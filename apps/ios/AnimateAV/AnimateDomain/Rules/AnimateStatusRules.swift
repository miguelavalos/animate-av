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
        if status == "video_direction_ready" {
            return L10n.string("video.status.videoDirectionReady")
        }
        if status == "final_render_pending" || status == "final_rendering" {
            return L10n.string("video.status.creatingVideo")
        }
        if status == "gallery_ready" {
            return L10n.string("video.status.videoReady")
        }
        if status == "completed" {
            return L10n.string("video.status.completed")
        }
        if status == "in_progress" {
            return L10n.string("inProgress.summary.active")
        }
        if status == "queued" || status == "pending" {
            return L10n.string("create.render.status.queued")
        }
        if status == "running" || status == "processing" {
            return L10n.string("create.render.status.working")
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
        if let failedJob = workspace.renderJobs.map({ $0.resolvedForUser() }).latest(where: { isFailureStatus($0.status) }) {
            return AnimateNextAction(
                title: L10n.string("video.nextAction.videoAttention.title"),
                message: L10n.string("video.nextAction.videoAttention.message", displayKind(failedJob.kind)),
                systemImage: "exclamationmark.triangle",
                primaryButtonTitle: L10n.string("video.nextAction.openInCreate"),
                continuationFocus: focus(forFailedJobKind: failedJob.kind)
            )
        }

        if workspace.mediaAssets.isEmpty {
            return AnimateNextAction(
                title: L10n.string("video.nextAction.addMedia.title"),
                message: L10n.string("video.nextAction.addMedia.message"),
                systemImage: "photo.badge.plus",
                primaryButtonTitle: L10n.string("video.nextAction.addMedia.button"),
                continuationFocus: .media
            )
        }

        if workspace.videoDirectionScenes.isEmpty {
            return AnimateNextAction(
                title: L10n.string("video.nextAction.prepareStory.title"),
                message: L10n.string("video.nextAction.prepareStory.message"),
                systemImage: "text.bubble",
                primaryButtonTitle: L10n.string("video.nextAction.prepareStory.button"),
                continuationFocus: .story
            )
        }

        if workspace.latestFinalVideoArtifact == nil {
            return AnimateNextAction(
                title: L10n.string("video.nextAction.createVideo.title"),
                message: L10n.string("video.nextAction.createVideo.message"),
                systemImage: "video.fill",
                primaryButtonTitle: L10n.string("video.nextAction.createVideo.button"),
                continuationFocus: .finalRender
            )
        }

        return AnimateNextAction(
            title: L10n.string("library.finished.title"),
            message: L10n.string("video.nextAction.finished.message"),
            systemImage: "checkmark.circle",
            primaryButtonTitle: L10n.string("video.nextAction.openInCreate"),
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
