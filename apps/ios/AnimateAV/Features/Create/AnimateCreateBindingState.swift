import Foundation

struct AnimateCreateAccountState {
    let isSignedIn: Bool
    let balance: AnimateCreditBalance
    let creditBalanceLoadState: AnimateCreditBalanceLoadState
}

struct AnimateCreateVideoCreationState {
    let isCreatingVideo: Bool
    let activeVideoId: String?
    let setupErrorMessage: String?
}

struct AnimateCreateMediaUploadState {
    let selectedMedia: [AnimateSelectedMedia]
    let statusMessage: String?
    let isImporting: Bool
    let importProgress: AnimateMediaImportProgress?
}

struct AnimateCreateVideoDirectionState {
    let activeWorkspace: AnimateWorkspace?
    let savedScenes: [AnimateVideoDirectionScene]
    let generatedScenes: [AnimateVideoDirectionSceneResponse]
    let statusMessage: String?
    let isPlanning: Bool
}

struct AnimateCreateFinalRenderState {
    let finalExport: AnimateArtifact?
    let latestFinalJob: AnimateRenderJob?
    let renderPlan: AnimateRenderPlanResponse?
    var videoQuote: AnimateVideoQuoteResponse? = nil
    var pendingGalleryVideo: AnimateGalleryVideoRecord? = nil
    var pendingGalleryImage: AnimateGalleryImageRecord? = nil
    var canRetryFinalVideoDownload = false
    var isSavingFinalVideo = false
    let statusMessage: String?
    let isGenerating: Bool
}
