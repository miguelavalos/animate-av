import Foundation

struct AnimateHomePresentation {
    let accountTitle: String
    let accountDetail: String
    let aviBriefDetail: String
    let momentStatusDetail: String
    let createAction: AnimateHomeAction
    let openInProgressAction: AnimateHomeAction
    let aviGuidanceAction: AnimateHomeAction
    let latestInProgressAction: AnimateHomeAction?
    let latestInProgressContinuationRequest: AnimateContinuationRequest?

    static func make(
        isSignedIn: Bool,
        displayName: String?,
        momentsSummary: AnimateInProgressSummary
    ) -> AnimateHomePresentation {
        let latestAnimateVideo = momentsSummary.latestAnimateVideo
        let latestInProgressAction = latestAnimateVideo.map {
            AnimateHomeAction(
                title: L10n.string("home.action.continueLatest.title"),
                detail: AnimateVideoFormatting.compactDetail(for: $0, includeTitle: true),
                systemImage: "arrow.right.circle",
                isProminent: true
            )
        }

        return AnimateHomePresentation(
            accountTitle: isSignedIn ? L10n.string("home.account.connected.title") : L10n.string("home.account.required.title"),
            accountDetail: accountDetail(isSignedIn: isSignedIn, displayName: displayName),
            aviBriefDetail: aviBriefDetail(isSignedIn: isSignedIn, momentsSummary: momentsSummary),
            momentStatusDetail: momentStatusDetail(momentsSummary: momentsSummary),
            createAction: AnimateHomeAction(
                title: L10n.string("home.action.create.title"),
                detail: L10n.string("home.action.create.detail"),
                systemImage: "plus.app",
                isProminent: latestAnimateVideo == nil,
                isDisabled: !isSignedIn
            ),
            openInProgressAction: AnimateHomeAction(
                title: L10n.string("home.action.openInProgress.title"),
                detail: momentsSummary.hasMoments
                    ? L10n.string("home.action.openInProgress.detail.hasMoments")
                    : L10n.string("home.action.openInProgress.detail.empty"),
                systemImage: "clock",
                isDisabled: !isSignedIn
            ),
            aviGuidanceAction: AnimateHomeAction(
                title: L10n.string("home.action.guidance.title"),
                detail: L10n.string("home.action.guidance.detail"),
                systemImage: "sparkles"
            ),
            latestInProgressAction: latestInProgressAction,
            latestInProgressContinuationRequest: momentsSummary.latestInProgressContinuationRequest
        )
    }

    private static func accountDetail(isSignedIn: Bool, displayName: String?) -> String {
        if isSignedIn {
            return L10n.string("home.account.signedInAs", displayName ?? L10n.string("home.account.defaultUser"))
        }

        return L10n.string("home.account.signInRequired")
    }

    private static func momentStatusDetail(momentsSummary: AnimateInProgressSummary) -> String {
        if momentsSummary.hasMoments {
            return L10n.string("home.momentStatus.synced", momentsSummary.momentCount, momentLabel(momentsSummary.momentCount))
        }

        return L10n.string("home.momentStatus.empty")
    }

    private static func aviBriefDetail(isSignedIn: Bool, momentsSummary: AnimateInProgressSummary) -> String {
        guard isSignedIn else {
            return L10n.string("home.aviBrief.signIn")
        }

        if let latestMoment = momentsSummary.latestAnimateVideo {
            return L10n.string("home.aviBrief.continueMoment", latestMoment.title)
        }

        if momentsSummary.hasMoments {
            return L10n.string("home.aviBrief.openInProgress")
        }

        return L10n.string("home.aviBrief.firstMemory")
    }

    private static func momentLabel(_ count: Int) -> String {
        count == 1 ? L10n.string("moment.noun.one") : L10n.string("moment.noun.other")
    }
}
