import Foundation

struct MomentsCreateFinalVideoActionPresentation: Equatable {
    var summary: MomentsCreateFinalRenderSummary
    var template: MomentTemplate
    var balance: MomentsCreditBalance
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
        summary.renderPlan?.plan.totalCreditCost ?? 0
    }

    var totalCreditCostTitle: String {
        MomentsCreditCopy.countTitle(totalCreditCost)
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
        if let backendCost = summary.renderPlan?.plan.totalCreditCost {
            return balance.spendable >= backendCost
        }
        return true
    }
}

struct MomentsCreatePrimaryActionPresentation: Equatable {
    var workflow: MomentsCreateWorkflowPresentation
    var finalVideoAction: MomentsCreateFinalVideoActionPresentation

    init(workflow: MomentsCreateWorkflowPresentation) {
        self.workflow = workflow
        self.finalVideoAction = MomentsCreateFinalVideoActionPresentation(
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
                || workflow.canPlanStory
                || needsSignInForStory
        }
        return workflow.canPlanStory || needsSignInForStory
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
            return finalVideoAction.hasRenderPlan
                ? L10n.string("create.final.readyToCreateTitle")
                : L10n.string("common.continue")
        }
        return L10n.string("common.continue")
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
        if workflow.finalRenderSummary.isGenerating {
            return L10n.string("create.final.creating")
        }
        if hasFinalVideoIntent, needsCreditsForPreparedPlan {
            return L10n.string("credits.get.title")
        }
        if hasFinalVideoIntent {
            if finalVideoAction.hasBlockedRenderPlan {
                return finalVideoAction.canRetryBlockedRenderPlan
                    ? L10n.string("create.final.retrySetup")
                    : L10n.string("create.final.checkCredits")
            }
            return finalVideoAction.hasRenderPlan
                ? finalVideoAction.primaryTitle
                : L10n.string("common.continue")
        }
        if needsSignInForStory {
            return L10n.string("common.signIn")
        }
        return finalVideoAction.primaryTitle
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
        if hasFinalVideoIntent {
            if finalVideoAction.hasBlockedRenderPlan {
                return finalVideoAction.canRetryBlockedRenderPlan
                    ? "arrow.clockwise"
                    : "exclamationmark.triangle.fill"
            }
            return finalVideoAction.primaryIconName
        }
        if needsSignInForStory {
            return "person.crop.circle.badge.checkmark"
        }
        return finalVideoAction.primaryIconName
    }

    var statusMessage: String? {
        if workflow.finalRenderSummary.pendingGalleryVideo != nil {
            return workflow.finalRenderSummary.statusMessage
                ?? L10n.string("workflow.final.savedLocal")
        }
        if workflow.finalRenderSummary.isGenerating {
            return workflow.finalRenderSummary.statusMessage ?? L10n.string("create.final.action.creating")
        }
        if workflow.storySummary.isPlanning {
            return workflow.storySummary.statusMessage ?? L10n.string("create.preparation.prepareStory.progress")
        }
        if workflow.mediaSummary.isImporting {
            return workflow.mediaSummary.statusMessage ?? L10n.string("workflow.media.uploading")
        }
        if workflow.finalRenderSummary.finalExport != nil {
            return L10n.string("create.primary.finalReady")
        }
        if workflow.finalRenderSummary.latestFinalJob != nil {
            return workflow.finalRenderSummary.realtimeStatus?.detail
                ?? workflow.finalRenderSummary.statusMessage
                ?? L10n.string("create.primary.videoCreating")
        }
        if hasFinalVideoIntent {
            if needsCreditsForPreparedPlan {
                guard missingCreditsForPreparedPlan > 0 else {
                    return L10n.string("workflow.final.addCredits")
                }
                return MomentsCreateAvailabilityCopy.finalRenderInsufficientCredits(
                    missingCredits: missingCreditsForPreparedPlan
                )
            }
            if let blockedRenderPlanMessage = finalVideoAction.blockedRenderPlanMessage {
                return blockedRenderPlanMessage
            }
            if let finalStatusMessage = workflow.finalRenderSummary.statusMessage,
               !finalStatusMessage.isEmpty,
               Self.isFinalRenderErrorMessage(finalStatusMessage) {
                return finalStatusMessage
            }
            if finalVideoAction.hasRenderPlan {
                return finalVideoAction.creditPolicyMessage
            }
            if let finalStatusMessage = workflow.finalRenderSummary.statusMessage,
               !finalStatusMessage.isEmpty {
                return finalStatusMessage
            }
            if workflow.canGenerateFinalRender || canPrepareVideoPlan || canPrepareLocalVideoPlan || workflow.canPlanStory {
                return L10n.string("create.primary.continuePreflight")
            }
            return availabilityMessage
        }
        if let storyMessage = workflow.storySummary.statusMessage, !storyMessage.isEmpty {
            return storyMessage
        }
        if let mediaMessage = workflow.mediaSummary.statusMessage, !mediaMessage.isEmpty {
            return mediaMessage
        }
        if !canRunPrimaryAction {
            return availabilityMessage
        }
        if needsSignInForStory {
            return workflow.storyAvailabilityMessage
        }
        if workflow.canPlanStory {
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
        if needsSignInForStory {
            return "person.crop.circle.badge.checkmark"
        }
        if hasFinalVideoIntent {
            return finalVideoAction.primaryIconName
        }
        return "creditcard.fill"
    }

    var hasFinalVideoIntent: Bool {
        workflow.mediaSummary.effectiveMediaCount > 0
            || workflow.storySummary.hasScenes
            || workflow.finalRenderSummary.renderPlan != nil
            || workflow.finalRenderSummary.latestFinalJob != nil
            || workflow.finalRenderSummary.finalExport != nil
            || workflow.finalRenderSummary.pendingGalleryVideo != nil
    }

    var isBusy: Bool {
        workflow.mediaSummary.isImporting
            || workflow.storySummary.isPlanning
            || workflow.finalRenderSummary.isGenerating
    }

    var hasRetryableFinalRenderJob: Bool {
        guard let latestFinalJob = workflow.finalRenderSummary.latestFinalJob,
              latestFinalJob.canRetry == true else {
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
            && workflow.finalRenderSummary.renderPlan == nil
    }

    var needsSignInForStory: Bool {
        !workflow.isSignedIn
            && workflow.mediaSummary.effectiveMediaCount > 0
            && !workflow.storySummary.isPlanning
    }

    var needsCreditsForPreparedPlan: Bool {
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
                ?? workflow.storyAvailabilityMessage
                ?? workflow.mediaAvailabilityMessage
        }
        return workflow.finalRenderAvailabilityMessage ?? workflow.storyAvailabilityMessage
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
