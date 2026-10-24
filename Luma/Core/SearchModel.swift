import Foundation
import Combine

protocol YouTubeSearching {
    func search(_ query: String, key: String) async throws -> [Video]
}

/// One owner for request lifetime. A cancelled or superseded request can never replace a newer screen.
@MainActor
final class SearchModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading
        case loaded([Video])
        case failed(String)
    }

    @Published private(set) var state: State = .idle
    private var requestID = UUID()
    private var task: Task<Void, Never>?
    private let service: any YouTubeSearching

    init(service: any YouTubeSearching = YouTubeService()) { self.service = service }

    var isSearching: Bool { state == .loading }
    var didSearch: Bool { state != .idle }
    var results: [Video] { if case .loaded(let videos) = state { return videos }; return [] }
    var error: String? { if case .failed(let message) = state { return message }; return nil }

    func reset() {
        requestID = UUID()
        task?.cancel()
        task = nil
        state = .idle
    }

    func cancelIfLoading() { if isSearching { reset() } }

    func search(_ query: String, key: String, consent: Bool) {
        reset()
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }
        guard consent else { state = .failed("Schakel YouTube eerst in om online te zoeken."); return }
        guard !key.isEmpty else { state = .failed("Voeg een API-sleutel toe of zoek rechtstreeks op YouTube."); return }
        state = .loading
        let id = requestID
        let service = self.service
        task = Task { [weak self] in
            do {
                let videos = try await service.search(term, key: key)
                guard !Task.isCancelled, let self, self.requestID == id else { return }
                self.state = .loaded(videos)
                self.task = nil
            } catch {
                guard !Task.isCancelled, let self, self.requestID == id else { return }
                if error is CancellationError { self.state = .idle }
                else { self.state = .failed(error.localizedDescription) }
                self.task = nil
            }
        }
    }
}
