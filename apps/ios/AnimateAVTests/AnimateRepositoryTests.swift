import XCTest
@testable import AnimateAV

@MainActor
final class AnimateRepositoryTests: XCTestCase {
    func testRepositoryIsNotConfiguredWithoutDeploymentURL() {
        let repository = AnimateRepository(deploymentURL: "  ")

        XCTAssertFalse(repository.isConfigured)
    }

    func testRepositoryIsConfiguredWithDeploymentURL() {
        let repository = AnimateRepository(deploymentURL: "https://animate-av.convex.cloud")

        XCTAssertTrue(repository.isConfigured)
    }

    func testObserveInProgressThrowsNotConfiguredWhenConvexIsNotConfigured() {
        let repository = AnimateRepository(deploymentURL: "")

        do {
            _ = try repository.observeAnimateVideos(ownerUserId: "user-1")
            XCTFail("Expected not configured error")
        } catch {
            XCTAssertEqual(error as? AnimateSyncError, .notConfigured)
        }
    }

    func testObserveGalleryThrowsNotConfiguredWhenConvexIsNotConfigured() {
        let repository = AnimateRepository(deploymentURL: "")

        do {
            _ = try repository.observeGalleryArtifacts(ownerUserId: "user-1")
            XCTFail("Expected not configured error")
        } catch {
            XCTAssertEqual(error as? AnimateSyncError, .notConfigured)
        }
    }
}
