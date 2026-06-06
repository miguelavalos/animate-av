import Combine
import Foundation

@MainActor
final class InProgressMomentsWorkflow: ObservableObject {
    @Published private(set) var momentsSummary = InProgressMomentsSummary()
    @Published private(set) var isDeletingMoment = false
    @Published private(set) var errorMessage: String?

    private let momentsObserver: any InProgressMomentsListProviding
    private let workspaceSelectionWorkflow: MomentWorkspaceSelectionWorkflow
    private let momentDeletionWorkflow: MomentDeletionWorkflow
    private let momentTitleUpdater: any MomentsTitleUpdating
    private let currentUserProvider: any MomentsCurrentUserProviding
    private let authTokenProvider: any MomentsAuthTokenProviding
    private var currentOwnerUserId: String?
    private var optimisticMomentTitles: [String: String] = [:]
    private var cancellables = Set<AnyCancellable>()

    init(
        momentsObserver: any InProgressMomentsListProviding,
        workspaceSelectionWorkflow: MomentWorkspaceSelectionWorkflow,
        momentDeletionWorkflow: MomentDeletionWorkflow,
        momentTitleUpdater: any MomentsTitleUpdating,
        currentUserProvider: any MomentsCurrentUserProviding,
        authTokenProvider: any MomentsAuthTokenProviding
    ) {
        self.momentsObserver = momentsObserver
        self.workspaceSelectionWorkflow = workspaceSelectionWorkflow
        self.momentDeletionWorkflow = momentDeletionWorkflow
        self.momentTitleUpdater = momentTitleUpdater
        self.currentUserProvider = currentUserProvider
        self.authTokenProvider = authTokenProvider

        momentsObserver.momentsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] moments in
                self?.apply(moments)
            }
            .store(in: &cancellables)

        momentsObserver.momentsErrorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.applyMomentListError(message)
            }
            .store(in: &cancellables)

        momentDeletionWorkflow.isDeletingMomentPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDeleting in
                self?.isDeletingMoment = isDeleting
            }
            .store(in: &cancellables)

        momentDeletionWorkflow.deletionErrorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.applyMomentDeletionError(message)
            }
            .store(in: &cancellables)

        workspaceSelectionWorkflow.workspaceErrorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.applyWorkspaceError(message)
            }
            .store(in: &cancellables)
    }

    func observeInProgressMoments(ownerUserId: String?) {
        currentOwnerUserId = ownerUserId
        momentsSummary = InProgressMomentsSummary()
        errorMessage = nil
        clearActiveMoment()
        momentsObserver.observeInProgressMoments(ownerUserId: ownerUserId)
    }

    func observeMomentWorkspace(ownerUserId: String?, momentId: String?) {
        errorMessage = nil
        workspaceSelectionWorkflow.observeMomentWorkspace(ownerUserId: ownerUserId, momentId: momentId)
    }

    private func applyWorkspaceError(_ message: String?) {
        guard let message else { return }
        errorMessage = message
    }

    func clearMomentWorkspace() {
        clearActiveMoment()
    }

    func renameMoment(_ moment: InProgressMoment, title: String) async -> Bool {
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
            try await momentTitleUpdater.updateMomentTitle(
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

    func deleteMoment(_ moment: InProgressMoment) async -> Bool {
        errorMessage = nil
        let didDelete = await momentDeletionWorkflow.deleteMoment(moment)
        guard didDelete else { return false }

        if workspaceSelectionWorkflow.activeMoment?.id == moment.id {
            clearActiveMoment()
        }
        observeInProgressMoments(ownerUserId: currentOwnerUserId)
        return true
    }

    private func apply(_ moments: [InProgressMoment]) {
        let renamedMoments = moments.map { moment in
            guard let title = optimisticMomentTitles[moment.id] else { return moment }
            if moment.title == title {
                optimisticMomentTitles[moment.id] = nil
                return moment
            }
            return moment.renamed(title)
        }
        momentsSummary = InProgressMomentsSummary.make(from: renamedMoments)
    }

    private func applyOptimisticTitle(momentId: String, title: String) {
        let moments = momentsSummary.moments.map { moment in
            moment.id == momentId ? moment.renamed(title) : moment
        }
        momentsSummary = InProgressMomentsSummary.make(from: moments)
    }

    private func restoreOptimisticTitle(momentId: String, previousTitle: String?) {
        if let previousTitle {
            optimisticMomentTitles[momentId] = previousTitle
            applyOptimisticTitle(momentId: momentId, title: previousTitle)
            return
        }

        optimisticMomentTitles[momentId] = nil
    }

    private func applyMomentListError(_ message: String?) {
        guard let message else { return }
        errorMessage = message
    }

    private func applyMomentDeletionError(_ message: String?) {
        guard let message else { return }
        errorMessage = message
    }

    private func clearActiveMoment() {
        workspaceSelectionWorkflow.clearMomentWorkspace()
    }

}

extension InProgressMomentsWorkflow: InProgressMomentsViewing {
    var inProgressSummaryPublisher: AnyPublisher<InProgressMomentsSummary, Never> {
        $momentsSummary.eraseToAnyPublisher()
    }

    var activeMomentPublisher: AnyPublisher<InProgressMoment?, Never> {
        workspaceSelectionWorkflow.activeMomentPublisher
    }

    var activeWorkspacePublisher: AnyPublisher<MomentWorkspace?, Never> {
        workspaceSelectionWorkflow.activeWorkspacePublisher
    }

    var isLoadingMomentWorkspacePublisher: AnyPublisher<Bool, Never> {
        workspaceSelectionWorkflow.isLoadingMomentWorkspacePublisher
    }

    var isDeletingMomentPublisher: AnyPublisher<Bool, Never> {
        $isDeletingMoment.eraseToAnyPublisher()
    }

    var inProgressErrorMessagePublisher: AnyPublisher<String?, Never> {
        $errorMessage.eraseToAnyPublisher()
    }
}
