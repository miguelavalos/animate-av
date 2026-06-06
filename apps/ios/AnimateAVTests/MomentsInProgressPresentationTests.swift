import XCTest
@testable import AnimateAV

final class MomentsInProgressPresentationTests: XCTestCase {
    func testSignedOutAvailabilityExplainsAccountRequirement() {
        let presentation = MomentsInProgressPresentation.make(
            isSignedIn: false,
            momentsSummary: InProgressMomentsSummary(),
            momentPendingDeletion: nil
        )

        XCTAssertEqual(
            presentation.availability,
            .signedOut(
                MomentsInProgressUnavailablePresentation(
                    systemImage: "person.crop.circle.fill",
                    title: "Sign in to make Moments",
                    message: "In Progress and Gallery unlock once your account is connected."
                )
            )
        )
    }

    func testEmptySignedInAvailabilityExplainsCreateFirstState() {
        let presentation = MomentsInProgressPresentation.make(
            isSignedIn: true,
            momentsSummary: InProgressMomentsSummary(),
            momentPendingDeletion: nil
        )

        XCTAssertEqual(
            presentation.availability,
            .empty(
                MomentsInProgressUnavailablePresentation(
                    systemImage: "rectangle.stack.badge.plus",
                    title: "Nothing here yet",
                    message: "Active Moments appear in In Progress. Finished videos appear in Gallery."
                )
            )
        )
    }

    func testMomentsAvailabilityIsAvailableWhenSignedInWithMoments() {
        let presentation = MomentsInProgressPresentation.make(
            isSignedIn: true,
            momentsSummary: InProgressMomentsSummary.make(from: [
                makeMoment(id: "moment-1")
            ]),
            momentPendingDeletion: nil
        )

        XCTAssertEqual(presentation.availability, .available)
    }

    func testDeletionMessageUsesPendingMomentTitleOrFallback() {
        let fallback = MomentsInProgressPresentation.make(
            isSignedIn: true,
            momentsSummary: InProgressMomentsSummary(),
            momentPendingDeletion: nil
        )
        let moment = makeMoment(id: "moment-1", title: "Family Weekend")
        let titled = MomentsInProgressPresentation.make(
            isSignedIn: true,
            momentsSummary: InProgressMomentsSummary(),
            momentPendingDeletion: moment
        )

        XCTAssertEqual(
            fallback.deletionMessage,
            "This removes this Moment, including selected media records and generated video files that belong to it."
        )
        XCTAssertEqual(
            titled.deletionMessage,
            "This removes Family Weekend, including selected media records and generated video files that belong to it."
        )
    }

    private func makeMoment(
        id: String,
        title: String? = nil,
        status: String = "in_progress",
        updatedAt: Double = 10
    ) -> InProgressMoment {
        InProgressMoment(
            id: id,
            template: .birthdayMessage,
            status: status,
            title: title ?? id,
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
