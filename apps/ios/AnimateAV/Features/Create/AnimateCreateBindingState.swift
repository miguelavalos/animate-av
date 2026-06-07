import Foundation

struct AnimateCreateAccountState {
    let isSignedIn: Bool
    let balance: AnimateCreditBalance
    let creditBalanceLoadState: AnimateCreditBalanceLoadState
}

struct AnimateCreateMomentCreationState {
    let isCreatingMoment: Bool
    let activeMomentId: String?
    let setupErrorMessage: String?
}

struct AnimateCreateMediaUploadState {
    let selectedMedia: [MomentsSelectedMedia]
    let statusMessage: String?
    let isImporting: Bool
    let importProgress: MomentsMediaImportProgress?
}

struct AnimateCreateStoryState {
    let activeWorkspace: MomentWorkspace?
    let savedScenes: [MomentStoryScene]
    let generatedScenes: [MomentsStorySceneResponse]
    let statusMessage: String?
    let isPlanning: Bool
}

struct AnimateCreateFinalRenderState {
    let finalExport: MomentArtifact?
    let latestFinalJob: MomentRenderJob?
    let renderPlan: MomentsRenderPlanResponse?
    var videoQuote: AnimateVideoQuoteResponse? = nil
    var pendingGalleryVideo: AnimateGalleryVideoRecord? = nil
    var canRetryFinalVideoDownload = false
    let statusMessage: String?
    let isGenerating: Bool
}
