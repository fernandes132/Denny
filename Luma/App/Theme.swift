import SwiftUI

enum LumaTheme {
    static let background = Color(hex: 0x0B1017)
    static let surface = Color(hex: 0x141D28)
    static let text = Color(hex: 0xF4F3EE)
    static let muted = Color(hex: 0x96A4B5)
    static let accent = Color(hex: 0xD5FB77)
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255,
                  green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
    }
}

struct LumaButton: ButtonStyle {
    var primary = true
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline).multilineTextAlignment(.center)
            .padding(.horizontal, 16).padding(.vertical, 12)
            .frame(maxWidth: .infinity).frame(minHeight: 50)
            .foregroundStyle(primary ? LumaTheme.background : LumaTheme.text)
            .background(primary ? LumaTheme.accent : LumaTheme.surface, in: RoundedRectangle(cornerRadius: 16))
            .opacity(!enabled ? 0.4 : configuration.isPressed ? 0.75 : 1)
    }
}

struct ScreenBackground: ViewModifier {
    func body(content: Content) -> some View {
        content.background(LumaTheme.background.ignoresSafeArea())
            .foregroundStyle(LumaTheme.text)
            .toolbarBackground(LumaTheme.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

extension View {
    func lumaScreen() -> some View { modifier(ScreenBackground()) }
}

struct YouTubeAttribution: View {
    var channel: String = "YouTube"
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "play.rectangle.fill").foregroundStyle(.red)
            Text(channel == "YouTube" ? "YouTube" : "\(channel) · YouTube")
                .foregroundStyle(LumaTheme.muted)
        }.font(.caption).accessibilityElement(children: .combine)
    }
}

struct VideoArtwork: View {
    let video: Video
    @AppStorage("luma.mediaConsent") private var consent = false
    var body: some View {
        ZStack {
            LumaTheme.surface
            if consent {
                AsyncImage(url: video.thumbnailURL) { phase in
                    if let image = phase.image { image.resizable().scaledToFill() }
                    else { Image(systemName: "play.rectangle").font(.largeTitle).foregroundStyle(LumaTheme.muted) }
                }
            } else {
                Image(systemName: "play.rectangle").font(.largeTitle).foregroundStyle(LumaTheme.muted)
            }
        }
        .accessibilityHidden(true)
    }
}

struct VideoRow: View {
    let video: Video
    @EnvironmentObject private var library: LibraryStore
    @ScaledMetric private var thumbnailWidth = 128.0
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        NavigationLink(value: video) {
            Group {
                if typeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: 12) {
                        VideoArtwork(video: video).aspectRatio(16.0 / 9.0, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        textContent
                    }
                } else {
                    HStack(spacing: 14) {
                        VideoArtwork(video: video)
                            .frame(width: min(thumbnailWidth, 160), height: min(thumbnailWidth, 160) * 0.60)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        textContent
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(LumaTheme.muted).accessibilityHidden(true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 6).contentShape(Rectangle())
            .accessibilityElement(children: .combine)
        }.buttonStyle(.plain)
        .contextMenu {
            Button(library.contains(video) ? "Verwijder uit bibliotheek" : "Bewaar video", systemImage: "bookmark") { library.toggle(video) }
            ShareLink(item: video.watchURL)
        }
    }

    private var textContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(video.title).font(.headline).lineLimit(typeSize.isAccessibilitySize ? nil : 3).foregroundStyle(LumaTheme.text)
            YouTubeAttribution(channel: video.channel)
            if library.contains(video) {
                Label("Bewaard", systemImage: "bookmark.fill").font(.caption2).foregroundStyle(LumaTheme.accent)
            }
        }
    }
}

struct EmptyMessage: View {
    let symbol: String
    let title: String
    let message: String
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: symbol).font(.system(size: 36, weight: .light)).foregroundStyle(LumaTheme.accent)
            Text(title).font(.title3.bold())
            Text(message).foregroundStyle(LumaTheme.muted).multilineTextAlignment(.center)
        }.frame(maxWidth: .infinity).padding(.vertical, 36).padding(.horizontal, 20)
    }
}
