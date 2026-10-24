import Foundation
import Combine

@MainActor
final class LibraryStore: ObservableObject {
    static let shared = LibraryStore()
    @Published private(set) var saved: [Video] = []
    @Published var pendingVideo: Video?
    @Published var storageError: String?
    private let defaults: UserDefaults
    private let key = "luma.saved.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: key) {
            do {
                let decoded = try JSONDecoder().decode([Video].self, from: data)
                var seen = Set<String>()
                saved = decoded.filter { YouTubeLink.validID($0.id) && seen.insert($0.id).inserted }.map { $0.removingExpiredMetadata() }
                if saved != decoded { persist() }
            }
            catch { storageError = "Je bibliotheek kon niet worden gelezen. Je bestaande gegevens zijn niet overschreven." }
        }
    }

    func contains(_ video: Video) -> Bool { saved.contains { $0.id == video.id } }

    func save(_ video: Video) {
        guard YouTubeLink.validID(video.id) else {
            storageError = "Deze video heeft geen geldig YouTube-ID en is niet bewaard."
            return
        }
        guard !contains(video) else { return }
        saved.insert(video, at: 0)
        persist()
    }

    func remove(_ video: Video) {
        saved.removeAll { $0.id == video.id }
        persist()
    }

    func toggle(_ video: Video) {
        if contains(video) { remove(video) } else { save(video) }
    }

    func clear() { saved = []; persist() }

    func purgeExpiredMetadata() {
        let cleaned = saved.map { $0.removingExpiredMetadata() }
        guard cleaned != saved else { return }
        saved = cleaned
        persist()
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(saved)
            defaults.set(data, forKey: key)
            storageError = nil
            NotificationCenter.default.post(name: .lumaLibraryChanged, object: nil)
        } catch { storageError = "Bewaren is niet gelukt. Probeer het opnieuw." }
    }
}

extension Notification.Name {
    static let lumaLibraryChanged = Notification.Name("luma.library.changed")
    static let lumaPauseYouTube = Notification.Name("luma.youtube.pause")
}
