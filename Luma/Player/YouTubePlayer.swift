import SwiftUI
import WebKit

struct YouTubePlayer: UIViewRepresentable {
    let videoID: String
    var onReady: () -> Void
    var onError: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onReady: onReady, onError: onError) }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = .all
        configuration.userContentController.add(WeakMessageHandler(context.coordinator), name: "lumaPlayer")
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .black
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.accessibilityLabel = "Officiële YouTube-videospeler"
        context.coordinator.webView = webView
        context.coordinator.observeLifecycle()
        let origin = "https://" + (Bundle.main.bundleIdentifier ?? "nl.luma.pilot").lowercased()
        context.coordinator.originHost = URL(string: origin)?.host
        guard YouTubeLink.validID(videoID),
              let template = Bundle.main.url(forResource: "YouTubePlayer", withExtension: "html"),
              let html = try? String(contentsOf: template, encoding: .utf8) else {
            DispatchQueue.main.async { onError("De speler kon niet worden geladen. Open de video rechtstreeks in YouTube.") }
            return webView
        }
        let rendered = html.replacingOccurrences(of: "__VIDEO_ID__", with: videoID)
            .replacingOccurrences(of: "__ORIGIN__", with: origin)
        // Google's documented local HTML + baseURL approach supplies the installed app identity.
        webView.loadHTMLString(rendered, baseURL: URL(string: origin))
        context.coordinator.startTimeout()
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.onError = onError
        context.coordinator.onReady = onReady
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        coordinator.cleanUp()
        webView.evaluateJavaScript("if(window.player){window.player.destroy();}", completionHandler: nil)
        webView.stopLoading()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "lumaPlayer")
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        weak var webView: WKWebView?
        var originHost: String?
        var onError: (String) -> Void
        var onReady: () -> Void
        private var observer: NSObjectProtocol?
        private var visibilityObserver: NSObjectProtocol?
        private var timeout: DispatchWorkItem?
        private var isActive = true

        init(onReady: @escaping () -> Void, onError: @escaping (String) -> Void) {
            self.onReady = onReady
            self.onError = onError
        }

        func observeLifecycle() {
            observer = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
                self?.webView?.evaluateJavaScript("if(window.player && window.player.pauseVideo){window.player.pauseVideo();}", completionHandler: nil)
            }
            visibilityObserver = NotificationCenter.default.addObserver(forName: .lumaPauseYouTube, object: nil, queue: .main) { [weak self] _ in
                self?.webView?.evaluateJavaScript("if(window.player && window.player.pauseVideo){window.player.pauseVideo();}", completionHandler: nil)
            }
        }

        func startTimeout() {
            let item = DispatchWorkItem { [weak self] in
                guard let self, self.isActive else { return }
                self.onError("YouTube reageert niet. Controleer je verbinding of open de video in YouTube.")
            }
            timeout = item
            DispatchQueue.main.asyncAfter(deadline: .now() + 25, execute: item)
        }

        func cleanUp() {
            isActive = false
            timeout?.cancel(); timeout = nil
            if let observer { NotificationCenter.default.removeObserver(observer) }
            if let visibilityObserver { NotificationCenter.default.removeObserver(visibilityObserver) }
            visibilityObserver = nil
            observer = nil
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard isActive, message.frameInfo.isMainFrame, let data = message.body as? [String: Any], let event = data["event"] as? String else { return }
            if event == "ready" { timeout?.cancel(); onReady() }
            if event == "error" {
                timeout?.cancel()
                let code = (data["code"] as? Int) ?? 0
                switch code {
                case 100: onError("Deze video is verwijderd, privé of niet beschikbaar.")
                case 101, 150: onError("De maker staat afspelen in andere apps niet toe. Gebruik Open in YouTube.")
                case 153: onError("YouTube kon de app-identiteit niet controleren (153). Controleer de Bundle Identifier in Xcode of open de video in YouTube.")
                default: onError("YouTube kon deze video niet afspelen (\(code)). Probeer opnieuw of open YouTube.")
                }
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            guard (error as NSError).code != NSURLErrorCancelled else { return }
            timeout?.cancel()
            onError("De YouTube-speler kon niet verbinden. Controleer je internetverbinding.")
        }

        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            guard isActive else { return }
            timeout?.cancel()
            onError("iOS heeft de speler gesloten om geheugen vrij te maken. Tik op Probeer opnieuw om verder te kijken.")
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
            if navigationAction.targetFrame == nil {
                openExternal(url); decisionHandler(.cancel); return
            }
            if navigationAction.targetFrame?.isMainFrame == true && url.scheme != "about" && url.host != originHost {
                openExternal(url); decisionHandler(.cancel); return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url { openExternal(url) }
            return nil
        }

        private func openExternal(_ url: URL) {
            guard ["https", "http"].contains(url.scheme?.lowercased() ?? "") else { return }
            UIApplication.shared.open(url)
        }
    }
}

private final class WeakMessageHandler: NSObject, WKScriptMessageHandler {
    weak var target: WKScriptMessageHandler?
    init(_ target: WKScriptMessageHandler) { self.target = target }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        target?.userContentController(userContentController, didReceive: message)
    }
}
