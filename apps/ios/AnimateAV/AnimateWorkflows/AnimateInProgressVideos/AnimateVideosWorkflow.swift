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
    private var optimisticMomentTitles: [String: String] = [:]
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

        videosObserver.momentsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] moments in
                self?.apply(moments)
            }
            .store(in: &cancellables)

        videosObserver.momentsErrorPublisher
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

    func observeAnimateWorkspace(ownerUserId: String?, momentId: String?) {
        errorMessage = nil
        workspaceSelectionWorkflow.observeAnimateWorkspace(ownerUserId: ownerUserId, momentId: momentId)
    }

    private func applyWorkspaceError(_ message: String?) {
        guard let message else { return }
        errorMessage = message
    }

    func clearAnimateWorkspace() {
        clearActiveVideo()
    }

    func renameVideo(_ moment: AnimateVideo, title: String) async -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return false }
        let previousTitle = optimisticMomentTitles[moment.id]
        optimisticMomentTitles[moment.id] = trimmedTitle
        applyOptimisticTitle(momentId: moment.id, title: trimmedTitle)

        do {
            guard currentUserProvider.currentUserId != nil else {
                restoreOptimisticTitle(momentId: moment.id, previousTitle: previousTitle)
                errorMessage = L10n.string("inProgress.rename.failed")
                return false
            }
            guard let bearerToken = try? await authTokenProvider.currentBearerToken() else {
                restoreOptimisticTitle(momentId: moment.id, previousTitle: previousTitle)
                errorMessage = L10n.string("inProgress.rename.failed")
                return false
            }
            try await videoTitleUpdater.updateMomentTitle(
                bearerToken: bearerToken,
                momentId: moment.id,
                title: trimmedTitle
            )
            errorMessage = nil
            return true
        } catch {
            restoreOptimisticTitle(momentId: moment.id, previousTitle: previousTitle)
            errorMessage = L10n.string("inProgress.rename.failed")
            return false
        }
    }

    func deleteVideo(_ moment: AnimateVideo) async -> Bool {
        errorMessage = nil
        let didDelete = await videoDeletionWorkflow.deleteVideo(moment)
        guard didDelete else { return false }

        if workspaceSelectionWorkflow.activeMoment?.id == moment.id {
            clearActiveVideo()
        }
        observeAnimateVideos(ownerUserId: currentOwnerUserId)
        return true
    }

    private func apply(_ moments: [AnimateVideo]) {
        let renamedMoments = moments.map { moment in
            guard let title = optimisticMomentTitles[moment.id] else { return moment }
            if moment.title == title {
                optimisticMomentTitles[moment.id] = nil
                return moment
            }
            return moment.renamed(title)
        }
        videosSummary = AnimateInProgressSummary.make(from: renamedMoments)
    }

    private func applyOptimisticTitle(momentId: String, title: String) {
        let moments = videosSummary.moments.map { moment in
            moment.id == momentId ? moment.renamed(title) : moment
        }
        videosSummary = AnimateInProgressSummary.make(from: moments)
    }

    private func restoreOptimisticTitle(momentId: String, previousTitle: String?) {
        if let previousTitle {
            optimisticMomentTitles[momentId] = previousTitle
            applyOptimisticTitle(momentId: momentId, title: previousTitle)
            return
        }

        optimisticMomentTitles[momentId] = nil
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
