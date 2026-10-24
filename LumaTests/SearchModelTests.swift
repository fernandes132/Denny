import XCTest
import Combine
@testable import Luma

final class SearchModelTests: XCTestCase {
    @MainActor func testNoConsentMeansNoNetworkRequest() async {
        let service = ControlledSearch()
        let model = SearchModel(service: service)
        model.search("film", key: "test", consent: false)
        let count = await service.requestCount
        XCTAssertEqual(count, 0)
        XCTAssertNotNil(model.error)
        XCTAssertFalse(model.isSearching)
    }

    @MainActor func testLateCancelledResultCannotReplaceNewerResult() async {
        let service = ControlledSearch()
        let model = SearchModel(service: service)
        model.search("old", key: "test", consent: true)
        await service.waitForRequest("old")
        model.search("new", key: "test", consent: true)
        await service.waitForRequest("new")
        let fresh = Video.link("aqz-KE-bpKQ")
        let stale = Video.link("M7lc1UVf-VE")
        let newLoaded = expectation(description: "Newest result visible")
        let noStaleResult = expectation(description: "Stale result must not be published")
        noStaleResult.isInverted = true
        let observation = model.$state.sink { state in
            if case .loaded(let videos) = state {
                if videos == [fresh] { newLoaded.fulfill() }
                if videos == [stale] { noStaleResult.fulfill() }
            }
        }
        await service.finish("new", videos: [fresh])
        await fulfillment(of: [newLoaded], timeout: 1)
        // The mock intentionally ignores task cancellation and returns old data anyway.
        await service.finish("old", videos: [stale])
        await fulfillment(of: [noStaleResult], timeout: 0.15)
        XCTAssertEqual(model.results, [fresh])
        withExtendedLifetime(observation) { }
    }

    @MainActor func testLeavingDuringLoadingRestoresIdleState() async {
        let service = ControlledSearch()
        let model = SearchModel(service: service)
        model.search("film", key: "test", consent: true)
        await service.waitForRequest("film")
        model.cancelIfLoading()
        XCTAssertEqual(model.state, .idle)
        await service.finish("film", videos: [])
    }
}

private actor ControlledSearch: YouTubeSearching {
    private var pending: [String: CheckedContinuation<[Video], Error>] = [:]
    private var waiters: [String: CheckedContinuation<Void, Never>] = [:]
    private(set) var requestCount = 0

    func search(_ query: String, key: String) async throws -> [Video] {
        requestCount += 1
        return try await withCheckedThrowingContinuation { continuation in
            pending[query] = continuation
            waiters.removeValue(forKey: query)?.resume()
        }
    }

    func waitForRequest(_ query: String) async {
        if pending[query] != nil { return }
        await withCheckedContinuation { waiters[query] = $0 }
    }

    func finish(_ query: String, videos: [Video]) {
        pending.removeValue(forKey: query)?.resume(returning: videos)
    }
}
