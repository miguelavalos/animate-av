import Foundation

@MainActor
struct MomentsWorkflowBundle {
    let momentDeletion: MomentDeletionWorkflow
    let momentWorkspaceSelection: MomentWorkspaceSelectionWorkflow
    let inProgressMoments: InProgressMomentsWorkflow
    let momentCreation: MomentCreationWorkflow
    let mediaUpload: MediaUploadWorkflow
    let story: StoryWorkflow
    let finalRender: FinalRenderWorkflow

    init(
        accountController: AccountController,
        momentsRepository: MomentsRepository,
        momentsObserver: InProgressMomentsObserver,
        workspaceObserver: MomentsWorkspaceObserver,
        clients: MomentsWorkflowClients
    ) {
        momentDeletion = MomentDeletionWorkflow(
            currentUserProvider: accountController,
            authTokenProvider: accountController,
            momentDeleter: clients.workspaceCommands
        )
        momentWorkspaceSelection = MomentWorkspaceSelectionWorkflow(workspaceObserver: workspaceObserver)
        inProgressMoments = InProgressMomentsWorkflow(
            momentsObserver: momentsObserver,
            workspaceSelectionWorkflow: momentWorkspaceSelection,
            momentDeletionWorkflow: momentDeletion,
            momentTitleUpdater: clients.workspaceCommands,
            currentUserProvider: accountController,
            authTokenProvider: accountController
        )
        momentCreation = MomentCreationWorkflow(
            currentUserProvider: accountController,
            authTokenProvider: accountController,
            creditBalanceProvider: accountController,
            momentCreator: clients.workspaceCommands,
            momentDeleter: clients.workspaceCommands,
            workspaceObserver: workspaceObserver
        )
        mediaUpload = MediaUploadWorkflow(
            currentUserProvider: accountController,
            authTokenProvider: accountController,
            workspaceObserver: workspaceObserver,
            uploadClient: clients.upload
        )
        story = StoryWorkflow(
            currentUserProvider: accountController,
            authTokenProvider: accountController,
            workspaceObserver: workspaceObserver,
            storyClient: clients.story
        )
        finalRender = FinalRenderWorkflow(
            currentUserProvider: accountController,
            authTokenProvider: accountController,
            creditBalanceProvider: accountController,
            workspaceObserver: workspaceObserver,
            finalRenderClient: clients.finalRender
        )
    }
}

struct MomentsWorkflowClients {
    let workspaceCommands: MomentsWorkspaceCommandClient
    let realtimeSession: MomentsRealtimeSessionClient
    let upload: MomentsUploadClient
    let story: MomentsStoryClient
    let videoQuote: MomentsVideoQuoteClient
    let finalRender: MomentsFinalRenderClient

    init(baseURLString: String) {
        workspaceCommands = MomentsWorkspaceCommandClient(baseURLString: baseURLString)
        realtimeSession = MomentsRealtimeSessionClient(baseURLString: baseURLString)
        upload = MomentsUploadClient(baseURLString: baseURLString, session: Self.makeUploadSession())
        story = MomentsStoryClient(baseURLString: baseURLString)
        videoQuote = MomentsVideoQuoteClient(baseURLString: baseURLString)
        finalRender = MomentsFinalRenderClient(baseURLString: baseURLString)
    }

    private static func makeUploadSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpMaximumConnectionsPerHost = 3
        configuration.timeoutIntervalForRequest = 45
        configuration.timeoutIntervalForResource = 90
        configuration.waitsForConnectivity = false
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: configuration)
    }
}
