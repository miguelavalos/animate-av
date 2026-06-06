import Combine
import XCTest
@testable import AnimateAV

@MainActor
final class MomentsAviViewModelTests: XCTestCase {
    func testSignedOutGuidanceAsksForAuthentication() {
        let presentation = MomentsAviPresentation.make(
            isSignedIn: false,
            momentsSummary: InProgressMomentsSummary(),
            creditBalance: .empty
        )

        XCTAssertEqual(presentation.workflowFocusTitle, "Sign in first")
        XCTAssertTrue(presentation.workflowFocusMessage.contains("after sign in"))
        XCTAssertEqual(presentation.creditGuidanceMessage, "Credits appear here after sign in.")
    }

    func testActiveMomentsDriveWorkflowFocus() {
        let presentation = MomentsAviPresentation.make(
            isSignedIn: true,
            momentsSummary: InProgressMomentsSummary.make(from: [
                makeMoment(id: "active-1", status: "story_ready", updatedAt: 20),
                makeMoment(id: "done-1", status: "gallery_ready", updatedAt: 10)
            ]),
            creditBalance: .empty
        )

        XCTAssertEqual(presentation.workflowFocusTitle, "Active work")
        XCTAssertTrue(presentation.workflowFocusMessage.contains("1 Moment in In Progress"))
        XCTAssertEqual(presentation.workflowFocusSystemImage, "clock.badge.checkmark")
    }

    func testCreditGuidanceUsesSpendableBalance() {
        let presentation = MomentsAviPresentation.make(
            isSignedIn: true,
            momentsSummary: InProgressMomentsSummary(),
            creditBalance: MomentsCreditBalance(proMonthly: 2, promotional: 1, purchased: 3)
        )

        XCTAssertTrue(presentation.creditGuidanceMessage.contains("6 credits available"))
    }

    func testCreditGuidanceUsesSingularSpendableCredit() {
        let presentation = MomentsAviPresentation.make(
            isSignedIn: true,
            momentsSummary: InProgressMomentsSummary(),
            creditBalance: MomentsCreditBalance(proMonthly: 1, promotional: 0, purchased: 0)
        )

        XCTAssertTrue(presentation.creditGuidanceMessage.contains("1 credit available"))
    }

    func testZeroCreditsExplainFinalExportRequirement() {
        let presentation = MomentsAviPresentation.make(
            isSignedIn: true,
            momentsSummary: InProgressMomentsSummary(),
            creditBalance: .empty
        )

        XCTAssertEqual(
            presentation.creditGuidanceMessage,
            "No credits are available. Credits are needed before creating the final video."
        )
    }

    func testLoadingCreditsDoNotReadAsZeroCredits() {
        let presentation = MomentsAviPresentation.make(
            isSignedIn: true,
            momentsSummary: InProgressMomentsSummary(),
            creditBalance: .empty,
            creditBalanceLoadState: .loading
        )

        XCTAssertEqual(presentation.creditGuidanceMessage, "Loading your video credit balance.")
    }

    func testOfflineCreditsExplainNetworkState() {
        let presentation = MomentsAviPresentation.make(
            isSignedIn: true,
            momentsSummary: InProgressMomentsSummary(),
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
        let viewModel = MomentsAviViewModel()
        viewModel.bind(to: summaryProvider)
        viewModel.bind(accountStateProvider: accountProvider)

        accountProvider.isSignedIn.send(true)
        accountProvider.creditBalance.send(
            MomentsCreditBalance(proMonthly: 1, promotional: 0, purchased: 0)
        )
        summaryProvider.summary.send(
            InProgressMomentsSummary.make(from: [
                makeMoment(id: "active-1", status: "story_ready", updatedAt: 20)
            ])
        )

        XCTAssertEqual(viewModel.presentation.workflowFocusTitle, "Active work")
        XCTAssertTrue(viewModel.presentation.creditGuidanceMessage.contains("1 credit available"))
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

private final class AviMomentsSummaryProvider: InProgressMomentsSummaryProviding {
    let summary = CurrentValueSubject<InProgressMomentsSummary, Never>(InProgressMomentsSummary())

    var inProgressSummaryPublisher: AnyPublisher<InProgressMomentsSummary, Never> {
        summary.eraseToAnyPublisher()
    }
}

private final class AviAccountStateProvider: MomentsAccountStateProviding {
    let isSignedIn = CurrentValueSubject<Bool, Never>(false)
    let currentUserId = CurrentValueSubject<String?, Never>(nil)
    let displayName = CurrentValueSubject<String?, Never>(nil)
    let creditBalance = CurrentValueSubject<MomentsCreditBalance, Never>(.empty)
    let creditBalanceLoadState = CurrentValueSubject<MomentsCreditBalanceLoadState, Never>(.loaded)

    var isSignedInPublisher: AnyPublisher<Bool, Never> {
        isSignedIn.eraseToAnyPublisher()
    }

    var currentUserIdPublisher: AnyPublisher<String?, Never> {
        currentUserId.eraseToAnyPublisher()
    }

    var displayNamePublisher: AnyPublisher<String?, Never> {
        displayName.eraseToAnyPublisher()
    }

    var creditBalancePublisher: AnyPublisher<MomentsCreditBalance, Never> {
        creditBalance.eraseToAnyPublisher()
    }

    var creditBalanceLoadStatePublisher: AnyPublisher<MomentsCreditBalanceLoadState, Never> {
        creditBalanceLoadState.eraseToAnyPublisher()
    }
}
