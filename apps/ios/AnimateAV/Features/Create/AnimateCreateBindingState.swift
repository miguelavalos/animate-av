import Foundation

struct AnimateCreateAccountState {
    let isSignedIn: Bool
    let balance: AnimateCreditBalance
    let creditBalanceLoadState: AnimateCreditBalanceLoadState
}

struct AnimateCreateVideoCreationState {
    let isCreatingMoment: Bool
    let activeMomentId: String?
    let setupErrorMessage: String?
}

struct AnimateCreateMediaUploadState {
    let selectedMedia: [AnimateSelectedMedia]
    let statusMessage: String?
    let isImporting: Bool
    let importProgress: AnimateMediaImportProgress?
}

struct AnimateCreateStoryState {
    let activeWorkspace: AnimateWorkspace?
    let savedScenes: [AnimateStoryScene]
    let generatedScenes: [AnimateStorySceneResponse]
    let statusMessage: String?
    let isPlanning: Bool
}

struct AnimateCreateFinalRenderState {
    let finalExport: AnimateArtifact?
    let latestFinalJob: AnimateRenderJob?
    let renderPlan: AnimateRenderPlanResponse?
    var videoQuote: AnimateVideoQuoteResponse? = nil
    var pendingGalleryVideo: AnimateGalleryVideoRecord? = nil
    var canRetryFinalVideoDownload = false
    let statusMessage: String?
    let isGenerating: Bool
}
