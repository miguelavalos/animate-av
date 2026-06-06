import Foundation

struct MomentsCreateAccountState {
    let isSignedIn: Bool
    let balance: MomentsCreditBalance
    let creditBalanceLoadState: MomentsCreditBalanceLoadState
}

struct MomentsCreateMomentCreationState {
    let isCreatingMoment: Bool
    let activeMomentId: String?
    let setupErrorMessage: String?
}

struct MomentsCreateMediaUploadState {
    let selectedMedia: [MomentsSelectedMedia]
    let statusMessage: String?
    let isImporting: Bool
    let importProgress: MomentsMediaImportProgress?
}

struct MomentsCreateStoryState {
    let activeWorkspace: MomentWorkspace?
    let savedScenes: [MomentStoryScene]
    let generatedScenes: [MomentsStorySceneResponse]
    let statusMessage: String?
    let isPlanning: Bool
}

struct MomentsCreateFinalRenderState {
    let finalExport: MomentArtifact?
    let latestFinalJob: MomentRenderJob?
    let renderPlan: MomentsRenderPlanResponse?
    var pendingGalleryVideo: MomentsGalleryVideoRecord? = nil
    var canRetryFinalVideoDownload = false
    let statusMessage: String?
    let isGenerating: Bool
}
