#if LUMA_CARPLAY
import CarPlay
import AVFoundation
import UIKit

/// Compiled only by Luma-CarPlay (iOS 27 SDK + Apple-approved entitlement).
/// YouTube's WKWebView playback is not represented as a native video stream.
@MainActor
final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate, CPSessionConfigurationDelegate {
    private var interface: CPInterfaceController?
    private var configuration: CPSessionConfiguration?
    private var list: CPListTemplate?
    private var libraryObserver: NSObjectProtocol?

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        interface = interfaceController
        configuration = CPSessionConfiguration(delegate: self)
        let template = CPListTemplate(title: "Luma", sections: sections())
        list = template
        interfaceController.setRootTemplate(template, animated: false, completion: nil)
        libraryObserver = NotificationCenter.default.addObserver(forName: .lumaLibraryChanged, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        DemoPlayback.shared.pause()
        if let libraryObserver { NotificationCenter.default.removeObserver(libraryObserver) }
        libraryObserver = nil; list = nil; interface = nil; configuration = nil
    }

    func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration, limitedUserInterfacesChanged limitedUserInterfaces: CPLimitableUserInterface) {
        // This is a UI restriction, not a trustworthy parking/motion signal.
        // Native CarPlay/AirPlay enforces video presentation; never infer a bypass here.
        refresh()
    }

    private func refresh() { list?.updateSections(sections()) }

    private func sections() -> [CPListSection] {
        guard configuration?.supportsVideoPlayback == true else {
            let unavailable = CPListItem(text: "Video niet ondersteund", detailText: "Deze auto biedt geen CarPlay Video.")
            unavailable.isEnabled = false
            return [CPListSection(items: [unavailable])]
        }

        let demo = CPListItem(text: "AirPlay-verbinding testen", detailText: "Apple-testvideo · geen YouTube")
        demo.playbackConfiguration = CPPlaybackConfiguration(preferredPresentation: .video, playbackAction: .play, elapsedTime: .zero, duration: .zero)
        demo.handler = { _, completion in
            DemoPlayback.shared.play()
            completion()
        }
        var sections = [CPListSection(items: [demo], header: "Native videotest", sectionIndexTitle: nil)]
        let videos = LibraryStore.shared.saved.isEmpty ? Catalog.videos : LibraryStore.shared.saved
        let items = videos.prefix(20).map { original -> CPListItem in
            let video = original.removingExpiredMetadata()
            let item = CPListItem(text: video.title, detailText: "YouTube · selecteer op iPhone")
            item.handler = { [weak self] _, completion in
                LibraryStore.shared.pendingVideo = video
                self?.showYouTubeStatus()
                completion()
            }
            return item
        }
        sections.append(CPListSection(items: items, header: "Je YouTube-links", sectionIndexTitle: nil))
        return sections
    }

    private func showYouTubeStatus() {
        let close = CPAlertAction(title: "Begrepen", style: .default) { [weak self] _ in
            self?.interface?.dismissTemplate(animated: true, completion: nil)
        }
        let alert = CPAlertTemplate(titleVariants: ["Geselecteerd op iPhone. YouTube-video via CarPlay is nog niet gevalideerd. Gebruik je iPhone alleen wanneer je geparkeerd staat."], actions: [close])
        interface?.presentTemplate(alert, animated: true, completion: nil)
    }
}
#endif
