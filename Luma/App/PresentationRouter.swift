import SwiftUI

/// The app has one modal presenter, including collection and AirPlay screens.
@MainActor
final class PresentationRouter: ObservableObject {
    enum Sheet: Identifiable {
        case add
        case video(Video)
        case collection
        case airPlay
        var id: String {
            switch self {
            case .add: return "add"
            case .video(let video): return "video." + video.id
            case .collection: return "collection"
            case .airPlay: return "airplay"
            }
        }
    }

    @Published var sheet: Sheet?

    func presentPendingVideo(from library: LibraryStore, isActive: Bool) {
        guard isActive, sheet == nil, let video = library.pendingVideo else { return }
        library.pendingVideo = nil
        sheet = .video(video)
    }
}
