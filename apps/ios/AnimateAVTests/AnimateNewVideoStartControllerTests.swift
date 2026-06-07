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
        let controller = MomentsNewMomentStartController(userDefaults: userDefaults)

        XCTAssertEqual(controller.currentPreference, .photosOrClips)
    }

    func testInvalidStoredPreferenceFallsBackToPhotosOrClips() {
        userDefaults.set("unexpected", forKey: "animateav.newMomentStartPreference")

        let controller = MomentsNewMomentStartController(userDefaults: userDefaults)

        XCTAssertEqual(controller.currentPreference, .photosOrClips)
    }

    func testInheritedAlbumPreferenceFallsBackToPhotosOrClips() {
        userDefaults.set("album", forKey: "animateav.newMomentStartPreference")

        let controller = MomentsNewMomentStartController(userDefaults: userDefaults)

        XCTAssertEqual(controller.currentPreference, .photosOrClips)
    }
}
