import Foundation

@MainActor
final class MomentsDependencyContainer: ObservableObject {
    let accountController: AccountController
    let momentsObserver: InProgressMomentsObserver
    let galleryMomentsObserver: GalleryMomentsObserver
    let workspaceObserver: MomentsWorkspaceObserver
    let momentDeletionWorkflow: MomentDeletionWorkflow
    let momentWorkspaceSelectionWorkflow: MomentWorkspaceSelectionWorkflow
    let inProgressMomentsWorkflow: InProgressMomentsWorkflow
    let momentCreationWorkflow: MomentCreationWorkflow
    let mediaUploadWorkflow: MediaUploadWorkflow
    let storyWorkflow: StoryWorkflow
    let finalRenderWorkflow: FinalRenderWorkflow
    let homeViewModel: MomentsHomeViewModel
    let createViewModel: MomentsCreateViewModel
    let inProgressViewModel: MomentsInProgressViewModel
    let galleryViewModel: MomentsGalleryViewModel
    let aviViewModel: MomentsAviViewModel
    private let realtimeSessionClient: MomentsRealtimeSessionClient
    private let realtimeSessionStore: MomentsRealtimeSessionStore
    private var realtimeSessionTask: Task<Void, Never>?
    private var observedOwnerUserId: ObservedOwnerUserId = .unobserved

    init(
        accountController: AccountController = AccountController(),
        momentsRepository: MomentsRepository = MomentsRepository(),
        momentsObserver: InProgressMomentsObserver? = nil,
        galleryMomentsObserver: GalleryMomentsObserver? = nil,
        workspaceObserver: MomentsWorkspaceObserver? = nil
    ) {
        let clients = MomentsWorkflowClients(baseURLString: AppConfig.animateAPIBaseURL)
        self.accountController = accountController
        let resolvedMomentsObserver = momentsObserver ?? InProgressMomentsObserver(momentsRepository: momentsRepository)
        let resolvedGalleryMomentsObserver = galleryMomentsObserver ?? GalleryMomentsObserver(momentsRepository: momentsRepository)
        let resolvedWorkspaceObserver = workspaceObserver ?? MomentsWorkspaceObserver(momentsRepository: momentsRepository)
        self.momentsObserver = resolvedMomentsObserver
        self.galleryMomentsObserver = resolvedGalleryMomentsObserver
        self.workspaceObserver = resolvedWorkspaceObserver
        let workflows = MomentsWorkflowBundle(
            accountController: accountController,
            momentsRepository: momentsRepository,
            momentsObserver: resolvedMomentsObserver,
            workspaceObserver: resolvedWorkspaceObserver,
            clients: clients
        )
        self.momentDeletionWorkflow = workflows.momentDeletion
        self.momentWorkspaceSelectionWorkflow = workflows.momentWorkspaceSelection
        self.inProgressMomentsWorkflow = workflows.inProgressMoments
        self.momentCreationWorkflow = workflows.momentCreation
        self.mediaUploadWorkflow = workflows.mediaUpload
        self.storyWorkflow = workflows.story
        self.finalRenderWorkflow = workflows.finalRender
        self.realtimeSessionClient = clients.realtimeSession
        self.realtimeSessionStore = .shared
        let viewModels = MomentsViewModelBundle(
            accountController: accountController,
            workflows: workflows,
            galleryMomentsProvider: resolvedGalleryMomentsObserver,
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
        inProgressMomentsWorkflow.observeInProgressMoments(ownerUserId: nil)
        galleryMomentsObserver.observeGalleryMoments(ownerUserId: nil)
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
                self?.inProgressMomentsWorkflow.observeInProgressMoments(ownerUserId: ownerUserId)
                self?.galleryMomentsObserver.observeGalleryMoments(ownerUserId: ownerUserId)
            }
        }
    }

    func applyUITestFixturesIfNeeded() {
        guard MomentsCreateUITestFixtures.isActive else { return }
        createViewModel.applyUITestCreateFixture()
    }
}

private enum ObservedOwnerUserId: Equatable {
    case unobserved
    case observed(String?)
}
