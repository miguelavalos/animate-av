import Foundation

struct AnimateAviPresentation: Equatable {
    let workflowFocusTitle: String
    let workflowFocusMessage: String
    let workflowFocusSystemImage: String
    let creditGuidanceMessage: String

    static func make(
        isSignedIn: Bool,
        momentsSummary: InProgressMomentsSummary,
        creditBalance: AnimateCreditBalance,
        creditBalanceLoadState: AnimateCreditBalanceLoadState = .loaded
    ) -> AnimateAviPresentation {
        AnimateAviPresentation(
            workflowFocusTitle: workflowFocusTitle(
                isSignedIn: isSignedIn,
                momentsSummary: momentsSummary
            ),
            workflowFocusMessage: workflowFocusMessage(
                isSignedIn: isSignedIn,
                momentsSummary: momentsSummary
            ),
            workflowFocusSystemImage: workflowFocusSystemImage(momentsSummary: momentsSummary),
            creditGuidanceMessage: creditGuidanceMessage(
                isSignedIn: isSignedIn,
                creditBalance: creditBalance,
                creditBalanceLoadState: creditBalanceLoadState
            )
        )
    }

    private static func workflowFocusTitle(
        isSignedIn: Bool,
        momentsSummary: InProgressMomentsSummary
    ) -> String {
        guard isSignedIn else { return L10n.string("avi.focus.signIn.title") }
        if momentsSummary.inProgressCount > 0 { return L10n.string("avi.focus.activeWork.title") }
        if momentsSummary.finishedCount > 0 { return L10n.string("avi.focus.nextMemory.title") }
        return L10n.string("avi.focus.firstMemory.title")
    }

    private static func workflowFocusMessage(
        isSignedIn: Bool,
        momentsSummary: InProgressMomentsSummary
    ) -> String {
        guard isSignedIn else {
            return L10n.string("avi.focus.signIn.message")
        }
        if momentsSummary.inProgressCount > 0 {
            return L10n.string("avi.focus.inProgress.message", momentsSummary.inProgressCount, inProgressMomentLabel(momentsSummary))
        }
        if momentsSummary.finishedCount > 0 {
            return L10n.string("avi.focus.finished.message")
        }
        return L10n.string("avi.focus.empty.message")
    }

    private static func workflowFocusSystemImage(momentsSummary: InProgressMomentsSummary) -> String {
        momentsSummary.inProgressCount > 0 ? "clock.badge.checkmark" : "sparkles"
    }

    private static func creditGuidanceMessage(
        isSignedIn: Bool,
        creditBalance: AnimateCreditBalance,
        creditBalanceLoadState: AnimateCreditBalanceLoadState
    ) -> String {
        guard isSignedIn else {
            return L10n.string("avi.credits.signIn.message")
        }
        guard creditBalanceLoadState.hasLoadedBalance else {
            return AnimateCreditCopy.balanceStatusDetail(creditBalanceLoadState)
        }
        guard creditBalance.spendable > 0 else {
            return L10n.string("avi.credits.none.message")
        }
        return L10n.string("avi.credits.available.message", AnimateCreditCopy.countTitle(creditBalance.spendable))
    }

    private static func inProgressMomentLabel(_ momentsSummary: InProgressMomentsSummary) -> String {
        momentsSummary.inProgressCount == 1 ? L10n.string("moment.noun.one") : L10n.string("moment.noun.other")
    }
}
