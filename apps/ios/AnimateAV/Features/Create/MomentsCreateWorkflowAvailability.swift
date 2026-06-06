import Foundation

struct MomentsCreateWorkflowAvailability: Equatable {
    var canAddMedia = false
    var canPlanStory = false
    var canPrepareFinalRenderPlan = false
    var canGenerateFinalRender = false
    var canRefreshFinalRenderStatus = false
    var mediaMessage: String?
    var storyMessage: String?
    var finalRenderMessage: String?

    static func make(
        canAddMedia: Bool,
        canPlanStory: Bool,
        canPrepareFinalRenderPlan: Bool,
        canGenerateFinalRender: Bool,
        canRefreshFinalRenderStatus: Bool,
        mediaMessage: String?,
        storyMessage: String?,
        finalRenderMessage: String?
    ) -> MomentsCreateWorkflowAvailability {
        MomentsCreateWorkflowAvailability(
            canAddMedia: canAddMedia,
            canPlanStory: canPlanStory,
            canPrepareFinalRenderPlan: canPrepareFinalRenderPlan,
            canGenerateFinalRender: canGenerateFinalRender,
            canRefreshFinalRenderStatus: canRefreshFinalRenderStatus,
            mediaMessage: mediaMessage,
            storyMessage: storyMessage,
            finalRenderMessage: finalRenderMessage
        )
    }
}
