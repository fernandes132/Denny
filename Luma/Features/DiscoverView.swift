import SwiftUI

struct DiscoverView: View {
    @Binding var showAdd: Bool
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var presentation: PresentationRouter
    @AppStorage("luma.mediaConsent") private var consent = false
    @State private var query = ""
    @State private var category = "Alles"
    @StateObject private var search = SearchModel()
    @State private var hasAPIKey = false
    @State private var selectedVideo: Video?
    @FocusState private var searchFocused: Bool
    private let categories = ["Alles", "Film", "Ruimte", "Tech"]

    private var videos: [Video] {
        let base = search.didSearch ? search.results : Catalog.videos
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return base.filter { (search.didSearch || !term.isEmpty || category == "Alles" || $0.category == category) &&
            (search.didSearch || term.isEmpty || $0.title.localizedCaseInsensitiveContains(term) || $0.channel.localizedCaseInsensitiveContains(term)) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Jouw moment.").font(.largeTitle.bold()).tracking(-1)
                    Text("Ontdek iets dat blijft hangen.").font(.body).foregroundStyle(LumaTheme.muted)
                }
                searchField
                if YouTubeLink.parse(query) != nil {
                    Button("Open deze YouTube-video", systemImage: "play.rectangle") { performSearch() }
                        .buttonStyle(LumaButton())
                }
                if !search.didSearch && query.isEmpty { filters }
                if !search.didSearch && query.isEmpty && category == "Alles" { hero }
                if !consent { privacyNotice }
                resultsHeader
                if search.isSearching {
                    ProgressView("Zoeken op YouTube…").frame(maxWidth: .infinity).padding(32).tint(LumaTheme.accent)
                } else if let error = search.error {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(error).foregroundStyle(LumaTheme.muted)
                        Button("Probeer opnieuw") { performSearch() }.buttonStyle(LumaButton(primary: false))
                        externalSearch
                    }
                } else {
                    LazyVStack(spacing: 14) { ForEach(videos) { VideoRow(video: $0) } }
                    if videos.isEmpty { EmptyMessage(symbol: "magnifyingglass", title: "Nog niets gevonden", message: "Probeer een andere zoekterm of plak een YouTube-link.") }
                }
                if !query.isEmpty && !search.didSearch && YouTubeLink.parse(query) == nil {
                    VStack(alignment: .leading, spacing: 12) {
                        if !hasAPIKey {
                            Text("Je doorzoekt nu de startselectie. Zoek verder op YouTube, of voeg je eigen API-sleutel toe in Instellingen voor resultaten in de app.")
                                .font(.footnote).foregroundStyle(LumaTheme.muted)
                            externalSearch
                        } else {
                            Button("Zoek op YouTube") { performSearch() }.buttonStyle(LumaButton())
                        }
                    }
                }
                if query.isEmpty && !search.didSearch { serviceLink }
            }
            .padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 28)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationBarHidden(true)
        .navigationDestination(for: Video.self) { VideoDetailView(video: $0) }
        .navigationDestination(item: $selectedVideo) { VideoDetailView(video: $0) }
        .onChange(of: query) { _, _ in search.reset() }
        .onAppear { hasAPIKey = !APIKeyStore.read().isEmpty }
        .onChange(of: consent) { _, allowed in
            if !allowed { search.reset() }
        }
        .onDisappear { search.cancelIfLoading() }
        .lumaScreen()
    }

    private var header: some View {
        HStack {
            HStack(spacing: 7) {
                Text("LUMA").font(.title2.weight(.heavy)).tracking(1)
                Image(systemName: "play.fill").foregroundStyle(LumaTheme.accent).font(.headline)
            }.accessibilityElement(children: .combine).accessibilityLabel("Luma")
            Spacer()
            Button { showAdd = true } label: {
                Image(systemName: "plus").font(.title3).frame(width: 46, height: 46)
                    .background(LumaTheme.surface, in: Circle())
            }.foregroundStyle(LumaTheme.text).accessibilityLabel("YouTube-link toevoegen")
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(LumaTheme.muted)
            TextField("Zoek of plak een YouTube-link", text: $query)
                .font(.subheadline).textInputAutocapitalization(.never).autocorrectionDisabled()
                .submitLabel(.search).focused($searchFocused).onSubmit(performSearch)
                .accessibilityIdentifier("discover.search")
            if !query.isEmpty {
                Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }
                    .foregroundStyle(LumaTheme.muted).accessibilityLabel("Zoekveld wissen").frame(minWidth: 44, minHeight: 44)
            }
        }.padding(.leading, 16).padding(.trailing, query.isEmpty ? 16 : 4).frame(minHeight: 54)
            .background(LumaTheme.surface, in: RoundedRectangle(cornerRadius: 18))
            .overlay { RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.07), lineWidth: 1) }
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(categories, id: \.self) { item in
                    Button { category = item } label: {
                        Text(item).font(.subheadline.weight(.semibold)).padding(.horizontal, 20).frame(minHeight: 44)
                            .background(category == item ? LumaTheme.accent : LumaTheme.surface, in: Capsule())
                            .foregroundStyle(category == item ? LumaTheme.background : LumaTheme.text)
                    }.accessibilityAddTraits(category == item ? .isSelected : [])
                }
            }
        }
    }

    private var privacyNotice: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Jij kiest wanneer YouTube laadt.").font(.headline)
            Text("Na je toestemming laden we afbeeldingen en video's van YouTube. Google kan daarbij gegevens ontvangen. Je bibliotheek blijft op je iPhone.")
                .font(.footnote).foregroundStyle(LumaTheme.muted)
            Button("YouTube inschakelen") { consent = true }.buttonStyle(LumaButton())
        }.padding(18).background(LumaTheme.surface, in: RoundedRectangle(cornerRadius: 20))
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image("Hero").resizable().scaledToFill().frame(height: 180).clipped().accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 12) {
                Text("Even helemaal weg").font(.title2.bold())
                Text("Een selectie om bij stil te staan.").foregroundStyle(LumaTheme.muted).font(.subheadline)
                Button { presentation.sheet = .collection } label: { HStack { Text("Bekijk selectie"); Spacer(); Image(systemName: "arrow.up.right") } }
                    .buttonStyle(LumaButton())
            }.padding(18)
        }.background(LumaTheme.surface).clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var resultsHeader: some View {
        HStack {
            Text(search.didSearch ? "Resultaten van YouTube" : query.isEmpty ? "Voor jou" : "In de startselectie")
                .font(.title2.bold())
            Spacer()
            if search.didSearch { Button("Wissen") { query = ""; search.reset() }.frame(minHeight: 44) }
        }
    }

    private var externalSearch: some View {
        Button(action: openYouTubeSearch) {
            Label("Zoek verder op YouTube", systemImage: "arrow.up.right")
        }.buttonStyle(LumaButton(primary: false))
    }

    private func openYouTubeSearch() {
        var url = URLComponents(string: "https://www.youtube.com/results")!
        url.queryItems = [URLQueryItem(name: "search_query", value: query.trimmingCharacters(in: .whitespacesAndNewlines))]
        if let destination = url.url { openURL(destination) }
    }

    private var serviceLink: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Ook binnen handbereik").font(.title3.bold())
            Link(destination: URL(string: "https://www.ziggogo.tv")!) {
                HStack {
                    Image(systemName: "tv").font(.title2).foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ziggo GO").font(.headline)
                        Text("Open de officiële dienst").font(.caption).foregroundStyle(LumaTheme.muted)
                    }
                    Spacer(); Image(systemName: "arrow.up.right")
                }.padding(18).background(LumaTheme.surface, in: RoundedRectangle(cornerRadius: 18))
            }.foregroundStyle(LumaTheme.text)
        }.padding(.top, 8)
    }

    private func performSearch() {
        searchFocused = false
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }
        search.reset()
        if let id = YouTubeLink.parse(term) {
            selectedVideo = Catalog.videos.first { $0.id == id } ?? .link(id)
            return
        }
        let key = APIKeyStore.read()
        hasAPIKey = !key.isEmpty
        guard hasAPIKey else { openYouTubeSearch(); return }
        category = "Alles"
        search.search(term, key: key, consent: consent)
    }

}

struct CollectionView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Image("Hero").resizable().scaledToFill().frame(height: 200).clipped().clipShape(RoundedRectangle(cornerRadius: 20))
                    Text("Even helemaal weg").font(.largeTitle.bold())
                    Text("Een kleine selectie open animatiefilms en een blik op de ruimte. Beschikbaarheid wordt door YouTube bepaald.").foregroundStyle(LumaTheme.muted)
                    ForEach(Catalog.videos.filter { $0.category != "Tech" }) { VideoRow(video: $0) }
                }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
            }.navigationTitle("De selectie").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Sluiten") { dismiss() } } }
                .navigationDestination(for: Video.self) { VideoDetailView(video: $0) }.lumaScreen()
        }.tint(LumaTheme.accent).preferredColorScheme(.dark)
    }
}
