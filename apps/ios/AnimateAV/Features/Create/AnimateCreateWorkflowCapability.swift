import Foundation

@MainActor
enum AnimateCreateWorkflowCapabilityFactory {
    static func make(
        activeVideoId: String?,
        isSignedIn: Bool,
        hasAnimateWorkspace: Bool,
        isImportingMedia: Bool,
        mediaRemainingSlots: Int,
        storyWorkflow: StoryWorkflow?,
        finalRenderWorkflow: FinalRenderWorkflow?,
        creditBalanceLoadState: AnimateCreditBalanceLoadState = .loaded,
        template: AnimateVideoTemplate,
        selectedMediaCount: Int
    ) -> AnimateCreateWorkflowCapability {
        AnimateCreateWorkflowCapability(
            canAddMedia: canAddMedia(
                hasAnimateWorkspace: hasAnimateWorkspace,
                isImportingMedia: isImportingMedia,
                mediaRemainingSlots: mediaRemainingSlots
            ),
            canPrepareVideoDirection: canPrepareVideoDirection(
                isSignedIn: isSignedIn,
                hasAnimateWorkspace: hasAnimateWorkspace,
                storyWorkflow: storyWorkflow,
                template: template,
                selectedMediaCount: selectedMediaCount
            ),
            canPrepareFinalRenderPlan: canPrepareFinalRenderPlan(
                activeVideoId: activeVideoId,
                finalRenderWorkflow: finalRenderWorkflow
            ),
            canGenerateFinalRender: canGenerateFinalRender(
                activeVideoId: activeVideoId,
                finalRenderWorkflow: finalRenderWorkflow,
                creditBalanceLoadState: creditBalanceLoadState,
                template: template
            ),
            canRefreshFinalRenderStatus: false
        )
    }

    private static func canAddMedia(
        hasAnimateWorkspace: Bool,
        isImportingMedia: Bool,
        mediaRemainingSlots: Int
    ) -> Bool {
        hasAnimateWorkspace
            && !isImportingMedia
            && mediaRemainingSlots > 0
    }

    private static func canPrepareVideoDirection(
        isSignedIn: Bool,
        hasAnimateWorkspace: Bool,
        storyWorkflow: StoryWorkflow?,
        template: AnimateVideoTemplate,
        selectedMediaCount: Int
    ) -> Bool {
        guard isSignedIn else { return false }
        guard let storyWorkflow, hasAnimateWorkspace else { return false }
        return storyWorkflow.isConfigured
            && !storyWorkflow.isPlanning
            && AnimateMediaRules.availability(template: template, selectedCount: selectedMediaCount).canUseSelection
    }

    private static func canPrepareFinalRenderPlan(
        activeVideoId: String?,
        finalRenderWorkflow: FinalRenderWorkflow?
    ) -> Bool {
        guard let finalRenderWorkflow, activeVideoId != nil else { return false }
        return finalRenderWorkflow.canPreparePlan()
    }

    private static func canGenerateFinalRender(
        activeVideoId: String?,
        finalRenderWorkflow: FinalRenderWorkflow?,
        creditBalanceLoadState: AnimateCreditBalanceLoadState,
        template: AnimateVideoTemplate
    ) -> Bool {
        guard let finalRenderWorkflow, activeVideoId != nil else { return false }
        guard creditBalanceLoadState.hasLoadedBalance else { return false }
        return finalRenderWorkflow.canGenerate(template: template)
    }
}
