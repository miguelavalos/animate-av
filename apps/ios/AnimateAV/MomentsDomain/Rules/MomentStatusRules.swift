import Foundation

enum MomentStatusRules {
    static func isFinished(_ moment: InProgressMoment) -> Bool {
        isFinishedStatus(moment.status)
    }

    static func isFinishedStatus(_ status: String) -> Bool {
        status == "gallery_ready" || status == "completed"
    }

    static func group(_ moments: [InProgressMoment]) -> InProgressMomentGroups {
        let sortedMoments = moments.sortedByLatestUpdate()

        return InProgressMomentGroups(
            inProgress: sortedMoments.filter { !isFinished($0) },
            finished: sortedMoments.filter(isFinished)
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

    static func nextAction(for workspace: MomentWorkspace) -> MomentNextAction {
        if let failedJob = workspace.renderJobs.latest(where: { isFailureStatus($0.status) }) {
            return MomentNextAction(
                title: L10n.string("moment.nextAction.videoAttention.title"),
                message: L10n.string("moment.nextAction.videoAttention.message", displayKind(failedJob.kind)),
                systemImage: "exclamationmark.triangle",
                primaryButtonTitle: L10n.string("moment.nextAction.openInCreate"),
                continuationFocus: focus(forFailedJobKind: failedJob.kind)
            )
        }

        if workspace.mediaAssets.isEmpty {
            return MomentNextAction(
                title: L10n.string("moment.nextAction.addMedia.title"),
                message: L10n.string("moment.nextAction.addMedia.message"),
                systemImage: "photo.badge.plus",
                primaryButtonTitle: L10n.string("moment.nextAction.addMedia.button"),
                continuationFocus: .media
            )
        }

        if workspace.storyScenes.isEmpty {
            return MomentNextAction(
                title: L10n.string("moment.nextAction.prepareStory.title"),
                message: L10n.string("moment.nextAction.prepareStory.message"),
                systemImage: "text.bubble",
                primaryButtonTitle: L10n.string("moment.nextAction.prepareStory.button"),
                continuationFocus: .story
            )
        }

        if !workspace.artifacts.containsAvailable(kind: "final_export") {
            return MomentNextAction(
                title: L10n.string("moment.nextAction.createVideo.title"),
                message: L10n.string("moment.nextAction.createVideo.message"),
                systemImage: "video.fill",
                primaryButtonTitle: L10n.string("moment.nextAction.createVideo.button"),
                continuationFocus: .finalRender
            )
        }

        return MomentNextAction(
            title: L10n.string("library.finished.title"),
            message: L10n.string("moment.nextAction.finished.message"),
            systemImage: "checkmark.circle",
            primaryButtonTitle: L10n.string("moment.nextAction.openInCreate"),
            continuationFocus: .finalRender
        )
    }

    private static func focus(forFailedJobKind kind: String) -> MomentsContinuationFocus {
        switch kind {
        case "final":
            .finalRender
        default:
            .moment
        }
    }

    private static func isFailureStatus(_ status: String) -> Bool {
        ["failed", "error", "blocked"].contains(status)
    }
}

private extension [InProgressMoment] {
    func sortedByLatestUpdate() -> [InProgressMoment] {
        sorted { $0.updatedAt > $1.updatedAt }
    }
}

private extension [MomentRenderJob] {
    func latest(where predicate: (MomentRenderJob) -> Bool) -> MomentRenderJob? {
        filter(predicate)
            .sorted { $0.updatedAt < $1.updatedAt }
            .last
    }
}

private extension [MomentArtifact] {
    func containsAvailable(kind: String) -> Bool {
        contains { $0.kind == kind && $0.status == "available" }
    }
}
