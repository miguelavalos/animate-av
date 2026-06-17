import Foundation

struct AnimateCreateFinalVideoActionPresentation: Equatable {
    var summary: AnimateCreateFinalRenderSummary
    var template: AnimateVideoTemplate
    var balance: AnimateCreditBalance
    var removesWatermark = false

    var hasRenderPlan: Bool {
        summary.renderPlan?.canCreateVideo == true
    }

    var hasBlockedRenderPlan: Bool {
        summary.renderPlan != nil && !hasRenderPlan
    }

    var blockedRenderPlanMessage: String? {
        guard hasBlockedRenderPlan else { return nil }
        let blockers = summary.renderPlan?.createVideoBlockers ?? []
        if blockers.contains("provider_adapter_unavailable") || blockers.contains("render_option_unavailable") {
            return L10n.string("create.final.blocker.videoSetupUnavailable")
        }
        if blockedRenderPlanIsInsufficientCredits {
            return L10n.string("create.final.blocker.insufficientCredits")
        }
        if blockers.contains("no_usable_media") || blockers.contains("all_media_rejected") {
            return L10n.string("create.final.blocker.noUsableMedia")
        }
        return L10n.string("create.final.blocker.default")
    }

    var blockedRenderPlanIsInsufficientCredits: Bool {
        hasBlockedRenderPlan
            && (summary.renderPlan?.createVideoBlockers ?? []).contains("insufficient_credits")
    }

    var canRetryBlockedRenderPlan: Bool {
        hasBlockedRenderPlan && !blockedRenderPlanIsInsufficientCredits
    }

    var canShowConfirmationSheet: Bool {
        hasRenderPlan || blockedRenderPlanIsInsufficientCredits
    }

    var totalCreditCost: Int {
        summary.videoQuote?.totalCreditCost ?? summary.renderPlan?.plan.totalCreditCost ?? 0
    }

    var totalCreditCostTitle: String {
        AnimateCreditCopy.countTitle(totalCreditCost)
    }

    var primaryTitle: String {
        hasRenderPlan
            ? L10n.string("create.final.confirmCredits", totalCreditCostTitle)
            : L10n.string("create.final.checkCredits")
    }

    var primaryIconName: String {
        hasRenderPlan ? "video.fill" : "creditcard.fill"
    }

    var creditPolicyMessage: String {
        hasRenderPlan
            ? L10n.string("create.final.creditPolicy.create", totalCreditCostTitle)
            : L10n.string("create.final.creditPolicy.preflight")
    }

    var confirmationTitle: String {
        L10n.string("create.final.confirmTitle")
    }

    var confirmationActionTitle: String {
        L10n.string("create.final.createWithCost", totalCreditCostTitle)
    }

    var confirmationMessage: String {
        L10n.string("create.final.confirmMessage", totalCreditCostTitle)
    }

    var canAffordSelectedCost: Bool {
        if let backendCost = summary.videoQuote?.totalCreditCost ?? summary.renderPlan?.plan.totalCreditCost {
            return balance.spendable >= backendCost
        }
        return true
    }
}

struct AnimateCreatePrimaryActionPresentation: Equatable {
    var workflow: AnimateCreateWorkflowPresentation
    var finalVideoAction: AnimateCreateFinalVideoActionPresentation

    init(workflow: AnimateCreateWorkflowPresentation) {
        self.workflow = workflow
        self.finalVideoAction = AnimateCreateFinalVideoActionPresentation(
            summary: workflow.finalRenderSummary,
            template: workflow.template,
            balance: workflow.balance
        )
    }

    var canRunPrimaryAction: Bool {
        if isBusy {
            return false
        }
        if workflow.finalRenderSummary.pendingGalleryVideo != nil || workflow.finalRenderSummary.finalExport != nil {
            return false
        }
        if hasRetryableFinalRenderJob {
            return workflow.canGenerateFinalRender
                || canPrepareVideoPlan
                || canPrepareLocalVideoPlan
        }
        if workflow.finalRenderSummary.latestFinalJob != nil {
            return false
        }
        if hasFinalVideoIntent {
            if needsSignInForFinalRender {
                return true
            }
            if !hasCompletedVideoDirection {
                return workflow.mediaSummary.effectiveMediaCount > 0
                    || workflow.canPrepareVideoDirection
                    || needsSignInForVideoDirection
            }
            if needsCreditsForPreparedPlan {
                return true
            }
            if finalVideoAction.canRetryBlockedRenderPlan {
                return workflow.canPrepareFinalRenderPlan || canPrepareLocalVideoPlan
            }
            if finalVideoAction.hasBlockedRenderPlan {
                return false
            }
            return workflow.canGenerateFinalRender
                || canPrepareVideoPlan
                || canPrepareLocalVideoPlan
                || workflow.canPrepareVideoDirection
                || needsSignInForVideoDirection
        }
        return workflow.canPrepareVideoDirection || needsSignInForVideoDirection
    }

