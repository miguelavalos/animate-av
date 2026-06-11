import Foundation

struct AnimateCreateWorkflowPresentation: Equatable {
    var activeVideoId: String?
    var isSignedIn = false
    var isCreatingVideo = false
    var hasActiveVideoWorkspace = false
    var hasUnsavedLocalVideo = false
    var template: AnimateVideoTemplate
    var creationStyleTitle = ""
    var selectedLook: AnimateVideoLook?
    var toneTitle = ""
    var tempoTitle = ""
    var occasionTitle = ""
    var balance: AnimateCreditBalance
    var creditBalanceLoadState = AnimateCreditBalanceLoadState.loaded
    var mediaSummary: AnimateCreateMediaSummary
    var videoDirectionSummary: AnimateCreateVideoDirectionSummary
    var finalRenderSummary: AnimateCreateFinalRenderSummary
    var canAddMedia = false
    var canPrepareVideoDirection = false
    var canPrepareFinalRenderPlan = false
    var canGenerateFinalRender = false
    var canRefreshFinalRenderStatus = false
    var mediaAvailabilityMessage: String?
    var videoDirectionAvailabilityMessage: String?
    var finalRenderAvailabilityMessage: String?

    var showsWorkflowCards: Bool {
        hasActiveVideoWorkspace
    }

    var showsMediaFirstWorkspace: Bool {
        hasActiveVideoWorkspace
            || hasUnsavedLocalVideo
            || mediaSummary.selectedCount > 0
            || !mediaSummary.syncedMediaAssets.isEmpty
            || finalRenderSummary.finalExport != nil
    }

    var currentStage: AnimateCreateCurrentStage {
        if finalRenderSummary.finalExport != nil {
            return .finalVideo
        }

        if !videoDirectionSummary.savedScenes.isEmpty || !videoDirectionSummary.generatedScenes.isEmpty {
            return .finalVideo
        }

        if canPrepareVideoDirection {
            return .story
        }

        return .media
    }

    var showsBlockingPreparation: Bool {
        isCreatingVideo
            || mediaSummary.isImporting
            || videoDirectionSummary.isPlanning
            || (finalRenderSummary.isGenerating && !finalRenderSummary.isPreparingPlan)
            || finalRenderSummary.latestFinalJob?.isActiveRender == true
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
        activeVideoId: String?,
        isSignedIn: Bool,
        isCreatingVideo: Bool,
        hasActiveVideoWorkspace: Bool,
        hasUnsavedLocalVideo: Bool,
        template: AnimateVideoTemplate,
        creationStyleTitle: String,
        selectedLook: AnimateVideoLook?,
        toneTitle: String,
        tempoTitle: String,
        occasionTitle: String,
        balance: AnimateCreditBalance,
        creditBalanceLoadState: AnimateCreditBalanceLoadState = .loaded,
        mediaSummary: AnimateCreateMediaSummary,
        videoDirectionSummary: AnimateCreateVideoDirectionSummary,
        finalRenderSummary: AnimateCreateFinalRenderSummary,
        availability: AnimateCreateWorkflowAvailability
    ) -> AnimateCreateWorkflowPresentation {
        AnimateCreateWorkflowPresentation(
            activeVideoId: activeVideoId,
            isSignedIn: isSignedIn,
            isCreatingVideo: isCreatingVideo,
            hasActiveVideoWorkspace: hasActiveVideoWorkspace,
            hasUnsavedLocalVideo: hasUnsavedLocalVideo,
            template: template,
            creationStyleTitle: creationStyleTitle,
            selectedLook: selectedLook,
            toneTitle: toneTitle,
            tempoTitle: tempoTitle,
            occasionTitle: occasionTitle,
            balance: balance,
            creditBalanceLoadState: creditBalanceLoadState,
            mediaSummary: mediaSummary,
            videoDirectionSummary: videoDirectionSummary,
            finalRenderSummary: finalRenderSummary,
            canAddMedia: availability.canAddMedia,
            canPrepareVideoDirection: availability.canPrepareVideoDirection,
            canPrepareFinalRenderPlan: availability.canPrepareFinalRenderPlan,
            canGenerateFinalRender: availability.canGenerateFinalRender,
            canRefreshFinalRenderStatus: availability.canRefreshFinalRenderStatus,
            mediaAvailabilityMessage: availability.mediaMessage,
            videoDirectionAvailabilityMessage: availability.videoDirectionMessage,
            finalRenderAvailabilityMessage: availability.finalRenderMessage
        )
    }
}

enum AnimateCreateCurrentStage: Equatable {
    case media
    case story
    case finalVideo
}
