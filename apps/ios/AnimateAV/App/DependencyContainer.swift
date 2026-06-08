import Foundation

@MainActor
final class AnimateDependencyContainer: ObservableObject {
    let accountController: AccountController
    let videosObserver: AnimateInProgressObserver
    let galleryObserver: AnimateGalleryObserver
    let workspaceObserver: AnimateWorkspaceObserver
    let videoDeletionWorkflow: AnimateVideoDeletionWorkflow
    let workspaceSelectionWorkflow: AnimateWorkspaceSelectionWorkflow
    let videosWorkflow: AnimateVideosWorkflow
    let videoCreationWorkflow: AnimateVideoCreationWorkflow
    let mediaUploadWorkflow: MediaUploadWorkflow
    let storyWorkflow: StoryWorkflow
    let finalRenderWorkflow: FinalRenderWorkflow
    let homeViewModel: AnimateHomeViewModel
    let createViewModel: AnimateCreateViewModel
    let inProgressViewModel: AnimateInProgressViewModel
    let galleryViewModel: AnimateGalleryViewModel
    let aviViewModel: AnimateAviViewModel
    private let realtimeSessionClient: AnimateRealtimeSessionClient
    private let realtimeSessionStore: AnimateRealtimeSessionStore
    private var realtimeSessionTask: Task<Void, Never>?
    private var observedOwnerUserId: ObservedOwnerUserId = .unobserved

    init(
        accountController: AccountController = AccountController(),
        animateRepository: AnimateRepository = AnimateRepository(),
        videosObserver: AnimateInProgressObserver? = nil,
        galleryObserver: AnimateGalleryObserver? = nil,
        workspaceObserver: AnimateWorkspaceObserver? = nil
    ) {
        let clients = AnimateWorkflowClients(baseURLString: AppConfig.animateAPIBaseURL)
        self.accountController = accountController
        let resolvedVideosObserver = videosObserver ?? AnimateInProgressObserver(animateRepository: animateRepository)
        let resolvedGalleryObserver = galleryObserver ?? AnimateGalleryObserver(animateRepository: animateRepository)
        let resolvedWorkspaceObserver = workspaceObserver ?? AnimateWorkspaceObserver(animateRepository: animateRepository)
        self.videosObserver = resolvedVideosObserver
        self.galleryObserver = resolvedGalleryObserver
        self.workspaceObserver = resolvedWorkspaceObserver
        let workflows = AnimateWorkflowBundle(
            accountController: accountController,
            animateRepository: animateRepository,
            videosObserver: resolvedVideosObserver,
            workspaceObserver: resolvedWorkspaceObserver,
            clients: clients
        )
        self.videoDeletionWorkflow = workflows.videoDeletion
        self.workspaceSelectionWorkflow = workflows.workspaceSelection
        self.videosWorkflow = workflows.videosWorkflow
        self.videoCreationWorkflow = workflows.videoCreation
        self.mediaUploadWorkflow = workflows.mediaUpload
        self.storyWorkflow = workflows.story
        self.finalRenderWorkflow = workflows.finalRender
        self.realtimeSessionClient = clients.realtimeSession
        self.realtimeSessionStore = .shared
        let viewModels = AnimateViewModelBundle(
            accountController: accountController,
            workflows: workflows,
            galleryArtifactsProvider: resolvedGalleryObserver,
            authTokenProvider: accountController,
            imageGenerationAccountingClient: clients.imageGenerationAccounting,
            finalRenderClient: clients.finalRender
        )
        self.homeViewModel = viewModels.home
        self.createViewModel = viewModels.create
        self.inProgressViewModel = viewModels.inProgress
        self.galleryViewModel = viewModels.gallery
        self.aviViewModel = viewModels.avi
    }

    func handleAccountChange(ownerUserId: String?) {
        let nextObservedOwnerUserId = ObservedOwnerUserId.observed(ownerUserId)
        guard observedOwnerUserId != nextObservedOwnerUserId else { return }
        observedOwnerUserId = nextObservedOwnerUserId
        realtimeSessionTask?.cancel()
        realtimeSessionStore.clear()
        videosWorkflow.observeAnimateVideos(ownerUserId: nil)
        galleryObserver.observeGalleryArtifacts(ownerUserId: nil)
        inProgressViewModel.clearSelection()
        createViewModel.clearSessionState()
        applyUITestFixturesIfNeeded()
        guard let ownerUserId else { return }

        realtimeSessionTask = Task { [weak self, accountController, realtimeSessionClient] in
            guard let bearerToken = try? await accountController.currentBearerToken(),
                  let realtimeSessionId = try? await realtimeSessionClient.createRealtimeSession(bearerToken: bearerToken)
            else { return }

            await MainActor.run {
                guard self?.observedOwnerUserId == .observed(ownerUserId) else { return }
                self?.realtimeSessionStore.update(ownerUserId: ownerUserId, realtimeSessionId: realtimeSessionId)
                self?.videosWorkflow.observeAnimateVideos(ownerUserId: ownerUserId)
                self?.galleryObserver.observeGalleryArtifacts(ownerUserId: ownerUserId)
            }
        }
    }

    func applyUITestFixturesIfNeeded() {
        guard AnimateCreateUITestFixtures.isActive else { return }
        createViewModel.applyUITestCreateFixture()
    }
}

private enum ObservedOwnerUserId: Equatable {
    case unobserved
    case observed(String?)
}
