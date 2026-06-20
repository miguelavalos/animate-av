import XCTest
@testable import AnimateAV

final class AnimateHomePresentationTests: XCTestCase {
    func testSignedOutStateRequiresAccountAndDisablesVideoActions() {
        let presentation = AnimateHomePresentation.make(
            isSignedIn: false,
            displayName: nil,
            videosSummary: AnimateInProgressSummary()
        )

        XCTAssertEqual(presentation.accountTitle, "Account required")
        XCTAssertEqual(
            presentation.accountDetail,
            "Sign in is required before creating and saving videos."
        )
        XCTAssertTrue(presentation.createAction.isDisabled)
        XCTAssertTrue(presentation.continueVideoAction.isDisabled)
        XCTAssertNil(presentation.latestInProgressAction)
        XCTAssertNil(presentation.latestInProgressContinuationRequest)
    }

    func testEmptySignedInStatePromotesCreateAction() {
        let presentation = AnimateHomePresentation.make(
            isSignedIn: true,
            displayName: "Ava",
            videosSummary: AnimateInProgressSummary()
        )

        XCTAssertEqual(presentation.accountTitle, "Account connected")
        XCTAssertEqual(presentation.accountDetail, "Signed in as Ava.")
        XCTAssertEqual(presentation.videoStatusDetail, "No videos yet.")
        XCTAssertEqual(presentation.createAction.title, "Create Video")
        XCTAssertTrue(presentation.createAction.isProminent)
        XCTAssertFalse(presentation.createAction.isDisabled)
        XCTAssertEqual(
            presentation.continueVideoAction.detail,
            "Open Create Video to start with one photo."
        )
    }

    func testLatestInProgressVideoAddsContinuationAction() {
        let video = makeVideo(id: "latest-plan", status: "video_direction_ready", updatedAt: 20)
        let presentation = AnimateHomePresentation.make(
            isSignedIn: true,
            displayName: nil,
            videosSummary: AnimateInProgressSummary.make(from: [
                makeVideo(id: "finished", status: "gallery_ready", updatedAt: 30),
                video
            ])
        )

        XCTAssertEqual(presentation.latestInProgressAction?.title, "Continue in Create Video")
        XCTAssertEqual(presentation.latestInProgressAction?.systemImage, "arrow.right.circle")
        XCTAssertTrue(presentation.latestInProgressAction?.isProminent == true)
        XCTAssertFalse(presentation.createAction.isProminent)
        XCTAssertEqual(presentation.latestInProgressContinuationRequest?.video.id, "latest-plan")
        XCTAssertEqual(presentation.latestInProgressContinuationRequest?.focus, .video)
    }

    func testVideoCountDrivesStatusAndReviewDetail() {
        let presentation = AnimateHomePresentation.make(
            isSignedIn: true,
            displayName: nil,
            videosSummary: AnimateInProgressSummary.make(from: [
                makeVideo(id: "one", status: "in_progress", updatedAt: 10),
                makeVideo(id: "two", status: "gallery_ready", updatedAt: 20)
            ])
        )

        XCTAssertEqual(
            presentation.videoStatusDetail,
            "2 videos in Animate AV."
        )
        XCTAssertEqual(
            presentation.continueVideoAction.detail,
            "Open Create Video to finish the next step."
        )
    }

    func testSingleVideoUsesSingularVideoCopy() {
        let presentation = AnimateHomePresentation.make(
            isSignedIn: true,
            displayName: nil,
            videosSummary: AnimateInProgressSummary.make(from: [
                makeVideo(id: "one", status: "in_progress", updatedAt: 10)
            ])
        )

        XCTAssertEqual(
            presentation.videoStatusDetail,
            "1 video in Animate AV."
        )
        XCTAssertEqual(
            presentation.continueVideoAction.detail,
            "Open Create Video to finish the next step."
        )
    }

    func testVideoSummaryExcludesImageAssetsFromHomePresentation() {
        let mixedSummary = AnimateInProgressSummary.make(from: [
            makeVideo(id: "video", status: "gallery_ready", updatedAt: 10),
            makeVideo(id: "image", status: "in_progress", updatedAt: 20, assetKind: "image")
        ])
        let presentation = AnimateHomePresentation.make(
            isSignedIn: true,
            displayName: nil,
            videosSummary: mixedSummary.videoSummary
        )

        XCTAssertEqual(presentation.videoStatusDetail, "1 video in Animate AV.")
        XCTAssertNil(presentation.latestInProgressAction)
        XCTAssertEqual(
            presentation.continueVideoAction.detail,
            "Open Create Video to start with one photo."
        )
    }

    private func makeVideo(
        id: String,
        status: String,
        updatedAt: Double,
        assetKind: String = "video"
    ) -> AnimateVideo {
        AnimateVideo(
            id: id,
            template: .birthdayMessage,
            status: status,
            title: id,
            tone: nil,
            tempo: nil,
            occasion: nil,
            details: nil,
            durationSeconds: 30,
            creditCost: 2,
            updatedAt: updatedAt,
            assetKind: assetKind
        )
    }
}