    var showsPrimaryActionButton: Bool {
        workflow.finalRenderSummary.pendingGalleryVideo == nil
            && workflow.finalRenderSummary.finalExport == nil
            && (workflow.finalRenderSummary.latestFinalJob == nil || hasRetryableFinalRenderJob)
    }

    var title: String {
        if workflow.finalRenderSummary.finalExport != nil || workflow.finalRenderSummary.latestFinalJob != nil {
            return L10n.string("create.final.video")
        }
        if hasFinalVideoIntent {
            if !hasCompletedVideoDirection {
                return L10n.string("create.primary.continueWithVideo")
            }
            return finalVideoAction.hasRenderPlan
                ? L10n.string("create.final.readyToCreateTitle")
                : L10n.string("create.primary.continueWithVideo")
        }
        return L10n.string("create.primary.continueWithVideo")
    }

    var buttonTitle: String {
        if workflow.finalRenderSummary.pendingGalleryVideo != nil {
            return L10n.string("create.final.chooseDestination")
        }
        if workflow.finalRenderSummary.finalExport != nil {
            return L10n.string("create.final.videoReady")
        }
        if workflow.finalRenderSummary.latestFinalJob != nil {
            if hasRetryableFinalRenderJob {
                return L10n.string("create.final.retrySetup")
            }
            return L10n.string("create.final.video")
        }
        if workflow.finalRenderSummary.isPreparingPlan {
            return L10n.string("create.final.checkingCost")
        }
        if workflow.finalRenderSummary.isGenerating {
            return L10n.string("create.final.creating")
        }
        if workflow.mediaSummary.isImporting {
            return workflow.mediaSummary.statusMessage ?? L10n.string("workflow.media.uploading")
        }
        if hasFinalVideoIntent, needsSignInForFinalRender {
            return L10n.string("common.signIn")
        }
        if hasFinalVideoIntent, needsCreditsForPreparedPlan {
            return L10n.string("credits.get.title")
        }
        if hasFinalVideoIntent {
            if !hasCompletedVideoDirection {
                return hasSelectedVideoLook
                    ? L10n.string("create.guided.continue.movement")
                    : L10n.string("create.guided.look.noneSelected.title")
            }
            if finalVideoAction.hasBlockedRenderPlan {
                return finalVideoAction.canRetryBlockedRenderPlan
                    ? L10n.string("create.final.retrySetup")
                    : L10n.string("create.final.checkCredits")
            }
            return finalVideoAction.hasRenderPlan
                ? finalVideoAction.primaryTitle
                : L10n.string("create.primary.continueWithVideo")
        }
        if needsSignInForVideoDirection {
            return L10n.string("common.signIn")
        }
        return L10n.string("create.primary.continueWithVideo")
    }

    var buttonIconName: String {
        if workflow.finalRenderSummary.pendingGalleryVideo != nil {
            return "rectangle.stack.badge.play.fill"
        }
        if workflow.finalRenderSummary.finalExport != nil {
            return "checkmark.circle.fill"
        }
        if workflow.finalRenderSummary.latestFinalJob != nil {
            if hasRetryableFinalRenderJob {
                return "arrow.clockwise"
            }
            return "video.fill"
        }
        if hasFinalVideoIntent, needsCreditsForPreparedPlan {
            return "plus.circle.fill"
        }
        if hasFinalVideoIntent, needsSignInForFinalRender {
            return "person.crop.circle.badge.checkmark"
        }
        if hasFinalVideoIntent {
            if !hasCompletedVideoDirection {
                return hasSelectedVideoLook ? "message.fill" : "paintbrush.pointed.fill"
            }
            if finalVideoAction.hasBlockedRenderPlan {
                return finalVideoAction.canRetryBlockedRenderPlan
                    ? "arrow.clockwise"
                    : "exclamationmark.triangle.fill"
            }
            return finalVideoAction.primaryIconName
        }
        if needsSignInForVideoDirection {
            return "person.crop.circle.badge.checkmark"
        }
        return finalVideoAction.primaryIconName
    }

