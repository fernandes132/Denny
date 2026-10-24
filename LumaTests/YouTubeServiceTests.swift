import XCTest
import Foundation
@testable import Luma

final class YouTubeServiceTests: XCTestCase {
    private func session(status: Int = 200, body: String, inspect: ((URLRequest) -> Void)? = nil) -> URLSession {
        StubURLProtocol.handler = { request in
            inspect?(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
            return (response, Data(body.utf8))
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }

    override func tearDown() { StubURLProtocol.handler = nil; super.tearDown() }

    func testSearchSanitizesAndDeduplicatesResponseWithoutLeakingKeyIntoURL() async throws {
        let body = #"{"items":[{"id":{"videoId":"aqz-KE-bpKQ"},"snippet":{"title":"Film &amp; muziek &#x1F3AC;","channelTitle":"Maker","description":"Over de film"}},{"id":{"videoId":"aqz-KE-bpKQ"},"snippet":{"title":"Duplicate","channelTitle":"Maker","description":""}},{"id":{"videoId":"bad"},"snippet":{"title":"Invalid","channelTitle":"Maker","description":""}}]}"#
        let session = session(body: body) { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-Goog-Api-Key"), "test-secret")
            XCTAssertFalse(request.url!.absoluteString.contains("test-secret"))
            XCTAssertFalse(request.url!.absoluteString.contains("key="))
        }
        defer { session.invalidateAndCancel() }
        let found = try await YouTubeService(session: session).search("film", key: "test-secret")
        XCTAssertEqual(found.count, 1)
        XCTAssertEqual(found.first?.title, "Film & muziek 🎬")
        XCTAssertNotNil(found.first?.metadataDate)
    }

    func testQuotaAndRestrictedKeysHaveDifferentErrors() async throws {
        for (reason, expected) in [("quotaExceeded", YouTubeService.APIError.quota), ("ipRefererBlocked", .restricted), ("accessNotConfigured", .disabled)] {
            let session = session(status: 403, body: "{\"error\":{\"errors\":[{\"reason\":\"\(reason)\"}]}}")
            defer { session.invalidateAndCancel() }
            do { _ = try await YouTubeService(session: session).search("film", key: "test"); XCTFail("Expected failure") }
            catch let error as YouTubeService.APIError { XCTAssertEqual(error, expected) }
        }
    }

    func testMalformedResponseIsActionable() async throws {
        let session = session(body: "<html>unavailable</html>")
        defer { session.invalidateAndCancel() }
        do { _ = try await YouTubeService(session: session).search("film", key: "test"); XCTFail("Expected failure") }
        catch let error as YouTubeService.APIError { XCTAssertEqual(error, .invalidResponse) }
    }

    func testEntityDecodingIsSinglePassAndSupportsUnicode() {
        XCTAssertEqual(YouTubeService.decodeEntities("&amp;lt; &#39; &#x1F680; &#128640; &unknown;"), "&lt; ' 🚀 🚀 &unknown;")
        XCTAssertEqual(YouTubeService.decodeEntities("&#xD800;"), "&#xD800;")
    }
}

private final class StubURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            guard let handler = Self.handler else { throw URLError(.badServerResponse) }
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() { }
}
