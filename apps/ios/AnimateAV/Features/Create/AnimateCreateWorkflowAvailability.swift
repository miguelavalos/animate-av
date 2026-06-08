import Foundation

struct AnimateCreateWorkflowAvailability: Equatable {
    var canAddMedia = false
    var canPrepareVideoDirection = false
    var canPrepareFinalRenderPlan = false
    var canGenerateFinalRender = false
    var canRefreshFinalRenderStatus = false
    var mediaMessage: String?
    var storyMessage: String?
    var finalRenderMessage: String?

    static func make(
        canAddMedia: Bool,
        canPrepareVideoDirection: Bool,
        canPrepareFinalRenderPlan: Bool,
        canGenerateFinalRender: Bool,
        canRefreshFinalRenderStatus: Bool,
        mediaMessage: String?,
        storyMessage: String?,
        finalRenderMessage: String?
    ) -> AnimateCreateWorkflowAvailability {
        AnimateCreateWorkflowAvailability(
            canAddMedia: canAddMedia,
            canPrepareVideoDirection: canPrepareVideoDirection,
            canPrepareFinalRenderPlan: canPrepareFinalRenderPlan,
            canGenerateFinalRender: canGenerateFinalRender,
            canRefreshFinalRenderStatus: canRefreshFinalRenderStatus,
            mediaMessage: mediaMessage,
            storyMessage: storyMessage,
            finalRenderMessage: finalRenderMessage
        )
    }
}
