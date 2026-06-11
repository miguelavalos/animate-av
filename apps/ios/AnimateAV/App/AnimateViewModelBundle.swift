import Foundation

@MainActor
struct AnimateViewModelBundle {
    let home: AnimateHomeViewModel
    let create: AnimateCreateViewModel
    let inProgress: AnimateInProgressViewModel
    let gallery: AnimateGalleryViewModel
    let avi: AnimateAviViewModel

    init(
        accountController: AccountController,
        workflows: AnimateWorkflowBundle,
        galleryArtifactsProvider: any AnimateGalleryListProviding,
        authTokenProvider: any AnimateAuthTokenProviding,
        imageGenerationAccountingClient: AnimateImageGenerationAccountingClient,
        finalRenderClient: AnimateFinalRenderClient
    ) {
        home = AnimateHomeViewModel()
        create = AnimateCreateViewModel()
        inProgress = AnimateInProgressViewModel()
        gallery = AnimateGalleryViewModel(
            galleryArtifactsProvider: galleryArtifactsProvider,
            authTokenProvider: authTokenProvider,
            finalRenderClient: finalRenderClient
        )
        avi = AnimateAviViewModel()

        home.bind(to: workflows.videosWorkflow)
        home.bind(accountStateProvider: accountController)
        create.bind(
            accountStateProvider: accountController,
            videoCreationWorkflow: workflows.videoCreation,
            mediaUploadWorkflow: workflows.mediaUpload,
            videoDirectionWorkflow: workflows.videoDirection,
            finalRenderWorkflow: workflows.finalRender,
            authTokenProvider: authTokenProvider,
            imageGenerationAccountingClient: imageGenerationAccountingClient
        )
        inProgress.bind(to: workflows.videosWorkflow)
        inProgress.bind(accountStateProvider: accountController)
        gallery.bind(accountStateProvider: accountController)
        avi.bind(to: workflows.videosWorkflow)
        avi.bind(accountStateProvider: accountController)
    }
}
