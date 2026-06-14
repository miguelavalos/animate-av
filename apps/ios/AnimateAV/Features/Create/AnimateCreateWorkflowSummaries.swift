import Foundation

struct AnimateCreateWorkspaceSummary: Equatable {
    var mediaCount = 0
    var sceneCount = 0
    var renderJobCount = 0
    var hasFinalExport = false

    var mediaDetail: String {
        L10n.string("create.summary.media.added", mediaCount)
    }

    var videoDirectionDetail: String {
        L10n.string(sceneCount == 1 ? "create.summary.story.scene" : "create.summary.story.scenes", sceneCount)
    }

    static func make(
        workspace: AnimateWorkspace?,
        finalExport: AnimateArtifact?
    ) -> AnimateCreateWorkspaceSummary {
        AnimateCreateWorkspaceSummary(
            mediaCount: workspace?.mediaAssets.count ?? 0,
            sceneCount: workspace?.storyScenes.count ?? 0,
            renderJobCount: workspace?.renderJobs.count ?? 0,
            hasFinalExport: finalExport != nil
        )
    }

}

struct AnimateCreateMediaSummary: Equatable {
    var selectedMedia: [AnimateSelectedMedia] = []
    var syncedMediaAssets: [AnimateMediaAsset] = []
    var isImporting = false
    var importProgress: AnimateMediaImportProgress?
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

    func remainingSlots(template: AnimateVideoTemplate) -> Int {
        AnimateMediaRules.remainingSlots(template: template, selectedCount: effectiveMediaCount)
    }
}

struct AnimateMediaImportProgress: Equatable {
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

struct AnimateCreateVideoDirectionSummary: Equatable {
    var savedScenes: [AnimateVideoDirectionScene] = []
    var generatedScenes: [AnimateVideoDirectionSceneResponse] = []
    var isPlanning = false
    var statusMessage: String?

    var hasScenes: Bool {
        !savedScenes.isEmpty || !generatedScenes.isEmpty
    }

