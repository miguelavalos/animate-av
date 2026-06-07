import XCTest
@testable import AnimateAV

final class AnimateInProgressPresentationTests: XCTestCase {
    func testSignedOutAvailabilityExplainsAccountRequirement() {
        let presentation = AnimateInProgressPresentation.make(
            isSignedIn: false,
            momentsSummary: AnimateInProgressSummary(),
            momentPendingDeletion: nil
        )

        XCTAssertEqual(
            presentation.availability,
            .signedOut(
                AnimateInProgressUnavailablePresentation(
                    systemImage: "person.crop.circle.fill",
                    title: "Sign in to make videos",
                    message: "In Progress and Gallery unlock once your account is connected."
                )
            )
        )
    }

    func testEmptySignedInAvailabilityExplainsCreateFirstState() {
        let presentation = AnimateInProgressPresentation.make(
            isSignedIn: true,
            momentsSummary: AnimateInProgressSummary(),
            momentPendingDeletion: nil
        )

        XCTAssertEqual(
            presentation.availability,
            .empty(
                AnimateInProgressUnavailablePresentation(
                    systemImage: "rectangle.stack.badge.plus",
                    title: "Nothing here yet",
                    message: "Active cartoons appear in In Progress. Finished ones appear in Gallery."
                )
            )
        )
    }

    func testVideoAvailabilityIsAvailableWhenSignedInWithVideos() {
        let presentation = AnimateInProgressPresentation.make(
            isSignedIn: true,
            momentsSummary: AnimateInProgressSummary.make(from: [
                makeMoment(id: "moment-1")
            ]),
            momentPendingDeletion: nil
        )

        XCTAssertEqual(presentation.availability, .available)
    }

    func testDeletionMessageUsesPendingVideoTitleOrFallback() {
        let fallback = AnimateInProgressPresentation.make(
            isSignedIn: true,
            momentsSummary: AnimateInProgressSummary(),
            momentPendingDeletion: nil
        )
        let moment = makeMoment(id: "moment-1", title: "Family Weekend")
        let titled = AnimateInProgressPresentation.make(
            isSignedIn: true,
            momentsSummary: AnimateInProgressSummary(),
            momentPendingDeletion: moment
        )

        XCTAssertEqual(
            fallback.deletionMessage,
            "This removes this video, including photo records and generated video files that belong to it."
        )
        XCTAssertEqual(
            titled.deletionMessage,
            "This removes Family Weekend, including photo records and generated video files that belong to it."
        )
    }

    private func makeMoment(
        id: String,
        title: String? = nil,
        status: String = "in_progress",
        updatedAt: Double = 10
    ) -> AnimateVideo {
        AnimateVideo(
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
