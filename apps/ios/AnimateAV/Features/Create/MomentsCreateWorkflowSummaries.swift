import Foundation

struct MomentsCreateWorkspaceSummary: Equatable {
    var mediaCount = 0
    var sceneCount = 0
    var renderJobCount = 0
    var hasFinalExport = false

    var mediaDetail: String {
        L10n.string("create.summary.media.added", mediaCount)
    }

    var storyDetail: String {
        L10n.string(sceneCount == 1 ? "create.summary.story.scene" : "create.summary.story.scenes", sceneCount)
    }

    static func make(
        workspace: MomentWorkspace?,
        finalExport: MomentArtifact?
    ) -> MomentsCreateWorkspaceSummary {
        MomentsCreateWorkspaceSummary(
            mediaCount: workspace?.mediaAssets.count ?? 0,
            sceneCount: workspace?.storyScenes.count ?? 0,
            renderJobCount: workspace?.renderJobs.count ?? 0,
            hasFinalExport: finalExport != nil
        )
    }

}

struct MomentsCreateMediaSummary: Equatable {
    var selectedMedia: [MomentsSelectedMedia] = []
    var syncedMediaAssets: [MomentMediaAsset] = []
    var isImporting = false
    var importProgress: MomentsMediaImportProgress?
    var statusMessage: String?

    var selectedCount: Int {
        selectedMedia.filter(\.selected).count
    }

    var effectiveMediaCount: Int {
        if selectedCount > 0 {
            return selectedCount
        }

        let selectedBackendCount = temporaryBackendMediaCount
        return selectedBackendCount > 0 ? selectedBackendCount : syncedMediaAssets.count
    }

    var hasTemporaryBackendMedia: Bool {
        selectedMedia.isEmpty && savedBackendMediaCount > 0
    }

    var temporaryBackendMediaCount: Int {
        syncedMediaAssets.filter(\.selected).count
    }

    var savedBackendMediaCount: Int {
        let selectedBackendCount = temporaryBackendMediaCount
        return selectedBackendCount > 0 ? selectedBackendCount : syncedMediaAssets.count
    }

    func remainingSlots(template: MomentTemplate) -> Int {
        MomentsMediaRules.remainingSlots(template: template, selectedCount: effectiveMediaCount)
    }
}

struct MomentsMediaImportProgress: Equatable {
    var completedCount = 0
    var totalCount = 0

    var fractionCompleted: Double? {
        guard totalCount > 0 else { return nil }
        return min(max(Double(completedCount) / Double(totalCount), 0), 1)
    }

    var title: String {
        guard totalCount > 0 else { return L10n.string("create.media.progress.reading") }
        return L10n.string("create.media.progress.count", min(completedCount, totalCount), totalCount)
    }
}

struct MomentsCreateStorySummary: Equatable {
    var savedScenes: [MomentStoryScene] = []
    var generatedScenes: [MomentsStorySceneResponse] = []
    var isPlanning = false
    var statusMessage: String?

    var hasScenes: Bool {
        !savedScenes.isEmpty || !generatedScenes.isEmpty
    }

    var presentedScenes: [MomentsCreateStoryScenePresentation] {
        if !savedScenes.isEmpty {
            return savedScenes
                .sorted { $0.sceneIndex < $1.sceneIndex }
                .map {
                    MomentsCreateStoryScenePresentation(
                        title: Self.sceneTitle(Int($0.sceneIndex)),
                        caption: $0.caption,
                        detail: $0.narrationText
                    )
                }
        }

        return generatedScenes
            .sorted { $0.sceneIndex < $1.sceneIndex }
            .map {
                MomentsCreateStoryScenePresentation(
                    title: Self.sceneTitle($0.sceneIndex),
                    caption: $0.caption,
                    detail: $0.narrationText
                )
            }
    }

    private static func sceneTitle(_ index: Int) -> String {
        switch index {
        case 0:
            return L10n.string("create.story.scene.opening")
        case 1:
            return L10n.string("create.story.scene.main")
        case 2:
            return L10n.string("create.story.scene.ending")
        default:
            return L10n.string("create.story.scene.number", index + 1)
        }
    }
}

