import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var library: LibraryStore
    @Binding var showAdd: Bool
    @State private var query = ""
    private var filtered: [Video] {
        library.saved.map { $0.removingExpiredMetadata() }.filter {
            query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) || $0.channel.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Goede video's.\nAltijd dichtbij.").font(.largeTitle.bold()).tracking(-0.8)
                Text("Je eigen selectie, bewaard op deze iPhone.").foregroundStyle(LumaTheme.muted)
                if library.saved.isEmpty {
                    EmptyMessage(symbol: "bookmark", title: "Maak het van jou", message: "Bewaar een video via Ontdekken of voeg je eigen YouTube-link toe.")
                    Button("Voeg je eerste video toe", systemImage: "plus") { showAdd = true }.buttonStyle(LumaButton())
                } else {
                    ForEach(filtered) { video in
                        HStack {
                            VideoRow(video: video)
                            Menu {
                                ShareLink(item: video.watchURL)
                                Button("Verwijder uit bibliotheek", systemImage: "bookmark.slash", role: .destructive) { library.remove(video) }
                            } label: {
                                Image(systemName: "ellipsis").frame(width: 44, height: 44)
                                    .foregroundStyle(LumaTheme.muted)
                            }.accessibilityLabel("Opties voor \(video.title)")
                        }
                    }
                    if filtered.isEmpty { EmptyMessage(symbol: "magnifyingglass", title: "Geen match", message: "Probeer een andere titel of maker.") }
                }
            }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }
        .navigationTitle("Bibliotheek").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Toevoegen", systemImage: "plus") { showAdd = true } } }
        .searchable(text: $query, prompt: "Zoek in je bibliotheek")
        .navigationDestination(for: Video.self) { VideoDetailView(video: $0) }
        .lumaScreen()
    }
}

struct AddVideoView: View {
    @EnvironmentObject private var library: LibraryStore
    @Environment(\.dismiss) private var dismiss
    @State private var link = ""
    @State private var title = ""
    @State private var error: String?
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image(systemName: "link").font(.system(size: 38, weight: .light)).foregroundStyle(LumaTheme.accent).padding(.top, 24)
                    Text("Een link.\nJouw volgende ontdekking.").font(.largeTitle.bold())
                    Text("Plak een YouTube-link, Shorts-link of video-ID. De video blijft bij YouTube; wij bewaren alleen je link.")
                        .foregroundStyle(LumaTheme.muted)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("YouTube-link").font(.headline)
                        TextField("https://youtu.be/…", text: $link)
                            .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                            .focused($focused).submitLabel(.done).onSubmit(add)
                            .padding(16).background(LumaTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                            .accessibilityIdentifier("add.link")
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Eigen titel (optioneel)").font(.headline)
                        TextField("Geef je link een naam", text: $title)
                            .padding(16).background(LumaTheme.surface, in: RoundedRectangle(cornerRadius: 14))
                            .accessibilityIdentifier("add.title")
                    }
                    if let error { Text(error).font(.callout).foregroundStyle(.orange).accessibilityAddTraits(.updatesFrequently) }
                    Button("Bewaar in bibliotheek", systemImage: "bookmark") { add() }
                        .buttonStyle(LumaButton()).disabled(link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("add.save")
                    Text("Je kunt alleen individuele video's toevoegen. Playlists en kanaallinks worden nog niet ondersteund.")
                        .font(.footnote).foregroundStyle(LumaTheme.muted)
                }.padding(24).frame(maxWidth: 600).frame(maxWidth: .infinity)
            }.navigationTitle("Video toevoegen").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Sluiten") { dismiss() } } }
                .onChange(of: link) { _, _ in error = nil }
                .onChange(of: title) { _, _ in error = nil }
                .lumaScreen()
        }.tint(LumaTheme.accent).preferredColorScheme(.dark)
    }

    private func add() {
        guard let id = YouTubeLink.parse(link) else {
            error = "Dit is geen geldige YouTube-videolink. Kopieer de link via Delen in YouTube."; return
        }
        var video = Catalog.videos.first { $0.id == id } ?? Video.link(id)
        let ownTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !ownTitle.isEmpty { video.title = String(ownTitle.prefix(160)); video.metadataDate = nil }
        if library.contains(video) { error = "Deze video staat al in je bibliotheek."; return }
        library.save(video)
        dismiss()
    }
}
