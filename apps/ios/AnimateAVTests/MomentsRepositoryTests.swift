import XCTest
@testable import AnimateAV

@MainActor
final class MomentsRepositoryTests: XCTestCase {
    func testRepositoryIsNotConfiguredWithoutDeploymentURL() {
        let repository = MomentsRepository(deploymentURL: "  ")

        XCTAssertFalse(repository.isConfigured)
    }

    func testRepositoryIsConfiguredWithDeploymentURL() {
        let repository = MomentsRepository(deploymentURL: "https://animate-av.convex.cloud")

        XCTAssertTrue(repository.isConfigured)
    }

    func testObserveInProgressThrowsNotConfiguredWhenConvexIsNotConfigured() {
        let repository = MomentsRepository(deploymentURL: "")

        do {
            _ = try repository.observeInProgressMoments(ownerUserId: "user-1")
            XCTFail("Expected not configured error")
        } catch {
            XCTAssertEqual(error as? MomentsSyncError, .notConfigured)
        }
    }

    func testObserveGalleryThrowsNotConfiguredWhenConvexIsNotConfigured() {
        let repository = MomentsRepository(deploymentURL: "")

        do {
            _ = try repository.observeGalleryMoments(ownerUserId: "user-1")
            XCTFail("Expected not configured error")
        } catch {
            XCTAssertEqual(error as? MomentsSyncError, .notConfigured)
        }
    }
}