    var statusMessage: String? {
        if workflow.finalRenderSummary.pendingGalleryVideo != nil {
            return workflow.finalRenderSummary.statusMessage
                ?? L10n.string("workflow.final.savedLocal")
        }
        if workflow.finalRenderSummary.isPreparingPlan {
            return workflow.finalRenderSummary.statusMessage ?? L10n.string("workflow.final.checkingPlan")
        }
        if workflow.finalRenderSummary.isGenerating {
            return workflow.finalRenderSummary.statusMessage ?? L10n.string("create.final.action.creating")
        }
        if workflow.videoDirectionSummary.isPlanning {
            return workflow.videoDirectionSummary.statusMessage ?? L10n.string("create.preparation.prepareStory.progress")
        }
        if workflow.mediaSummary.isImporting {
            return workflow.mediaSummary.statusMessage ?? L10n.string("workflow.media.uploading")
        }
        if workflow.finalRenderSummary.finalExport != nil {
            return workflow.finalRenderSummary.statusMessage ?? L10n.string("create.primary.finalReady")
        }
        if workflow.finalRenderSummary.latestFinalJob != nil {
            return workflow.finalRenderSummary.realtimeStatus?.detail
                ?? workflow.finalRenderSummary.statusMessage
                ?? L10n.string("create.primary.videoCreating")
        }
        if let finalStatusMessage = workflow.finalRenderSummary.statusMessage,
           !finalStatusMessage.isEmpty {
            return finalStatusMessage
        }
        if hasFinalVideoIntent {
            if needsSignInForFinalRender {
                return L10n.string("workflow.final.signInAgainRender")
            }
            if let finalStatusMessage = workflow.finalRenderSummary.statusMessage,
               !finalStatusMessage.isEmpty,
               Self.isFinalRenderErrorMessage(finalStatusMessage) {
                return finalStatusMessage
            }
            if !hasCompletedVideoDirection {
                return hasSelectedVideoLook
                    ? L10n.string("create.storyDirection.needsStory")
                    : L10n.string("create.primary.continuePreflight")
            }
            if needsCreditsForPreparedPlan {
                guard missingCreditsForPreparedPlan > 0 else {
                    return L10n.string("workflow.final.addCredits")
                }
                return AnimateCreateAvailabilityCopy.finalRenderInsufficientCredits(
                    missingCredits: missingCreditsForPreparedPlan
                )
            }
            if let blockedRenderPlanMessage = finalVideoAction.blockedRenderPlanMessage {
                return blockedRenderPlanMessage
            }
            if finalVideoAction.hasRenderPlan {
                return finalVideoAction.creditPolicyMessage
            }
            if workflow.canGenerateFinalRender || canPrepareVideoPlan || canPrepareLocalVideoPlan || workflow.canPrepareVideoDirection {
                return L10n.string("create.primary.continuePreflight")
            }
            return availabilityMessage
        }
        if let videoDirectionMessage = workflow.videoDirectionSummary.statusMessage, !videoDirectionMessage.isEmpty {
            return videoDirectionMessage
        }
        if let mediaMessage = workflow.mediaSummary.statusMessage, !mediaMessage.isEmpty {
            return mediaMessage
        }
        if !canRunPrimaryAction {
            return availabilityMessage
        }
        if needsSignInForVideoDirection {
            return workflow.videoDirectionAvailabilityMessage
        }
        if workflow.canPrepareVideoDirection {
            return L10n.string("create.primary.continuePreflight")
        }
        return nil
    }

    var statusIconName: String {
        if isBusy {
            return "sparkles"
        }
        if workflow.finalRenderSummary.finalExport != nil {
            return "checkmark.circle.fill"
        }
        if !canRunPrimaryAction {
            return "info.circle.fill"
        }
        return "play.circle.fill"
    }

