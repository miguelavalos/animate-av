import Foundation

struct AnimateCreateWorkflowAvailability: Equatable {
    var canAddMedia = false
    var canPrepareVideoDirection = false
    var canPrepareFinalRenderPlan = false
    var canGenerateFinalRender = false
    var canRefreshFinalRenderStatus = false
    var mediaMessage: String?
    var videoDirectionMessage: String?
    var finalRenderMessage: String?

    static func make(
        canAddMedia: Bool,
        canPrepareVideoDirection: Bool,
        canPrepareFinalRenderPlan: Bool,
        canGenerateFinalRender: Bool,
        canRefreshFinalRenderStatus: Bool,
        mediaMessage: String?,
        videoDirectionMessage: String?,
        finalRenderMessage: String?
    ) -> AnimateCreateWorkflowAvailability {
        AnimateCreateWorkflowAvailability(
            canAddMedia: canAddMedia,
            canPrepareVideoDirection: canPrepareVideoDirection,
            canPrepareFinalRenderPlan: canPrepareFinalRenderPlan,
            canGenerateFinalRender: canGenerateFinalRender,
            canRefreshFinalRenderStatus: canRefreshFinalRenderStatus,
            mediaMessage: mediaMessage,
            videoDirectionMessage: videoDirectionMessage,
            finalRenderMessage: finalRenderMessage
        )
    }
}
