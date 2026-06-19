import Foundation

@MainActor
struct AnimateWorkflowBundle {
    let videoDeletion: AnimateVideoDeletionWorkflow
    let workspaceSelection: AnimateWorkspaceSelectionWorkflow
    let videosWorkflow: AnimateVideosWorkflow
    let videoCreation: AnimateVideoCreationWorkflow
    let mediaUpload: MediaUploadWorkflow
    let videoDirection: VideoDirectionWorkflow
    let finalRender: FinalRenderWorkflow

    init(
        accountController: AccountController,
        animateRepository: AnimateRepository,
        videosObserver: AnimateInProgressObserver,
        workspaceObserver: AnimateWorkspaceObserver,
        clients: AnimateWorkflowClients
    ) {
        videoDeletion = AnimateVideoDeletionWorkflow(
            currentUserProvider: accountController,
            authTokenProvider: accountController,
            videoDeleter: clients.workspaceCommands
        )
        workspaceSelection = AnimateWorkspaceSelectionWorkflow(workspaceObserver: workspaceObserver)
        videosWorkflow = AnimateVideosWorkflow(
            videosObserver: videosObserver,
            workspaceSelectionWorkflow: workspaceSelection,
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
        videoDirection = VideoDirectionWorkflow(
            currentUserProvider: accountController,
            authTokenProvider: accountController,
            workspaceObserver: workspaceObserver,
            videoDirectionClient: clients.videoDirection
        )
        finalRender = FinalRenderWorkflow(
            currentUserProvider: accountController,
            authTokenProvider: accountController,
            creditBalanceProvider: accountController,
            workspaceObserver: workspaceObserver,
            finalRenderClient: clients.finalRender,
            videoQuoteClient: clients.videoQuote,
            uploadClient: clients.upload
        )
    }
}

struct AnimateWorkflowClients {
    let workspaceCommands: AnimateWorkspaceCommandClient
    let realtimeSession: AnimateRealtimeSessionClient
    let upload: AnimateUploadClient
    let videoDirection: AnimateVideoDirectionClient
    let videoQuote: AnimateVideoQuoteClient
    let imageGenerationAccounting: AnimateImageGenerationAccountingClient
    let finalRender: AnimateFinalRenderClient

    init(baseURLString: String) {
        workspaceCommands = AnimateWorkspaceCommandClient(baseURLString: baseURLString)
        realtimeSession = AnimateRealtimeSessionClient(baseURLString: baseURLString)
        upload = AnimateUploadClient(baseURLString: baseURLString, session: Self.makeUploadSession())
        videoDirection = AnimateVideoDirectionClient(baseURLString: baseURLString)
        videoQuote = AnimateVideoQuoteClient(baseURLString: baseURLString)
        imageGenerationAccounting = AnimateImageGenerationAccountingClient(baseURLString: baseURLString)
        finalRender = AnimateFinalRenderClient(baseURLString: baseURLString, session: Self.makeFinalRenderSession())
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

    private static func makeFinalRenderSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpMaximumConnectionsPerHost = 3
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 120
        configuration.waitsForConnectivity = false
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return URLSession(configuration: configuration)
    }
}