    var primaryHeaderIconName: String {
        if workflow.finalRenderSummary.pendingGalleryVideo != nil {
            return "rectangle.stack.badge.play.fill"
        }
        if workflow.finalRenderSummary.finalExport != nil {
            return "checkmark.circle.fill"
        }
        if hasRetryableFinalRenderJob {
            return "arrow.clockwise"
        }
        if let realtimeStatus = workflow.finalRenderSummary.realtimeStatus {
            return realtimeStatus.systemImage
        }
        if workflow.finalRenderSummary.latestFinalJob != nil {
            return "video.fill"
        }
        if needsSignInForVideoDirection {
            return "person.crop.circle.badge.checkmark"
        }
        if hasFinalVideoIntent {
            if !hasCompletedVideoDirection {
                return hasSelectedVideoLook ? "message.fill" : "paintbrush.pointed.fill"
            }
            return finalVideoAction.primaryIconName
        }
        return "creditcard.fill"
    }

    var hasFinalVideoIntent: Bool {
        workflow.mediaSummary.effectiveMediaCount > 0
            || workflow.videoDirectionSummary.hasScenes
            || workflow.finalRenderSummary.renderPlan != nil
            || workflow.finalRenderSummary.latestFinalJob != nil
            || workflow.finalRenderSummary.finalExport != nil
            || workflow.finalRenderSummary.pendingGalleryVideo != nil
    }

    var hasCompletedVideoDirection: Bool {
        workflow.videoDirectionSummary.hasScenes
            || workflow.finalRenderSummary.renderPlan != nil
            || (workflow.mediaSummary.effectiveMediaCount > 0 && workflow.selectedLook != nil)
    }

    var hasSelectedVideoLook: Bool {
        workflow.selectedLook != nil
    }

    var isBusy: Bool {
        workflow.mediaSummary.isImporting
            || workflow.videoDirectionSummary.isPlanning
            || workflow.finalRenderSummary.isGenerating
            || workflow.finalRenderSummary.isPreparingPlan
    }

    var hasRetryableFinalRenderJob: Bool {
        guard let latestFinalJob = workflow.finalRenderSummary.latestFinalJob,
              latestFinalJob.canRetry != false else {
            return false
        }
        return latestFinalJob.status == "failed" || latestFinalJob.status == "cancelled"
    }

    var canPrepareVideoPlan: Bool {
        workflow.canPrepareFinalRenderPlan
            && workflow.finalRenderSummary.renderPlan == nil
    }

    var canPrepareLocalVideoPlan: Bool {
        workflow.isSignedIn
            && workflow.mediaSummary.effectiveMediaCount > 0
            && hasCompletedVideoDirection
            && workflow.finalRenderSummary.renderPlan == nil
    }

    var needsSignInForVideoDirection: Bool {
        !workflow.isSignedIn
            && workflow.mediaSummary.effectiveMediaCount > 0
            && !workflow.videoDirectionSummary.isPlanning
    }

    var needsSignInForFinalRender: Bool {
        hasCompletedVideoDirection
            && workflow.finalRenderSummary.latestFinalJob == nil
            && workflow.finalRenderSummary.finalExport == nil
            && workflow.finalRenderSummary.pendingGalleryVideo == nil
            && !workflow.isSignedIn
    }

    var needsCreditsForPreparedPlan: Bool {
        guard hasCompletedVideoDirection else {
            return false
        }
        if finalVideoAction.blockedRenderPlanIsInsufficientCredits {
            return true
        }

        return missingCreditsForPreparedPlan > 0 && finalVideoAction.hasRenderPlan
    }

    private var missingCreditsForPreparedPlan: Int {
        max(0, finalVideoAction.totalCreditCost - workflow.balance.spendable)
    }

    private var availabilityMessage: String? {
        if workflow.finalRenderSummary.latestFinalJob != nil {
            return workflow.finalRenderAvailabilityMessage
        }
        if hasFinalVideoIntent {
            return workflow.finalRenderAvailabilityMessage
                ?? workflow.videoDirectionAvailabilityMessage
                ?? workflow.mediaAvailabilityMessage
        }
        return workflow.finalRenderAvailabilityMessage ?? workflow.videoDirectionAvailabilityMessage
    }

    private static func isFinalRenderErrorMessage(_ message: String) -> Bool {
        let lowercased = message.lowercased()
        return lowercased.contains("couldn’t")
            || lowercased.contains("couldn't")
            || lowercased.contains("failed")
            || lowercased.contains("not configured")
            || lowercased.contains("not available")
            || lowercased.contains("sign in again")
            || lowercased.contains("try again")
            || lowercased.contains("changed")
    }

}
