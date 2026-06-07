import Foundation

@MainActor
struct AnimateViewModelBundle {
    let home: AnimateHomeViewModel
    let create: MomentsCreateViewModel
    let inProgress: MomentsInProgressViewModel
    let gallery: MomentsGalleryViewModel
    let avi: MomentsAviViewModel

    init(
        accountController: AccountController,
        workflows: AnimateWorkflowBundle,
        galleryMomentsProvider: any GalleryMomentsListProviding,
        authTokenProvider: any MomentsAuthTokenProviding,
        imageGenerationAccountingClient: MomentsImageGenerationAccountingClient,
        finalRenderClient: MomentsFinalRenderClient
    ) {
        home = AnimateHomeViewModel()
        create = MomentsCreateViewModel()
        inProgress = MomentsInProgressViewModel()
        gallery = MomentsGalleryViewModel(
            galleryMomentsProvider: galleryMomentsProvider,
            authTokenProvider: authTokenProvider,
            finalRenderClient: finalRenderClient
        )
        avi = MomentsAviViewModel()

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
