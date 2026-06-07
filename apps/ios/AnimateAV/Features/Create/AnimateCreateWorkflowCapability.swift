import Foundation

@MainActor
enum AnimateCreateWorkflowCapabilityFactory {
    static func make(
        activeMomentId: String?,
        isSignedIn: Bool,
        hasMomentWorkspace: Bool,
        isImportingMedia: Bool,
        mediaRemainingSlots: Int,
        storyWorkflow: StoryWorkflow?,
        finalRenderWorkflow: FinalRenderWorkflow?,
        creditBalanceLoadState: AnimateCreditBalanceLoadState = .loaded,
        template: MomentTemplate,
        selectedMediaCount: Int
    ) -> AnimateCreateWorkflowCapability {
        AnimateCreateWorkflowCapability(
            canAddMedia: canAddMedia(
                hasMomentWorkspace: hasMomentWorkspace,
                isImportingMedia: isImportingMedia,
                mediaRemainingSlots: mediaRemainingSlots
            ),
            canPlanStory: canPlanStory(
                isSignedIn: isSignedIn,
                hasMomentWorkspace: hasMomentWorkspace,
                storyWorkflow: storyWorkflow,
                template: template,
                selectedMediaCount: selectedMediaCount
            ),
            canPrepareFinalRenderPlan: canPrepareFinalRenderPlan(
                activeMomentId: activeMomentId,
                finalRenderWorkflow: finalRenderWorkflow
            ),
            canGenerateFinalRender: canGenerateFinalRender(
                activeMomentId: activeMomentId,
                finalRenderWorkflow: finalRenderWorkflow,
                creditBalanceLoadState: creditBalanceLoadState,
                template: template
            ),
            canRefreshFinalRenderStatus: false
        )
    }

    private static func canAddMedia(
        hasMomentWorkspace: Bool,
        isImportingMedia: Bool,
        mediaRemainingSlots: Int
    ) -> Bool {
        hasMomentWorkspace
            && !isImportingMedia
            && mediaRemainingSlots > 0
    }

    private static func canPlanStory(
        isSignedIn: Bool,
        hasMomentWorkspace: Bool,
        storyWorkflow: StoryWorkflow?,
        template: MomentTemplate,
        selectedMediaCount: Int
    ) -> Bool {
        guard isSignedIn else { return false }
        guard let storyWorkflow, hasMomentWorkspace else { return false }
        return storyWorkflow.isConfigured
            && !storyWorkflow.isPlanning
            && MomentsMediaRules.availability(template: template, selectedCount: selectedMediaCount).canUseSelection
    }

    private static func canPrepareFinalRenderPlan(
        activeMomentId: String?,
        finalRenderWorkflow: FinalRenderWorkflow?
    ) -> Bool {
        guard let finalRenderWorkflow, activeMomentId != nil else { return false }
        return finalRenderWorkflow.canPreparePlan()
    }

    private static func canGenerateFinalRender(
        activeMomentId: String?,
        finalRenderWorkflow: FinalRenderWorkflow?,
        creditBalanceLoadState: AnimateCreditBalanceLoadState,
        template: MomentTemplate
    ) -> Bool {
        guard let finalRenderWorkflow, activeMomentId != nil else { return false }
        guard creditBalanceLoadState.hasLoadedBalance else { return false }
        return finalRenderWorkflow.canGenerate(template: template)
    }
}
