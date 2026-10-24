import SwiftUI

@main
struct LumaApp: App {
    @StateObject private var library = LibraryStore.shared
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(library)
                .preferredColorScheme(.dark)
                .tint(LumaTheme.accent)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var library: LibraryStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0
    @StateObject private var presentation = PresentationRouter()

    private var showAdd: Binding<Bool> {
        Binding(get: { if case .add? = presentation.sheet { return true }; return false }, set: { value in
            if value { presentation.sheet = .add }
            else if case .add? = presentation.sheet { presentation.sheet = nil }
        })
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack { DiscoverView(showAdd: showAdd) }
                .tabItem { Label("Ontdekken", systemImage: "safari") }.tag(0)
            NavigationStack { LibraryView(showAdd: showAdd) }
                .tabItem { Label("Bibliotheek", systemImage: "books.vertical") }.tag(1)
            NavigationStack { SettingsView() }
                .tabItem { Label("Instellingen", systemImage: "gearshape") }.tag(2)
        }
        .toolbarBackground(LumaTheme.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .sheet(item: $presentation.sheet, onDismiss: presentPendingVideo) { sheet in
            Group {
                switch sheet {
                case .add: AddVideoView()
                case .collection: CollectionView()
                case .airPlay: NativeDemoView()
                case .video(let video):
                    NavigationStack { VideoDetailView(video: video)
                        .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Sluiten") { presentation.sheet = nil } } }
                    }
                }
            }.environmentObject(presentation).environmentObject(library)
        }
        .onChange(of: library.pendingVideo, initial: true) { _, _ in presentPendingVideo() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { library.purgeExpiredMetadata(); presentPendingVideo() }
        }
        .alert("Bibliotheek", isPresented: Binding(get: { library.storageError != nil }, set: { if !$0 { library.storageError = nil } })) {
            Button("Begrepen") { library.storageError = nil }
        } message: { Text(library.storageError ?? "") }
        .environmentObject(presentation)
    }

    private func presentPendingVideo() {
        presentation.presentPendingVideo(from: library, isActive: scenePhase == .active)
    }
}
