import XCTest
@testable import Luma

final class LumaTests: XCTestCase {
    func testAcceptedYouTubeLinks() {
        let id = "aqz-KE-bpKQ"
        for link in [id, "HTTPS://WWW.YOUTUBE.COM/watch?v=\(id)", "https://youtu.be/\(id)?si=abc", "https://www.youtube.com/watch?v=\(id)&t=20", "m.youtube.com/watch?v=\(id)", "https://www.youtube.com/shorts/\(id)", "https://www.youtube.com/live/\(id)", "https://www.youtube-nocookie.com/embed/\(id)"] {
            XCTAssertEqual(YouTubeLink.parse(link), id, link)
        }
    }

    func testRawIDsRejectControlCharactersAndNonASCII() {
        XCTAssertFalse(YouTubeLink.validID("aqz-KE-bpKQ\n"))
        XCTAssertFalse(YouTubeLink.validID("aqz-KE-bpKé"))
        XCTAssertFalse(YouTubeLink.validID("aqz-KE-bpKQ "))
    }

    func testRejectsUntrustedOrMalformedLinks() {
        for link in ["", "bad", "https://youtube.com.evil.example/watch?v=aqz-KE-bpKQ", "https://evil.example/aqz-KE-bpKQ", "javascript:alert(1)", "https://youtube.com/playlist?list=abc", "https://youtu.be/short", "https://evil@youtube.com/watch?v=aqz-KE-bpKQ", "https://youtu.be/aqz-KE-bpKQ/extra", "https://youtube.com:444/watch?v=aqz-KE-bpKQ"] {
            XCTAssertNil(YouTubeLink.parse(link), link)
        }
    }

    @MainActor func testLibraryDeduplicatesPersistsAndRemoves() throws {
        let suite = "LumaTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = LibraryStore(defaults: defaults)
        let video = Video.link("aqz-KE-bpKQ")
        store.save(video); store.save(video)
        XCTAssertEqual(store.saved.count, 1)
        XCTAssertEqual(LibraryStore(defaults: defaults).saved.first?.id, video.id)
        store.toggle(video)
        XCTAssertTrue(store.saved.isEmpty)
        XCTAssertTrue(LibraryStore(defaults: defaults).saved.isEmpty)
    }

    func testExpiredAPIMetadataIsDiscardedButLinkRemains() {
        var video = Video.link("aqz-KE-bpKQ")
        video.title = "Old API title"
        video.metadataDate = Date(timeIntervalSince1970: 0)
        let fresh = video.removingExpiredMetadata()
        XCTAssertEqual(fresh.id, video.id)
        XCTAssertEqual(fresh.title, "YouTube-video")
        XCTAssertNil(fresh.metadataDate)
    }

    func testMetadataWithoutAPITimestampSurvives() {
        var video = Video.link("aqz-KE-bpKQ")
        video.title = "Mijn eigen naam"
        XCTAssertEqual(video.removingExpiredMetadata().title, "Mijn eigen naam")
    }

    @MainActor func testCarPlaySelectionWaitsForExistingSheetAndForeground() throws {
        let suite = "LumaPresentationTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = LibraryStore(defaults: defaults)
        let router = PresentationRouter()
        let video = Video.link("aqz-KE-bpKQ")
        store.pendingVideo = video
        router.sheet = .airPlay
        router.presentPendingVideo(from: store, isActive: true)
        XCTAssertEqual(router.sheet?.id, "airplay")
        XCTAssertEqual(store.pendingVideo, video)
        router.sheet = nil
        router.presentPendingVideo(from: store, isActive: false)
        XCTAssertNil(router.sheet)
        XCTAssertEqual(store.pendingVideo, video)
        router.presentPendingVideo(from: store, isActive: true)
        XCTAssertEqual(router.sheet?.id, "video." + video.id)
        XCTAssertNil(store.pendingVideo)
    }

    @MainActor func testInvalidVideoIsNeverPersisted() throws {
        let suite = "LumaInvalidVideoTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = LibraryStore(defaults: defaults)
        store.save(Video.link("invalid"))
        XCTAssertTrue(store.saved.isEmpty)
        XCTAssertNotNil(store.storageError)
    }
}
