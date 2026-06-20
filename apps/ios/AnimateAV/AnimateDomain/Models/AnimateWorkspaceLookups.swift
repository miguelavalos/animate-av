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
            job.kind == "final" && job.isActiveRender
        }
    }

    var canEditSetupDuringRender: Bool {
        guard let activeFinalRenderJob else { return true }
        return activeFinalRenderJob.canEditSetup ?? false
    }
}

extension AnimateRenderJob {
    private static let staleSavingIntervalMs: Double = 4 * 60 * 1_000
    private static let staleActiveIntervalMs: Double = 20 * 60 * 1_000

    var isActiveRender: Bool {
        isActiveRender(now: Date())
    }

    var isTerminalFailure: Bool {
        ["failed", "blocked", "cancelled"].contains(status)
            || ["failed_recoverable", "failed_terminal", "cancelled"].contains(phase ?? "")
    }

    func isActiveRender(now: Date) -> Bool {
        Self.activeStatuses.contains(status) && !isStaleActiveRender(now: now)
    }

    func isStaleActiveRender(now: Date) -> Bool {
        guard Self.activeStatuses.contains(status) else { return false }
        let nowMs = now.timeIntervalSince1970 * 1_000
        let ageMs = nowMs - updatedAt
        guard ageMs > 0 else { return false }
        return ageMs > staleIntervalMs
    }

    func resolvedForUser(now: Date = Date()) -> AnimateRenderJob {
        guard isStaleActiveRender(now: now) else { return self }
        return AnimateRenderJob(
            id: id,
            kind: kind,
            status: "failed",
            phase: "failed_recoverable",
            progressPercent: progressPercent,
            userMessage: L10n.string("workflow.final.staleRender"),
            script: script,
            canEditSetup: true,
            canRetry: true,
            baseCreditCost: baseCreditCost,
            watermarkRemovalCreditCost: watermarkRemovalCreditCost,
            totalCreditCost: totalCreditCost,
            targetDurationMs: targetDurationMs,
            plannedAssetCount: plannedAssetCount,
            usedAssetCount: usedAssetCount,
            rejectedAssetCount: rejectedAssetCount,
            rendererMode: rendererMode,
            workflowRunId: workflowRunId,
            provider: provider,
            model: model,
            providerRequestId: providerRequestId,
            sourceImageArtifactId: sourceImageArtifactId,
            generatedImageArtifactId: generatedImageArtifactId,
            errorCode: errorCode ?? "stale_render_status",
            errorMessage: errorMessage,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    private var staleIntervalMs: Double {
        phase == "saving" ? Self.staleSavingIntervalMs : Self.staleActiveIntervalMs
    }

    private static let activeStatuses = ["queued", "running", "processing", "in_progress"]
}
