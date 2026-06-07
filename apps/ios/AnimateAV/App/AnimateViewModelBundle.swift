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
        galleryMomentsProvider: any GalleryMomentsListProviding,
        authTokenProvider: any AnimateAuthTokenProviding,
        imageGenerationAccountingClient: MomentsImageGenerationAccountingClient,
        finalRenderClient: MomentsFinalRenderClient
    ) {
        home = AnimateHomeViewModel()
        create = AnimateCreateViewModel()
        inProgress = AnimateInProgressViewModel()
        gallery = AnimateGalleryViewModel(
            galleryMomentsProvider: galleryMomentsProvider,
            authTokenProvider: authTokenProvider,
            finalRenderClient: finalRenderClient
        )
        avi = AnimateAviViewModel()

        home.bind(to: workflows.inProgressMoments)
        home.bind(accountStateProvider: accountController)
        create.bind(
            accountStateProvider: accountController,
            momentCreationWorkflow: workflows.momentCreation,
            mediaUploadWorkflow: workflows.mediaUpload,
            storyWorkflow: workflows.story,
            finalRenderWorkflow: workflows.finalRender,
            authTokenProvider: authTokenProvider,
            imageGenerationAccountingClient: imageGenerationAccountingClient
        )
        inProgress.bind(to: workflows.inProgressMoments)
        inProgress.bind(accountStateProvider: accountController)
        avi.bind(to: workflows.inProgressMoments)
        avi.bind(accountStateProvider: accountController)
    }
}
