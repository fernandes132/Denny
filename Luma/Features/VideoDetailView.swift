import SwiftUI

struct VideoDetailView: View {
    let video: Video
    @EnvironmentObject private var library: LibraryStore
    @AppStorage("luma.mediaConsent") private var consent = false
    @State private var playbackError: String?
    @State private var playerID = UUID()
    @State private var playerReady = false

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(video.removingExpiredMetadata().title).font(.largeTitle.bold()).tracking(-0.7)
                        .padding(.horizontal, 20)
                    if consent {
                        YouTubePlayer(videoID: video.id, onReady: { playerReady = true; playbackError = nil }, onError: { playbackError = $0 })
                            .id(playerID)
                            .frame(height: max(220, min(geometry.size.width, 680) * 9 / 16))
                            .frame(maxWidth: 680)
                            .background(.black)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "play.rectangle").font(.largeTitle).foregroundStyle(LumaTheme.accent)
                            Text("Klaar om te kijken?").font(.title3.bold())
                            Text("De speler maakt verbinding met YouTube. Google kan daarbij gegevens ontvangen.")
                                .foregroundStyle(LumaTheme.muted).multilineTextAlignment(.center)
                            Button("Sta YouTube toe en laad video") { consent = true }.buttonStyle(LumaButton())
                        }.padding(20).frame(minHeight: 220).background(LumaTheme.surface).padding(.horizontal, 20)
                    }
                    VStack(alignment: .leading, spacing: 22) {
                        if consent && !playerReady && playbackError == nil {
                            HStack(spacing: 10) { ProgressView(); Text("YouTube laden…").foregroundStyle(LumaTheme.muted) }
                                .font(.subheadline).accessibilityElement(children: .combine)
                        }
                        YouTubeAttribution(channel: video.channel)
                        if let playbackError {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Afspelen lukt niet", systemImage: "exclamationmark.triangle").font(.headline)
                                Text(playbackError).font(.callout).foregroundStyle(LumaTheme.muted)
                                Button("Probeer opnieuw") { self.playbackError = nil; playerReady = false; playerID = UUID() }
                                    .buttonStyle(LumaButton(primary: false))
                            }
                        }
                        Button {
                            library.toggle(video)
                        } label: {
                            Label(library.contains(video) ? "Bewaard in bibliotheek" : "Bewaren",
                                  systemImage: library.contains(video) ? "bookmark.fill" : "bookmark")
                        }.buttonStyle(LumaButton()).accessibilityIdentifier("video.save")
                        Link(destination: video.watchURL) { Label("Open in YouTube", systemImage: "arrow.up.right.square") }
                            .buttonStyle(LumaButton(primary: false))
                        ShareLink(item: video.watchURL) { Label("Deel video", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity, minHeight: 44) }
                        Divider().overlay(LumaTheme.muted.opacity(0.2))
                        Text("Over deze video").font(.title2.bold())
                        Text(video.removingExpiredMetadata().detail.isEmpty ? "Bekijk de volledige beschrijving en credits op YouTube." : video.removingExpiredMetadata().detail)
                            .foregroundStyle(LumaTheme.muted).textSelection(.enabled)
                        LabeledContent("Bron", value: "YouTube").font(.subheadline)
                        LabeledContent("Categorie", value: video.category).font(.subheadline)
                        Text("De officiële YouTube-speler verzorgt de bediening, advertenties en beschikbaarheid. Niet iedere video kan in een andere app worden afgespeeld.")
                            .font(.footnote).foregroundStyle(LumaTheme.muted)
                    }.padding(.horizontal, 20)
                }.padding(.top, 16).padding(.bottom, 32).frame(maxWidth: 680).frame(maxWidth: .infinity)
            }
        }
        .navigationBarHidden(false).navigationBarTitleDisplayMode(.inline)
        .onAppear { DemoPlayback.shared.pause() }
        .onChange(of: consent) { _, _ in playerReady = false; playbackError = nil }
        .onDisappear { NotificationCenter.default.post(name: .lumaPauseYouTube, object: nil) }
        .lumaScreen()
    }
}
