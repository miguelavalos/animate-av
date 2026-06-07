import Foundation

enum AnimateStatusRules {
    static func isFinished(_ video: AnimateVideo) -> Bool {
        isFinishedStatus(video.status)
    }

    static func isFinishedStatus(_ status: String) -> Bool {
        status == "gallery_ready" || status == "completed"
    }

    static func group(_ videos: [AnimateVideo]) -> AnimateVideoGroups {
        let sortedVideos = videos.sortedByLatestUpdate()

        return AnimateVideoGroups(
            inProgress: sortedVideos.filter { !isFinished($0) },
            finished: sortedVideos.filter(isFinished)
        )
    }

    static func displayTitle(for status: String) -> String {
        if status == "story_ready" {
            return L10n.string("moment.status.storyReady")
        }
        if status == "final_render_pending" || status == "final_rendering" {
            return L10n.string("moment.status.creatingVideo")
        }
        if status == "gallery_ready" {
            return L10n.string("moment.status.videoReady")
        }
        return status
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    static func displayKind(_ kind: String) -> String {
        return kind
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    static func nextAction(for workspace: AnimateWorkspace) -> AnimateNextAction {
        if let failedJob = workspace.renderJobs.latest(where: { isFailureStatus($0.status) }) {
            return AnimateNextAction(
                title: L10n.string("moment.nextAction.videoAttention.title"),
                message: L10n.string("moment.nextAction.videoAttention.message", displayKind(failedJob.kind)),
                systemImage: "exclamationmark.triangle",
                primaryButtonTitle: L10n.string("moment.nextAction.openInCreate"),
                continuationFocus: focus(forFailedJobKind: failedJob.kind)
            )
        }

        if workspace.mediaAssets.isEmpty {
            return AnimateNextAction(
                title: L10n.string("moment.nextAction.addMedia.title"),
                message: L10n.string("moment.nextAction.addMedia.message"),
                systemImage: "photo.badge.plus",
                primaryButtonTitle: L10n.string("moment.nextAction.addMedia.button"),
                continuationFocus: .media
            )
        }

        if workspace.storyScenes.isEmpty {
            return AnimateNextAction(
                title: L10n.string("moment.nextAction.prepareStory.title"),
                message: L10n.string("moment.nextAction.prepareStory.message"),
                systemImage: "text.bubble",
                primaryButtonTitle: L10n.string("moment.nextAction.prepareStory.button"),
                continuationFocus: .story
            )
        }

        if !workspace.artifacts.containsAvailable(kind: "final_export") {
            return AnimateNextAction(
                title: L10n.string("moment.nextAction.createVideo.title"),
                message: L10n.string("moment.nextAction.createVideo.message"),
                systemImage: "video.fill",
                primaryButtonTitle: L10n.string("moment.nextAction.createVideo.button"),
                continuationFocus: .finalRender
            )
        }

        return AnimateNextAction(
            title: L10n.string("library.finished.title"),
            message: L10n.string("moment.nextAction.finished.message"),
            systemImage: "checkmark.circle",
            primaryButtonTitle: L10n.string("moment.nextAction.openInCreate"),
            continuationFocus: .finalRender
        )
    }

    private static func focus(forFailedJobKind kind: String) -> AnimateContinuationFocus {
        switch kind {
        case "final":
            .finalRender
        default:
            .video
        }
    }

    private static func isFailureStatus(_ status: String) -> Bool {
        ["failed", "error", "blocked"].contains(status)
    }
}

private extension [AnimateVideo] {
    func sortedByLatestUpdate() -> [AnimateVideo] {
        sorted { $0.updatedAt > $1.updatedAt }
    }
}

private extension [AnimateRenderJob] {
    func latest(where predicate: (AnimateRenderJob) -> Bool) -> AnimateRenderJob? {
        filter(predicate)
            .sorted { $0.updatedAt < $1.updatedAt }
            .last
    }
}

private extension [AnimateArtifact] {
    func containsAvailable(kind: String) -> Bool {
        contains { $0.kind == kind && $0.status == "available" }
    }
}
