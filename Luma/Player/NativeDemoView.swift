import SwiftUI
import AVKit
import MediaPlayer
import Combine

/// Separate native test path; successful AirPlay still requires a real device test.
@MainActor
final class DemoPlayback: ObservableObject {
    static let shared = DemoPlayback()
    let player = AVPlayer()
    @Published var error: String?
    @Published private(set) var isPlaying = false
    private var endObserver: NSObjectProtocol?
    private var statusObserver: NSKeyValueObservation?
    private var playbackObserver: NSKeyValueObservation?
    private var playTarget: Any?
    private var pauseTarget: Any?
    private var ownsAudioSession = false

    private init() {
        player.allowsExternalPlayback = true
        playbackObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            let playing = player.timeControlStatus == .playing
            Task { @MainActor in
                self?.isPlaying = playing
                if self?.ownsAudioSession == true {
                    MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = playing ? 1.0 : 0.0
                }
            }
        }
    }

    private func installRemoteCommands() {
        guard playTarget == nil else { return }
        playTarget = MPRemoteCommandCenter.shared().playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.play() }
            return .success
        }
        pauseTarget = MPRemoteCommandCenter.shared().pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }
    }

    private func prepareItem(forceReload: Bool) {
        guard forceReload || player.currentItem == nil || player.currentItem?.status == .failed else { return }
        statusObserver = nil
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8")!
        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)
        statusObserver = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            guard item.status == .failed else { return }
            Task { @MainActor in self?.error = "De Apple-teststream is niet beschikbaar. Controleer je verbinding en probeer opnieuw." }
        }
        endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: item, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.error = "De teststream kon niet afspelen. Controleer de verbinding." }
        }
    }

    func play() {
        let reload = error != nil
        error = nil
        do {
            NotificationCenter.default.post(name: .lumaPauseYouTube, object: nil)
            prepareItem(forceReload: reload)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
            ownsAudioSession = true
            installRemoteCommands()
            MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyTitle: "Luma — AirPlay-test", MPMediaItemPropertyArtist: "Apple HLS-teststream", MPNowPlayingInfoPropertyPlaybackRate: 0.0]
            player.play()
        } catch { self.error = "De audiosessie kon niet starten." }
    }

    func pause() {
        player.pause()
        if let playTarget { MPRemoteCommandCenter.shared().playCommand.removeTarget(playTarget) }
        if let pauseTarget { MPRemoteCommandCenter.shared().pauseCommand.removeTarget(pauseTarget) }
        playTarget = nil; pauseTarget = nil
        guard ownsAudioSession else { return }
        ownsAudioSession = false
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

struct NativeDemoView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var playback = DemoPlayback.shared
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Test je verbinding.").font(.largeTitle.bold())
                    NativePlayerController(player: playback.player).frame(height: 260)
                    Button(playback.isPlaying ? "Pauzeer testvideo" : "Start testvideo", systemImage: playback.isPlaying ? "pause.fill" : "play.fill") {
                        if playback.isPlaying { playback.pause() } else { playback.play() }
                    }.buttonStyle(LumaButton())
                    AirPlayRoutePicker().frame(height: 48).accessibilityLabel("Selecteer AirPlay-scherm")
                    if let error = playback.error { Text(error).foregroundStyle(.orange) }
                    Text("Selecteer een beschikbaar AirPlay-scherm met de AirPlay-knop. Op een geschikte CarPlay-auto kan video alleen beschikbaar zijn wanneer de auto geparkeerd staat. Deze Apple-teststream test de native verbinding; hij bewijst geen YouTube-ondersteuning.")
                        .foregroundStyle(LumaTheme.muted)
                }.padding(20)
            }.navigationTitle("AirPlay-test").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Sluiten") { playback.pause(); dismiss() } } }
                .lumaScreen()
        }.preferredColorScheme(.dark).tint(LumaTheme.accent)
            .onDisappear { playback.pause() }
    }
}

struct NativePlayerController: UIViewControllerRepresentable {
    let player: AVPlayer
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.allowsPictureInPicturePlayback = false
        return controller
    }
    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) { }
}

struct AirPlayRoutePicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.prioritizesVideoDevices = true
        view.tintColor = UIColor(LumaTheme.accent)
        return view
    }
    func updateUIView(_ view: AVRoutePickerView, context: Context) { }
}
