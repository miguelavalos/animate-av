import Combine
import Foundation
import SwiftUI

@MainActor
final class AnimateInProgressViewModel: ObservableObject {
    @Published private(set) var momentsSummary = AnimateInProgressSummary()
    @Published private(set) var isSignedIn = false
    @Published private(set) var currentUserId: String?
    @Published private(set) var activeMoment: AnimateVideo?
    @Published private(set) var activeWorkspace: AnimateWorkspace?
    @Published private(set) var selectedMomentId: String?
    @Published private(set) var isLoadingAnimateWorkspace = false
    @Published private(set) var isDeletingMoment = false
    @Published private(set) var statusMessage: String?

    var videoMomentsSummary: AnimateInProgressSummary {
        momentsSummary.videoSummary
    }

    var imageMomentsSummary: AnimateInProgressSummary {
        momentsSummary.imageSummary
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
            .sink { [weak self] momentsSummary in
                withAnimation(.snappy(duration: 0.28)) {
                    self?.momentsSummary = momentsSummary
                }
            }
            .store(in: &workflowCancellables)

        workflow.activeMomentPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] moment in
                self?.activeMoment = moment
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

        workflow.isDeletingMomentPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDeleting in
                self?.isDeletingMoment = isDeleting
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

    func selectMoment(_ moment: AnimateVideo) {
        if selectedMomentId == moment.id {
            selectedMomentId = nil
            workflow?.clearAnimateWorkspace()
            return
        }

        selectedMomentId = moment.id
        workflow?.observeAnimateWorkspace(ownerUserId: currentUserId, momentId: moment.id)
    }

    func isSelected(_ moment: AnimateVideo) -> Bool {
        selectedMomentId == moment.id
    }

    func clearSelection() {
        deletionTask?.cancel()
        renameTask?.cancel()
        deletionTask = nil
        renameTask = nil
        selectedMomentId = nil
        statusMessage = nil
        workflow?.clearAnimateWorkspace()
    }

    func renameMoment(_ moment: AnimateVideo, title: String) {
        guard let workflow else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        renameTask?.cancel()
        renameTask = Task { [weak self] in
            let didRename = await workflow.renameMoment(moment, title: trimmedTitle)
            guard !Task.isCancelled else { return }
            if didRename {
                self?.statusMessage = L10n.string("inProgress.rename.saved")
            }
            self?.renameTask = nil
        }
    }

    func deleteMoment(_ moment: AnimateVideo) {
        guard let workflow else { return }
        if ["final_render_pending", "final_rendering"].contains(moment.status)
            || (activeWorkspace?.moment.id == moment.id && activeWorkspace?.activeFinalRenderJob != nil) {
            statusMessage = L10n.string("create.error.waitBeforeDiscard")
            return
        }

        deletionTask?.cancel()
        deletionTask = Task { [weak self] in
            let didDelete = await workflow.deleteMoment(moment)
            guard !Task.isCancelled else { return }
            if didDelete {
                self?.selectedMomentId = nil
                self?.activeMoment = nil
                self?.activeWorkspace = nil
                self?.momentsSummary = self?.momentsSummary.removing(momentId: moment.id) ?? AnimateInProgressSummary()
                self?.statusMessage = L10n.string("inProgress.status.momentDeleted")
            }
            self?.deletionTask = nil
        }
    }
}
