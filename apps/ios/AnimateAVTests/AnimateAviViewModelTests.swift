import Combine
import XCTest
@testable import AnimateAV

@MainActor
final class AnimateAviViewModelTests: XCTestCase {
    func testSignedOutGuidanceAsksForAuthentication() {
        let presentation = AnimateAviPresentation.make(
            isSignedIn: false,
            momentsSummary: AnimateInProgressSummary(),
            creditBalance: .empty
        )

        XCTAssertEqual(presentation.workflowFocusTitle, "Sign in first")
        XCTAssertTrue(presentation.workflowFocusMessage.contains("after sign in"))
        XCTAssertEqual(presentation.creditGuidanceMessage, "Credits appear here after sign in.")
    }

    func testActiveVideosDriveWorkflowFocus() {
        let presentation = AnimateAviPresentation.make(
            isSignedIn: true,
            momentsSummary: AnimateInProgressSummary.make(from: [
                makeMoment(id: "active-1", status: "story_ready", updatedAt: 20),
                makeMoment(id: "done-1", status: "gallery_ready", updatedAt: 10)
            ]),
            creditBalance: .empty
        )

        XCTAssertEqual(presentation.workflowFocusTitle, "Cartoons in motion")
        XCTAssertTrue(presentation.workflowFocusMessage.contains("1 video in In Progress"))
        XCTAssertEqual(presentation.workflowFocusSystemImage, "clock.badge.checkmark")
    }

    func testCreditGuidanceUsesSpendableBalance() {
        let presentation = AnimateAviPresentation.make(
            isSignedIn: true,
            momentsSummary: AnimateInProgressSummary(),
            creditBalance: AnimateCreditBalance(proMonthly: 2, promotional: 1, purchased: 3)
        )

        XCTAssertTrue(presentation.creditGuidanceMessage.contains("6 credits available"))
    }

    func testCreditGuidanceUsesSingularSpendableCredit() {
        let presentation = AnimateAviPresentation.make(
            isSignedIn: true,
            momentsSummary: AnimateInProgressSummary(),
            creditBalance: AnimateCreditBalance(proMonthly: 1, promotional: 0, purchased: 0)
        )

        XCTAssertTrue(presentation.creditGuidanceMessage.contains("1 credit available"))
    }

    func testZeroCreditsExplainFinalExportRequirement() {
        let presentation = AnimateAviPresentation.make(
            isSignedIn: true,
            momentsSummary: AnimateInProgressSummary(),
            creditBalance: .empty
        )

        XCTAssertEqual(
            presentation.creditGuidanceMessage,
            "No credits are available. Credits are needed before creating the final video."
        )
    }

    func testLoadingCreditsDoNotReadAsZeroCredits() {
        let presentation = AnimateAviPresentation.make(
            isSignedIn: true,
            momentsSummary: AnimateInProgressSummary(),
            creditBalance: .empty,
            creditBalanceLoadState: .loading
        )

        XCTAssertEqual(presentation.creditGuidanceMessage, "Loading your credit balance.")
    }

    func testOfflineCreditsExplainNetworkState() {
        let presentation = AnimateAviPresentation.make(
            isSignedIn: true,
            momentsSummary: AnimateInProgressSummary(),
            creditBalance: .empty,
            creditBalanceLoadState: .offline
        )

        XCTAssertEqual(
            presentation.creditGuidanceMessage,
            "Connect to the internet to see your balance or get credits."
        )
    }

    func testViewModelExposesPresentationFromBoundState() {
        let summaryProvider = AviMomentsSummaryProvider()
        let accountProvider = AviAccountStateProvider()
        let viewModel = AnimateAviViewModel()
        viewModel.bind(to: summaryProvider)
        viewModel.bind(accountStateProvider: accountProvider)

        accountProvider.isSignedIn.send(true)
        accountProvider.creditBalance.send(
            AnimateCreditBalance(proMonthly: 1, promotional: 0, purchased: 0)
        )
        summaryProvider.summary.send(
            AnimateInProgressSummary.make(from: [
                makeMoment(id: "active-1", status: "story_ready", updatedAt: 20)
            ])
        )

        XCTAssertEqual(viewModel.presentation.workflowFocusTitle, "Cartoons in motion")
        XCTAssertTrue(viewModel.presentation.creditGuidanceMessage.contains("1 credit available"))
    }

    private func makeMoment(id: String, status: String, updatedAt: Double) -> AnimateVideo {
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
            updatedAt: updatedAt
        )
    }
}

private final class AviMomentsSummaryProvider: AnimateInProgressSummaryProviding {
    let summary = CurrentValueSubject<AnimateInProgressSummary, Never>(AnimateInProgressSummary())

    var inProgressSummaryPublisher: AnyPublisher<AnimateInProgressSummary, Never> {
        summary.eraseToAnyPublisher()
    }
}

private final class AviAccountStateProvider: AnimateAccountStateProviding {
    let isSignedIn = CurrentValueSubject<Bool, Never>(false)
    let currentUserId = CurrentValueSubject<String?, Never>(nil)
    let displayName = CurrentValueSubject<String?, Never>(nil)
    let creditBalance = CurrentValueSubject<AnimateCreditBalance, Never>(.empty)
    let creditBalanceLoadState = CurrentValueSubject<AnimateCreditBalanceLoadState, Never>(.loaded)

    var isSignedInPublisher: AnyPublisher<Bool, Never> {
        isSignedIn.eraseToAnyPublisher()
    }

    var currentUserIdPublisher: AnyPublisher<String?, Never> {
        currentUserId.eraseToAnyPublisher()
    }

    var displayNamePublisher: AnyPublisher<String?, Never> {
        displayName.eraseToAnyPublisher()
    }

    var creditBalancePublisher: AnyPublisher<AnimateCreditBalance, Never> {
        creditBalance.eraseToAnyPublisher()
    }

    var creditBalanceLoadStatePublisher: AnyPublisher<AnimateCreditBalanceLoadState, Never> {
        creditBalanceLoadState.eraseToAnyPublisher()
    }
}
