import Combine
import Foundation
import SwiftUI

@MainActor
final class AnimateInProgressViewModel: ObservableObject {
    @Published private(set) var allVideosSummary = AnimateInProgressSummary()
    @Published private(set) var isSignedIn = false
    @Published private(set) var currentUserId: String?
    @Published private(set) var activeVideo: AnimateVideo?
    @Published private(set) var activeWorkspace: AnimateWorkspace?
    @Published private(set) var selectedVideoId: String?
    @Published private(set) var isLoadingAnimateWorkspace = false
    @Published private(set) var isDeletingVideo = false
    @Published private(set) var statusMessage: String?

    var videosSummary: AnimateInProgressSummary {
        allVideosSummary.videoSummary
    }

    var imagesSummary: AnimateInProgressSummary {
        allVideosSummary.imageSummary
    }

    private var workflow: (any AnimateVideosViewing)?
    private var workflowCancellables = Set<AnyCancellable>()
    private var accountCancellables = Set<AnyCancellable>()
    private var deletionTask: Task<Void, Never>?
    private var renameTask: Task<Void, Never>?

    init() {}

    func bind(to workflow: any AnimateVideosViewing) {
        self.workflow = workflow
        workflowCancellables.removeAll()

        workflow.inProgressSummaryPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] videosSummary in
                withAnimation(.snappy(duration: 0.28)) {
                    self?.allVideosSummary = videosSummary
                }
            }
            .store(in: &workflowCancellables)

        workflow.activeVideoPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] moment in
                self?.activeVideo = moment
            }
            .store(in: &workflowCancellables)

        workflow.activeWorkspacePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] workspace in
                self?.activeWorkspace = workspace
            }
            .store(in: &workflowCancellables)

        workflow.isLoadingAnimateWorkspacePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.isLoadingAnimateWorkspace = isLoading
            }
            .store(in: &workflowCancellables)

        workflow.isDeletingVideoPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDeleting in
                self?.isDeletingVideo = isDeleting
            }
            .store(in: &workflowCancellables)

        workflow.inProgressErrorMessagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] errorMessage in
                self?.statusMessage = errorMessage
            }
            .store(in: &workflowCancellables)
    }

    func bind(accountStateProvider: any AnimateAccountStateProviding) {
        accountCancellables.removeAll()

        Publishers.CombineLatest(
            accountStateProvider.isSignedInPublisher,
            accountStateProvider.currentUserIdPublisher
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isSignedIn, currentUserId in
            self?.isSignedIn = isSignedIn
            self?.currentUserId = currentUserId
        }
        .store(in: &accountCancellables)
    }

    func selectMoment(_ video: AnimateVideo) {
        if selectedVideoId == video.id {
            selectedVideoId = nil
            workflow?.clearAnimateWorkspace()
            return
        }

        selectedVideoId = video.id
        workflow?.observeAnimateWorkspace(ownerUserId: currentUserId, momentId: video.id)
    }

    func isSelected(_ video: AnimateVideo) -> Bool {
        selectedVideoId == video.id
    }

    func clearSelection() {
        deletionTask?.cancel()
        renameTask?.cancel()
        deletionTask = nil
        renameTask = nil
        selectedVideoId = nil
        statusMessage = nil
        workflow?.clearAnimateWorkspace()
    }

    func renameVideo(_ video: AnimateVideo, title: String) {
        guard let workflow else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        renameTask?.cancel()
        renameTask = Task { [weak self] in
            let didRename = await workflow.renameVideo(video, title: trimmedTitle)
            guard !Task.isCancelled else { return }
            if didRename {
                self?.statusMessage = L10n.string("inProgress.rename.saved")
            }
            self?.renameTask = nil
        }
    }

    func deleteVideo(_ video: AnimateVideo) {
        guard let workflow else { return }
        if ["final_render_pending", "final_rendering"].contains(video.status)
            || (activeWorkspace?.video.id == video.id && activeWorkspace?.activeFinalRenderJob != nil) {
            statusMessage = L10n.string("create.error.waitBeforeDiscard")
            return
        }

        deletionTask?.cancel()
        deletionTask = Task { [weak self] in
            let didDelete = await workflow.deleteVideo(video)
            guard !Task.isCancelled else { return }
            if didDelete {
                self?.selectedVideoId = nil
                self?.activeVideo = nil
                self?.activeWorkspace = nil
                self?.allVideosSummary = self?.allVideosSummary.removing(momentId: video.id) ?? AnimateInProgressSummary()
                self?.statusMessage = L10n.string("inProgress.status.momentDeleted")
            }
            self?.deletionTask = nil
        }
    }
}
