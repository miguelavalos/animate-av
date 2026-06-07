import XCTest
@testable import AnimateAV

final class AnimateNewVideoStartControllerTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var userDefaultsSuiteName: String!

    override func setUp() {
        super.setUp()
        userDefaultsSuiteName = "AnimateNewVideoStartControllerTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: userDefaultsSuiteName)
        userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
        userDefaults = nil
        userDefaultsSuiteName = nil
        super.tearDown()
    }

    func testDefaultsToPhotosOrClipsForSpeed() {
        let controller = AnimateNewVideoStartController(userDefaults: userDefaults)

        XCTAssertEqual(controller.currentPreference, .photosOrClips)
    }

    func testInvalidStoredPreferenceFallsBackToPhotosOrClips() {
        userDefaults.set("unexpected", forKey: "animateav.newVideoStartPreference")

        let controller = AnimateNewVideoStartController(userDefaults: userDefaults)

        XCTAssertEqual(controller.currentPreference, .photosOrClips)
    }

    func testInvalidAlbumPreferenceFallsBackToPhotosOrClips() {
        userDefaults.set("album", forKey: "animateav.newVideoStartPreference")

        let controller = AnimateNewVideoStartController(userDefaults: userDefaults)

        XCTAssertEqual(controller.currentPreference, .photosOrClips)
    }
}
