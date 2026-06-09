import Combine
import Foundation

@MainActor
final class AnimateVideosWorkflow: ObservableObject {
    @Published private(set) var videosSummary = AnimateInProgressSummary()
    @Published private(set) var isDeletingVideo = false
    @Published private(set) var errorMessage: String?

    private let videosObserver: any AnimateInProgressListProviding
    private let workspaceSelectionWorkflow: AnimateWorkspaceSelectionWorkflow
    private let videoDeletionWorkflow: AnimateVideoDeletionWorkflow
    private let videoTitleUpdater: any AnimateVideoTitleUpdating
    private let currentUserProvider: any AnimateCurrentUserProviding
    private let authTokenProvider: any AnimateAuthTokenProviding
    private var currentOwnerUserId: String?
    private var optimisticVideoTitles: [String: String] = [:]
    private var cancellables = Set<AnyCancellable>()

    init(
        videosObserver: any AnimateInProgressListProviding,
        workspaceSelectionWorkflow: AnimateWorkspaceSelectionWorkflow,
        videoDeletionWorkflow: AnimateVideoDeletionWorkflow,
        videoTitleUpdater: any AnimateVideoTitleUpdating,
        currentUserProvider: any AnimateCurrentUserProviding,
        authTokenProvider: any AnimateAuthTokenProviding
    ) {
        self.videosObserver = videosObserver
        self.workspaceSelectionWorkflow = workspaceSelectionWorkflow
        self.videoDeletionWorkflow = videoDeletionWorkflow
        self.videoTitleUpdater = videoTitleUpdater
        self.currentUserProvider = currentUserProvider
        self.authTokenProvider = authTokenProvider

        videosObserver.videosPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] videos in
                self?.apply(videos)
            }
            .store(in: &cancellables)

        videosObserver.videosErrorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.applyVideoListError(message)
            }
            .store(in: &cancellables)

        videoDeletionWorkflow.isDeletingVideoPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDeleting in
                self?.isDeletingVideo = isDeleting
            }
            .store(in: &cancellables)

        videoDeletionWorkflow.deletionErrorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.applyVideoDeletionError(message)
            }
            .store(in: &cancellables)

        workspaceSelectionWorkflow.workspaceErrorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.applyWorkspaceError(message)
            }
            .store(in: &cancellables)
    }

    func observeAnimateVideos(ownerUserId: String?) {
        currentOwnerUserId = ownerUserId
        videosSummary = AnimateInProgressSummary()
        errorMessage = nil
        clearActiveVideo()
        videosObserver.observeAnimateVideos(ownerUserId: ownerUserId)
    }

    func observeAnimateWorkspace(ownerUserId: String?, videoId: String?) {
        errorMessage = nil
        workspaceSelectionWorkflow.observeAnimateWorkspace(ownerUserId: ownerUserId, videoId: videoId)
    }

    private func applyWorkspaceError(_ message: String?) {
        guard let message else { return }
        errorMessage = message
    }

    func clearAnimateWorkspace() {
        clearActiveVideo()
    }

    func renameVideo(_ video: AnimateVideo, title: String) async -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return false }
        let previousTitle = optimisticVideoTitles[video.id]
        optimisticVideoTitles[video.id] = trimmedTitle
        applyOptimisticTitle(videoId: video.id, title: trimmedTitle)

        do {
            guard currentUserProvider.currentUserId != nil else {
                restoreOptimisticTitle(videoId: video.id, previousTitle: previousTitle)
                errorMessage = L10n.string("inProgress.rename.failed")
                return false
            }
            guard let bearerToken = try? await authTokenProvider.currentBearerToken() else {
                restoreOptimisticTitle(videoId: video.id, previousTitle: previousTitle)
                errorMessage = L10n.string("inProgress.rename.failed")
                return false
            }
            try await videoTitleUpdater.updateVideoTitle(
                bearerToken: bearerToken,
                videoId: video.id,
                title: trimmedTitle
            )
            errorMessage = nil
            return true
        } catch {
            restoreOptimisticTitle(videoId: video.id, previousTitle: previousTitle)
            errorMessage = L10n.string("inProgress.rename.failed")
            return false
        }
    }

    func deleteVideo(_ video: AnimateVideo) async -> Bool {
        errorMessage = nil
        let didDelete = await videoDeletionWorkflow.deleteVideo(video)
        guard didDelete else { return false }

        if workspaceSelectionWorkflow.activeVideo?.id == video.id {
            clearActiveVideo()
        }
        observeAnimateVideos(ownerUserId: currentOwnerUserId)
        return true
    }

    private func apply(_ videos: [AnimateVideo]) {
        let renamedVideos = videos.map { video in
            guard let title = optimisticVideoTitles[video.id] else { return video }
            if video.title == title {
                optimisticVideoTitles[video.id] = nil
                return video
            }
            return video.renamed(title)
        }
        videosSummary = AnimateInProgressSummary.make(from: renamedVideos)
    }

    private func applyOptimisticTitle(videoId: String, title: String) {
        let videos = videosSummary.videos.map { video in
            video.id == videoId ? video.renamed(title) : video
        }
        videosSummary = AnimateInProgressSummary.make(from: videos)
    }

    private func restoreOptimisticTitle(videoId: String, previousTitle: String?) {
        if let previousTitle {
            optimisticVideoTitles[videoId] = previousTitle
            applyOptimisticTitle(videoId: videoId, title: previousTitle)
            return
        }

        optimisticVideoTitles[videoId] = nil
    }

    private func applyVideoListError(_ message: String?) {
        guard let message else { return }
        errorMessage = message
    }

    private func applyVideoDeletionError(_ message: String?) {
        guard let message else { return }
        errorMessage = message
    }

    private func clearActiveVideo() {
        workspaceSelectionWorkflow.clearAnimateWorkspace()
    }

}

extension AnimateVideosWorkflow: AnimateVideosViewing {
    var inProgressSummaryPublisher: AnyPublisher<AnimateInProgressSummary, Never> {
        $videosSummary.eraseToAnyPublisher()
    }

    var activeVideoPublisher: AnyPublisher<AnimateVideo?, Never> {
        workspaceSelectionWorkflow.activeVideoPublisher
    }

    var activeWorkspacePublisher: AnyPublisher<AnimateWorkspace?, Never> {
        workspaceSelectionWorkflow.activeWorkspacePublisher
    }

    var isLoadingAnimateWorkspacePublisher: AnyPublisher<Bool, Never> {
        workspaceSelectionWorkflow.isLoadingAnimateWorkspacePublisher
    }

    var isDeletingVideoPublisher: AnyPublisher<Bool, Never> {
        $isDeletingVideo.eraseToAnyPublisher()
    }

    var inProgressErrorMessagePublisher: AnyPublisher<String?, Never> {
        $errorMessage.eraseToAnyPublisher()
    }
}
