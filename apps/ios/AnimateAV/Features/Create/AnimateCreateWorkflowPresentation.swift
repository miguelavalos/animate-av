import Foundation

struct AnimateCreateWorkflowPresentation: Equatable {
    var activeMomentId: String?
    var isSignedIn = false
    var isCreatingMoment = false
    var hasAnimateWorkspace = false
    var hasUnsavedLocalMoment = false
    var template: AnimateVideoTemplate
    var creationStyleTitle = ""
    var toneTitle = ""
    var tempoTitle = ""
    var occasionTitle = ""
    var balance: AnimateCreditBalance
    var creditBalanceLoadState = AnimateCreditBalanceLoadState.loaded
    var mediaSummary: AnimateCreateMediaSummary
    var storySummary: AnimateCreateStorySummary
    var finalRenderSummary: AnimateCreateFinalRenderSummary
    var canAddMedia = false
    var canPlanStory = false
    var canPrepareFinalRenderPlan = false
    var canGenerateFinalRender = false
    var canRefreshFinalRenderStatus = false
    var mediaAvailabilityMessage: String?
    var storyAvailabilityMessage: String?
    var finalRenderAvailabilityMessage: String?

    var showsWorkflowCards: Bool {
        hasAnimateWorkspace
    }

    var showsMediaFirstWorkspace: Bool {
        hasAnimateWorkspace
            || hasUnsavedLocalMoment
            || mediaSummary.selectedCount > 0
            || !mediaSummary.syncedMediaAssets.isEmpty
            || finalRenderSummary.finalExport != nil
    }

    var currentStage: AnimateCreateCurrentStage {
        if finalRenderSummary.finalExport != nil {
            return .finalVideo
        }

        if !storySummary.savedScenes.isEmpty || !storySummary.generatedScenes.isEmpty {
            return .finalVideo
        }

        if canPlanStory {
            return .story
        }

        return .media
    }

    var showsBlockingPreparation: Bool {
        isCreatingMoment
            || mediaSummary.isImporting
            || storySummary.isPlanning
            || finalRenderSummary.isGenerating
    }

    var isFinalRenderEditingLocked: Bool {
        guard finalRenderSummary.finalExport == nil else {
            return false
        }
        guard let latestFinalJob = finalRenderSummary.latestFinalJob,
              latestFinalJob.isActiveRender else {
            return false
        }
        return latestFinalJob.canEditSetup != true
    }

    var lockedFinalRenderMediaCountTitle: String {
        let count = lockedFinalRenderMediaCount ?? mediaSummary.effectiveMediaCount
        guard count > 0 else {
            return L10n.string("create.final.confirmSheet.media")
        }
        return count == 1 ? "1 item" : "\(count) items"
    }

    private var lockedFinalRenderMediaCount: Int? {
        guard let latestFinalJob = finalRenderSummary.latestFinalJob else {
            return nil
        }
        let value = latestFinalJob.usedAssetCount ?? latestFinalJob.plannedAssetCount
        guard let value, value.isFinite, value > 0 else {
            return nil
        }
        return Int(value.rounded())
    }

    var lockedFinalRenderCreditCost: Int {
        if let totalCreditCost = finalRenderSummary.latestFinalJob?.totalCreditCost,
           totalCreditCost.isFinite,
           totalCreditCost > 0 {
            return Int(totalCreditCost.rounded())
        }

        return finalRenderSummary.effectiveCreditCost
    }

    static func make(
        activeMomentId: String?,
        isSignedIn: Bool,
        isCreatingMoment: Bool,
        hasAnimateWorkspace: Bool,
        hasUnsavedLocalMoment: Bool,
        template: AnimateVideoTemplate,
        creationStyleTitle: String,
        toneTitle: String,
        tempoTitle: String,
        occasionTitle: String,
        balance: AnimateCreditBalance,
        creditBalanceLoadState: AnimateCreditBalanceLoadState = .loaded,
        mediaSummary: AnimateCreateMediaSummary,
        storySummary: AnimateCreateStorySummary,
        finalRenderSummary: AnimateCreateFinalRenderSummary,
        availability: AnimateCreateWorkflowAvailability
    ) -> AnimateCreateWorkflowPresentation {
        AnimateCreateWorkflowPresentation(
            activeMomentId: activeMomentId,
            isSignedIn: isSignedIn,
            isCreatingMoment: isCreatingMoment,
            hasAnimateWorkspace: hasAnimateWorkspace,
            hasUnsavedLocalMoment: hasUnsavedLocalMoment,
            template: template,
            creationStyleTitle: creationStyleTitle,
            toneTitle: toneTitle,
            tempoTitle: tempoTitle,
            occasionTitle: occasionTitle,
            balance: balance,
            creditBalanceLoadState: creditBalanceLoadState,
            mediaSummary: mediaSummary,
            storySummary: storySummary,
            finalRenderSummary: finalRenderSummary,
            canAddMedia: availability.canAddMedia,
            canPlanStory: availability.canPlanStory,
            canPrepareFinalRenderPlan: availability.canPrepareFinalRenderPlan,
            canGenerateFinalRender: availability.canGenerateFinalRender,
            canRefreshFinalRenderStatus: availability.canRefreshFinalRenderStatus,
            mediaAvailabilityMessage: availability.mediaMessage,
            storyAvailabilityMessage: availability.storyMessage,
            finalRenderAvailabilityMessage: availability.finalRenderMessage
        )
    }
}

enum AnimateCreateCurrentStage: Equatable {
    case media
    case story
    case finalVideo
}
