import Foundation

struct AnimateHomePresentation {
    let accountTitle: String
    let accountDetail: String
    let aviBriefDetail: String
    let videoStatusDetail: String
    let createAction: AnimateHomeAction
    let continueVideoAction: AnimateHomeAction
    let aviGuidanceAction: AnimateHomeAction
    let latestInProgressAction: AnimateHomeAction?
    let latestInProgressContinuationRequest: AnimateContinuationRequest?

    static func make(
        isSignedIn: Bool,
        displayName: String?,
        videosSummary: AnimateInProgressSummary
    ) -> AnimateHomePresentation {
        let latestAnimateVideo = videosSummary.latestAnimateVideo
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
            aviBriefDetail: aviBriefDetail(isSignedIn: isSignedIn, videosSummary: videosSummary),
            videoStatusDetail: videoStatusDetail(videosSummary: videosSummary),
            createAction: AnimateHomeAction(
                title: L10n.string("home.action.create.title"),
                detail: L10n.string("home.action.create.detail"),
                systemImage: "plus.app",
                isProminent: latestAnimateVideo == nil,
                isDisabled: !isSignedIn
            ),
            continueVideoAction: AnimateHomeAction(
                title: L10n.string("home.action.continueVideo.title"),
                detail: latestAnimateVideo == nil
                    ? L10n.string("home.action.continueVideo.detail.empty")
                    : L10n.string("home.action.continueVideo.detail.hasVideo"),
                systemImage: "arrow.right.circle",
                isDisabled: !isSignedIn
            ),
            aviGuidanceAction: AnimateHomeAction(
                title: L10n.string("home.action.guidance.title"),
                detail: L10n.string("home.action.guidance.detail"),
                systemImage: "sparkles"
            ),
            latestInProgressAction: latestInProgressAction,
            latestInProgressContinuationRequest: videosSummary.latestInProgressContinuationRequest
        )
    }

    private static func accountDetail(isSignedIn: Bool, displayName: String?) -> String {
        if isSignedIn {
            return L10n.string("home.account.signedInAs", displayName ?? L10n.string("home.account.defaultUser"))
        }

        return L10n.string("home.account.signInRequired")
    }

    private static func videoStatusDetail(videosSummary: AnimateInProgressSummary) -> String {
        if videosSummary.hasVideos {
            return L10n.string("home.videoStatus.synced", videosSummary.videoCount, videoLabel(videosSummary.videoCount))
        }

        return L10n.string("home.videoStatus.empty")
    }

    private static func aviBriefDetail(isSignedIn: Bool, videosSummary: AnimateInProgressSummary) -> String {
        guard isSignedIn else {
            return L10n.string("home.aviBrief.signIn")
        }

        if let latestVideo = videosSummary.latestAnimateVideo {
            return L10n.string("home.aviBrief.continueVideo", latestVideo.title)
        }

        if videosSummary.hasVideos {
            return L10n.string("home.aviBrief.gallery")
        }

        return L10n.string("home.aviBrief.firstMemory")
    }

    private static func videoLabel(_ count: Int) -> String {
        count == 1 ? L10n.string("video.noun.one") : L10n.string("video.noun.other")
    }
}
