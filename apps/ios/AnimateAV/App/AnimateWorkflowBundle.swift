import Foundation

@MainActor
struct AnimateWorkflowBundle {
    let videoDeletion: AnimateVideoDeletionWorkflow
    let momentWorkspaceSelection: AnimateWorkspaceSelectionWorkflow
    let inProgressMoments: AnimateVideosWorkflow
    let videoCreation: AnimateVideoCreationWorkflow
    let mediaUpload: MediaUploadWorkflow
    let story: StoryWorkflow
    let finalRender: FinalRenderWorkflow

    init(
        accountController: AccountController,
        momentsRepository: AnimateRepository,
        videosObserver: AnimateInProgressObserver,
        workspaceObserver: AnimateWorkspaceObserver,
        clients: MomentsWorkflowClients
    ) {
        videoDeletion = AnimateVideoDeletionWorkflow(
            currentUserProvider: accountController,
            authTokenProvider: accountController,
            videoDeleter: clients.workspaceCommands
        )
        momentWorkspaceSelection = AnimateWorkspaceSelectionWorkflow(workspaceObserver: workspaceObserver)
        inProgressMoments = AnimateVideosWorkflow(
            videosObserver: videosObserver,
            workspaceSelectionWorkflow: momentWorkspaceSelection,
            videoDeletionWorkflow: videoDeletion,
            videoTitleUpdater: clients.workspaceCommands,
            currentUserProvider: accountController,
            authTokenProvider: accountController
        )
        videoCreation = AnimateVideoCreationWorkflow(
            currentUserProvider: accountController,
            authTokenProvider: accountController,
            creditBalanceProvider: accountController,
            videoCreator: clients.workspaceCommands,
            videoDeleter: clients.workspaceCommands,
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
            finalRenderClient: clients.finalRender,
            videoQuoteClient: clients.videoQuote,
            imageGenerationAccountingClient: clients.imageGenerationAccounting
        )
    }
}

struct MomentsWorkflowClients {
    let workspaceCommands: AnimateWorkspaceCommandClient
    let realtimeSession: AnimateRealtimeSessionClient
    let upload: AnimateUploadClient
    let story: AnimateStoryClient
    let videoQuote: AnimateVideoQuoteClient
    let imageGenerationAccounting: AnimateImageGenerationAccountingClient
    let finalRender: AnimateFinalRenderClient

    init(baseURLString: String) {
        workspaceCommands = AnimateWorkspaceCommandClient(baseURLString: baseURLString)
        realtimeSession = AnimateRealtimeSessionClient(baseURLString: baseURLString)
        upload = AnimateUploadClient(baseURLString: baseURLString, session: Self.makeUploadSession())
        story = AnimateStoryClient(baseURLString: baseURLString)
        videoQuote = AnimateVideoQuoteClient(baseURLString: baseURLString)
        imageGenerationAccounting = AnimateImageGenerationAccountingClient(baseURLString: baseURLString)
        finalRender = AnimateFinalRenderClient(baseURLString: baseURLString)
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