    var presentedScenes: [AnimateCreateVideoDirectionScenePresentation] {
        if !savedScenes.isEmpty {
            return savedScenes
                .sorted { $0.sceneIndex < $1.sceneIndex }
                .map {
                    AnimateCreateVideoDirectionScenePresentation(
                        title: Self.sceneTitle(Int($0.sceneIndex)),
                        caption: $0.caption,
                        detail: $0.narrationText
                    )
                }
        }

        return generatedScenes
            .sorted { $0.sceneIndex < $1.sceneIndex }
            .map {
                AnimateCreateVideoDirectionScenePresentation(
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

struct AnimateCreateVideoDirectionScenePresentation: Equatable, Identifiable {
    var id: String { "\(title)-\(caption)" }
    let title: String
    let caption: String
    let detail: String?
}

struct AnimateCreateFinalRenderSummary: Equatable {
    var creditCost = 0
    var renderPlan: AnimateRenderPlanResponse?
    var videoQuote: AnimateVideoQuoteResponse?
    var finalExport: AnimateArtifact?
    var pendingGalleryVideo: AnimateGalleryVideoRecord?
    var generatedImagePreviewLocalRelativePath: String?
    var canRetryFinalVideoDownload = false
    var latestFinalJob: AnimateRenderJob?
    var isGenerating = false
    var isPreparingPlan = false
    var statusMessage: String?

    var realtimeStatus: AnimateRenderRealtimePresentation? {
        latestFinalJob.map { AnimateRenderRealtimePresentation(renderJob: $0) }
    }

    var effectiveCreditCost: Int {
        videoQuote?.totalCreditCost ?? renderPlan?.plan.totalCreditCost ?? creditCost
    }
}

struct AnimateRenderRealtimePresentation: Equatable {
    let title: String
    let detail: String
    let progressFraction: Double?
    let systemImage: String
    let isActive: Bool
    let canEditSetup: Bool
    let visualStage: VisualStage
    let hasMessage: Bool
    let steps: [Step]

    init(renderJob: AnimateRenderJob) {
        isActive = renderJob.isActiveRender
        canEditSetup = renderJob.canEditSetup ?? !renderJob.isActiveRender
        hasMessage = !(renderJob.script ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        title = Self.title(status: renderJob.status, phase: renderJob.phase)
        detail = Self.detail(renderJob)
        progressFraction = Self.progressFraction(renderJob.progressPercent, status: renderJob.status)
        systemImage = Self.systemImage(status: renderJob.status, phase: renderJob.phase)
        visualStage = Self.visualStage(status: renderJob.status, phase: renderJob.phase)
        steps = Self.steps(status: renderJob.status, phase: renderJob.phase, includesAudio: hasMessage)
    }

    enum VisualStage: Equatable {
        case sourcePhoto
        case styledImage
        case voiceover
        case animatingVideo
        case finishing
        case completed
        case failed
    }

    struct Step: Equatable, Identifiable {
        enum State: Equatable {
            case pending
            case current
            case done
            case failed
        }

        let id: String
        let title: String
        let detail: String
        let systemImage: String
        let state: State
    }

    private static func title(status: String, phase: String?) -> String {
        if status == "completed" { return L10n.string("create.render.status.ready") }
        if status == "failed" { return L10n.string("create.render.status.needsAttention") }

        switch phase {
        case "preparing", "preparing_source":
            return L10n.string("create.render.phase.preparing")
        case "generating_image":
            return L10n.string("create.render.phase.image")
        case "generating_audio":
            return L10n.string("create.render.phase.audio")
        case "uploading":
            return L10n.string("create.render.phase.uploading")
        case "composing":
            return L10n.string("create.render.phase.composing")
        case "rendering", "animating_video":
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

    private static func detail(_ renderJob: AnimateRenderJob) -> String {
        if renderJob.status == "failed" {
            return AnimateRecoveryCopy.failedRenderDetail(
                userMessage: renderJob.userMessage,
                errorMessage: renderJob.errorMessage
            )
        }

        switch renderJob.phase {
        case "preparing", "preparing_source":
            return L10n.string("create.render.detail.preparing")
        case "generating_image":
            return L10n.string("create.render.detail.image")
        case "generating_audio":
            return L10n.string("create.render.detail.audio")
        case "uploading":
            return L10n.string("create.render.detail.uploading")
        case "composing":
            return L10n.string("create.render.detail.composing")
        case "rendering", "animating_video":
            return L10n.string("create.render.detail.rendering")
        case "saving":
            return L10n.string("create.render.detail.saving")
        default:
            if renderJob.isActiveRender {
                return L10n.string("create.render.detail.realtime")
            }
            if let userMessage = renderJob.userMessage, !userMessage.isEmpty {
                return userMessage
            }
            return L10n.string("create.render.detail.available")
        }
    }

    private static func progressFraction(_ progressPercent: Double?, status: String) -> Double? {
        if status == "completed" { return 1 }
        guard let progressPercent else { return nil }
        return min(max(progressPercent / 100, 0), 1)
    }

    private static func systemImage(status: String, phase: String?) -> String {
        if status == "completed" { return "checkmark.circle.fill" }
        if status == "failed" { return "exclamationmark.triangle.fill" }

        switch phase {
        case "generating_image":
            return "photo.fill"
        case "generating_audio":
            return "waveform"
        case "uploading":
            return "icloud.and.arrow.up.fill"
        case "composing":
            return "rectangle.stack.fill"
        case "rendering", "animating_video":
            return "gearshape.2.fill"
        case "saving":
            return "square.and.arrow.down.fill"
        default:
            return "sparkles"
        }
    }

    private static func steps(status: String, phase: String?, includesAudio: Bool) -> [Step] {
        var orderedSteps: [(id: String, title: String, detail: String, icon: String)] = [
            ("generating_image", L10n.string("create.render.step.image.title"), L10n.string("create.render.step.image.detail"), "photo.fill")
        ]
        if includesAudio {
            orderedSteps.append(("generating_audio", L10n.string("create.render.step.audio.title"), L10n.string("create.render.step.audio.detail"), "waveform"))
        }
        orderedSteps.append(contentsOf: [
            (id: "animating_video", title: L10n.string("create.render.step.video.title"), detail: L10n.string("create.render.step.video.detail"), icon: "sparkles.tv.fill"),
            (id: "saving", title: L10n.string("create.render.step.finish.title"), detail: L10n.string("create.render.step.finish.detail"), icon: "square.and.arrow.down.fill")
        ])
        let normalizedPhase = normalizedPhase(phase)
        let currentIndex = orderedSteps.firstIndex { $0.id == normalizedPhase } ?? 0

        return orderedSteps.enumerated().map { index, step in
            Step(
                id: step.id,
                title: step.title,
                detail: step.detail,
                systemImage: step.icon,
                state: stepState(status: status, index: index, currentIndex: currentIndex)
            )
        }
    }

    private static func normalizedPhase(_ phase: String?) -> String {
        switch phase {
        case "preparing", "preparing_source":
            return "generating_image"
        case "rendering":
            return "animating_video"
        case "completed":
            return "saving"
        default:
            return phase ?? "generating_image"
        }
    }

    private static func stepState(status: String, index: Int, currentIndex: Int) -> Step.State {
        if status == "completed" { return .done }
        if status == "failed" {
            return index < currentIndex ? .done : index == currentIndex ? .failed : .pending
        }
        if index < currentIndex { return .done }
        if index == currentIndex { return .current }
        return .pending
    }

    private static func visualStage(status: String, phase: String?) -> VisualStage {
        if status == "completed" { return .completed }
        if status == "failed" { return .failed }

        switch phase {
        case "generating_image", "preparing", "preparing_source":
            return .sourcePhoto
        case "generating_audio":
            return .voiceover
        case "animating_video", "rendering":
            return .animatingVideo
        case "saving", "completed":
            return .finishing
        default:
            return .styledImage
        }
    }
}
