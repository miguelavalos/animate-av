import XCTest
@testable import AnimateAV

final class MomentsHomePresentationTests: XCTestCase {
    func testSignedOutStateRequiresAccountAndDisablesMomentActions() {
        let presentation = MomentsHomePresentation.make(
            isSignedIn: false,
            displayName: nil,
            momentsSummary: InProgressMomentsSummary()
        )

        XCTAssertEqual(presentation.accountTitle, "Account required")
        XCTAssertEqual(
            presentation.accountDetail,
            "Sign in is required before creating and saving videos."
        )
        XCTAssertTrue(presentation.createAction.isDisabled)
        XCTAssertTrue(presentation.openInProgressAction.isDisabled)
        XCTAssertNil(presentation.latestInProgressAction)
        XCTAssertNil(presentation.latestInProgressContinuationRequest)
    }

    func testEmptySignedInStatePromotesCreateAction() {
        let presentation = MomentsHomePresentation.make(
            isSignedIn: true,
            displayName: "Ava",
            momentsSummary: InProgressMomentsSummary()
        )

        XCTAssertEqual(presentation.accountTitle, "Account connected")
        XCTAssertEqual(presentation.accountDetail, "Signed in as Ava.")
        XCTAssertEqual(presentation.momentStatusDetail, "No synced videos yet.")
        XCTAssertTrue(presentation.createAction.isProminent)
        XCTAssertFalse(presentation.createAction.isDisabled)
        XCTAssertEqual(
            presentation.openInProgressAction.detail,
            "Videos appear after you start one."
        )
    }

    func testLatestInProgressMomentAddsContinuationAction() {
        let moment = makeMoment(id: "latest-plan", status: "story_ready", updatedAt: 20)
        let presentation = MomentsHomePresentation.make(
            isSignedIn: true,
            displayName: nil,
            momentsSummary: InProgressMomentsSummary.make(from: [
                makeMoment(id: "finished", status: "gallery_ready", updatedAt: 30),
                moment
            ])
        )

        XCTAssertEqual(presentation.latestInProgressAction?.title, "Continue latest video")
        XCTAssertEqual(presentation.latestInProgressAction?.systemImage, "arrow.right.circle")
        XCTAssertTrue(presentation.latestInProgressAction?.isProminent == true)
        XCTAssertFalse(presentation.createAction.isProminent)
        XCTAssertEqual(presentation.latestInProgressContinuationRequest?.moment.id, "latest-plan")
        XCTAssertEqual(presentation.latestInProgressContinuationRequest?.focus, .moment)
    }

    func testMomentCountDrivesStatusAndReviewDetail() {
        let presentation = MomentsHomePresentation.make(
            isSignedIn: true,
            displayName: nil,
            momentsSummary: InProgressMomentsSummary.make(from: [
                makeMoment(id: "one", status: "in_progress", updatedAt: 10),
                makeMoment(id: "two", status: "gallery_ready", updatedAt: 20)
            ])
        )

        XCTAssertEqual(
            presentation.momentStatusDetail,
            "2 synced videos tracked across the current account."
        )
        XCTAssertEqual(
            presentation.openInProgressAction.detail,
            "Continue videos that still need action."
        )
    }

    func testSingleMomentUsesSingularMomentCopy() {
        let presentation = MomentsHomePresentation.make(
            isSignedIn: true,
            displayName: nil,
            momentsSummary: InProgressMomentsSummary.make(from: [
                makeMoment(id: "one", status: "in_progress", updatedAt: 10)
            ])
        )

        XCTAssertEqual(
            presentation.momentStatusDetail,
            "1 synced video tracked across the current account."
        )
        XCTAssertEqual(
            presentation.openInProgressAction.detail,
            "Continue videos that still need action."
        )
    }

    private func makeMoment(id: String, status: String, updatedAt: Double) -> InProgressMoment {
        InProgressMoment(
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
            updatedAt: updatedAt
        )
    }
}
