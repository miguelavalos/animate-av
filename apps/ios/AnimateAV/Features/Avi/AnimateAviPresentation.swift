import Foundation

struct AnimateAviPresentation: Equatable {
    let workflowFocusTitle: String
    let workflowFocusMessage: String
    let workflowFocusSystemImage: String
    let creditGuidanceMessage: String

    static func make(
        isSignedIn: Bool,
        videosSummary: AnimateInProgressSummary,
        creditBalance: AnimateCreditBalance,
        creditBalanceLoadState: AnimateCreditBalanceLoadState = .loaded
    ) -> AnimateAviPresentation {
        AnimateAviPresentation(
            workflowFocusTitle: workflowFocusTitle(
                isSignedIn: isSignedIn,
                videosSummary: videosSummary
            ),
            workflowFocusMessage: workflowFocusMessage(
                isSignedIn: isSignedIn,
                videosSummary: videosSummary
            ),
            workflowFocusSystemImage: workflowFocusSystemImage(videosSummary: videosSummary),
            creditGuidanceMessage: creditGuidanceMessage(
                isSignedIn: isSignedIn,
                creditBalance: creditBalance,
                creditBalanceLoadState: creditBalanceLoadState
            )
        )
    }

    private static func workflowFocusTitle(
        isSignedIn: Bool,
        videosSummary: AnimateInProgressSummary
    ) -> String {
        guard isSignedIn else { return L10n.string("avi.focus.signIn.title") }
        if videosSummary.inProgressCount > 0 { return L10n.string("avi.focus.activeWork.title") }
        if videosSummary.finishedCount > 0 { return L10n.string("avi.focus.nextMemory.title") }
        return L10n.string("avi.focus.firstMemory.title")
    }

    private static func workflowFocusMessage(
        isSignedIn: Bool,
        videosSummary: AnimateInProgressSummary
    ) -> String {
        guard isSignedIn else {
            return L10n.string("avi.focus.signIn.message")
        }
        if videosSummary.inProgressCount > 0 {
            return L10n.string("avi.focus.inProgress.message", videosSummary.inProgressCount, inProgressVideoLabel(videosSummary))
        }
        if videosSummary.finishedCount > 0 {
            return L10n.string("avi.focus.finished.message")
        }
        return L10n.string("avi.focus.empty.message")
    }

    private static func workflowFocusSystemImage(videosSummary: AnimateInProgressSummary) -> String {
        videosSummary.inProgressCount > 0 ? "clock.badge.checkmark" : "sparkles"
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

    private static func inProgressVideoLabel(_ videosSummary: AnimateInProgressSummary) -> String {
        videosSummary.inProgressCount == 1 ? L10n.string("video.noun.one") : L10n.string("video.noun.other")
    }
}