struct MomentsCreateStoryScenePresentation: Equatable, Identifiable {
    var id: String { "\(title)-\(caption)" }
    let title: String
    let caption: String
    let detail: String?
}

struct MomentsCreateFinalRenderSummary: Equatable {
    var creditCost = 0
    var renderPlan: MomentsRenderPlanResponse?
    var finalExport: MomentArtifact?
    var pendingGalleryVideo: MomentsGalleryVideoRecord?
    var canRetryFinalVideoDownload = false
    var latestFinalJob: MomentRenderJob?
    var isGenerating = false
    var statusMessage: String?

    var realtimeStatus: MomentsRenderRealtimePresentation? {
        latestFinalJob.map { MomentsRenderRealtimePresentation(renderJob: $0) }
    }

    var effectiveCreditCost: Int {
        renderPlan?.plan.totalCreditCost ?? creditCost
    }
}

struct MomentsRenderRealtimePresentation: Equatable {
    let title: String
    let detail: String
    let progressFraction: Double?
    let systemImage: String
    let isActive: Bool
    let canEditSetup: Bool

    init(renderJob: MomentRenderJob) {
        isActive = renderJob.isActiveRender
        canEditSetup = renderJob.canEditSetup ?? !renderJob.isActiveRender
        title = Self.title(status: renderJob.status, phase: renderJob.phase)
        detail = Self.detail(renderJob)
        progressFraction = Self.progressFraction(renderJob.progressPercent)
        systemImage = Self.systemImage(status: renderJob.status, phase: renderJob.phase)
    }

    private static func title(status: String, phase: String?) -> String {
        if status == "completed" { return L10n.string("create.render.status.ready") }
        if status == "failed" { return L10n.string("create.render.status.needsAttention") }

        switch phase {
        case "preparing":
            return L10n.string("create.render.phase.preparing")
        case "uploading":
            return L10n.string("create.render.phase.uploading")
        case "composing":
            return L10n.string("create.render.phase.composing")
        case "rendering":
            return L10n.string("create.render.phase.rendering")
        case "saving":
            return L10n.string("create.render.phase.saving")
        case "ready":
            return L10n.string("create.render.status.ready")
        case "failed":
            return L10n.string("create.render.status.needsAttention")
        default:
            return status == "queued" ? L10n.string("create.render.status.queued") : L10n.string("create.render.status.working")
        }
    }

    private static func detail(_ renderJob: MomentRenderJob) -> String {
        if renderJob.status == "failed" {
            return MomentsRecoveryCopy.failedRenderDetail(
                userMessage: renderJob.userMessage,
                errorMessage: renderJob.errorMessage
            )
        }

        if let userMessage = renderJob.userMessage, !userMessage.isEmpty {
            return userMessage
        }

        switch renderJob.phase {
        case "preparing":
            return L10n.string("create.render.detail.preparing")
        case "uploading":
            return L10n.string("create.render.detail.uploading")
        case "composing":
            return L10n.string("create.render.detail.composing")
        case "rendering":
            return L10n.string("create.render.detail.rendering")
        case "saving":
            return L10n.string("create.render.detail.saving")
        default:
            return renderJob.isActiveRender ? L10n.string("create.render.detail.realtime") : L10n.string("create.render.detail.available")
        }
    }

    private static func progressFraction(_ progressPercent: Double?) -> Double? {
        guard let progressPercent else { return nil }
        return min(max(progressPercent / 100, 0), 1)
    }

    private static func systemImage(status: String, phase: String?) -> String {
        if status == "completed" { return "checkmark.circle.fill" }
        if status == "failed" { return "exclamationmark.triangle.fill" }

        switch phase {
        case "uploading":
            return "icloud.and.arrow.up.fill"
        case "composing":
            return "rectangle.stack.fill"
        case "rendering":
            return "gearshape.2.fill"
        case "saving":
            return "square.and.arrow.down.fill"
        default:
            return "sparkles"
        }
    }
}
