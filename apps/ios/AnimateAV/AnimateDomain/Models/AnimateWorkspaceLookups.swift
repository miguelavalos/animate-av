import Foundation

extension AnimateWorkspace {
    func latestArtifact(kind: String) -> AnimateArtifact? {
        artifacts.last { $0.kind == kind }
    }

    func hasAvailableArtifact(kind: String) -> Bool {
        artifacts.contains { $0.kind == kind && $0.status == "available" }
    }

    var latestFinalVideoArtifact: AnimateArtifact? {
        latestArtifact(kind: "final_video") ?? latestArtifact(kind: "final_export")
    }

    var latestGeneratedImageArtifact: AnimateArtifact? {
        latestArtifact(kind: "generated_image")
    }

    func latestRenderJob(kind: String? = nil) -> AnimateRenderJob? {
        renderJobs
            .filter { job in
                guard let kind else { return true }
                return job.kind == kind
            }
            .max { $0.updatedAt < $1.updatedAt }
    }

    var activeFinalRenderJob: AnimateRenderJob? {
        renderJobs.first { job in
            job.kind == "final" && ["queued", "running"].contains(job.status)
        }
    }

    var canEditSetupDuringRender: Bool {
        guard let activeFinalRenderJob else { return true }
        return activeFinalRenderJob.canEditSetup ?? false
    }
}

extension AnimateRenderJob {
    var isActiveRender: Bool {
        ["queued", "running", "processing", "in_progress"].contains(status)
    }

    var isTerminalFailure: Bool {
        ["failed", "blocked", "cancelled"].contains(status)
            || ["failed_recoverable", "failed_terminal", "cancelled"].contains(phase ?? "")
    }
}
