import Foundation

struct AnimateInProgressProgressModel {
    let phases: [AnimateInProgressProgressPhase]

    init(workspace: AnimateWorkspace) {
        phases = [
            AnimateInProgressProgressPhase(
                title: L10n.string("video.progress.video"),
                detail: AnimateStatusRules.displayTitle(for: workspace.video.status),
                systemImage: "doc.text",
                state: .complete
            ),
            AnimateInProgressProgressPhase(
                title: L10n.string("video.progress.media"),
                detail: workspace.mediaAssets.isEmpty ? L10n.string("video.progress.noMedia") : L10n.string("video.progress.assets", workspace.mediaAssets.count),
                systemImage: "photo.on.rectangle",
                state: workspace.mediaAssets.isEmpty ? .waiting : .complete
            ),
            AnimateInProgressProgressPhase(
                title: L10n.string("video.progress.story"),
                detail: workspace.videoDirectionScenes.isEmpty ? L10n.string("video.progress.notReady") : L10n.string("video.progress.scenes", workspace.videoDirectionScenes.count),
                systemImage: "text.bubble",
                state: workspace.videoDirectionScenes.isEmpty ? .waiting : .complete
            ),
            AnimateInProgressProgressPhase(
                title: L10n.string("video.progress.createVideo"),
                detail: Self.renderDetail(workspace: workspace, kind: "final", fallback: L10n.string("video.progress.notCreated")),
                systemImage: "video.fill",
                state: Self.renderState(workspace: workspace, kind: "final", artifactKind: "final_export")
            )
        ]
    }

    private static func renderDetail(workspace: AnimateWorkspace, kind: String, fallback: String) -> String {
        if let artifact = workspace.latestArtifact(kind: artifactKind(for: kind)) {
            return AnimateStatusRules.displayTitle(for: artifact.status)
        }

        guard let job = workspace.latestRenderJob(kind: kind) else {
            return fallback
        }

        return AnimateStatusRules.displayTitle(for: job.status)
    }

    private static func renderState(
        workspace: AnimateWorkspace,
        kind: String,
        artifactKind: String
    ) -> AnimateInProgressProgressState {
        if workspace.hasAvailableArtifact(kind: artifactKind) {
            return .complete
        }

        guard let job = workspace.latestRenderJob(kind: kind) else {
            return .waiting
        }

        return AnimateInProgressProgressState(status: job.status)
    }

    private static func artifactKind(for renderKind: String) -> String {
        renderKind == "final" ? "final_export" : renderKind
    }
}

struct AnimateInProgressProgressPhase: Identifiable, Equatable {
    let title: String
    let detail: String
    let systemImage: String
    let state: AnimateInProgressProgressState

    var id: String {
        title
    }
}

enum AnimateInProgressProgressState: Equatable {
    case complete
    case active
    case waiting
    case failed

    init(status: String) {
        switch status {
        case "completed", "available", "succeeded":
            self = .complete
        case "failed", "error", "blocked":
            self = .failed
        case "queued", "running", "processing", "pending":
            self = .active
        default:
            self = .active
        }
    }

    var systemImage: String {
        switch self {
        case .complete: "checkmark.circle.fill"
        case .active: "clock.fill"
        case .waiting: "circle"
        case .failed: "exclamationmark.circle.fill"
        }
    }

}
