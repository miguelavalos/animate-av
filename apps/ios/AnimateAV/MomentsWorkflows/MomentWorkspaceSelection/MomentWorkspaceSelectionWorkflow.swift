import Combine
import Foundation

@MainActor
final class MomentWorkspaceSelectionWorkflow: ObservableObject {
    @Published private(set) var activeMoment: InProgressMoment?
    @Published private(set) var activeWorkspace: MomentWorkspace?
    @Published private(set) var isLoadingMomentWorkspace = false
    @Published private(set) var errorMessage: String?

    private let workspaceObserver: any AnimateActiveWorkspaceObserving
    private var cancellables = Set<AnyCancellable>()

    init(workspaceObserver: any AnimateActiveWorkspaceObserving) {
        self.workspaceObserver = workspaceObserver

        workspaceObserver.activeWorkspacePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] workspace in
                self?.apply(workspace: workspace)
            }
            .store(in: &cancellables)

        workspaceObserver.workspaceErrorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.applyWorkspaceError(message)
            }
            .store(in: &cancellables)
    }

    var activeMomentPublisher: AnyPublisher<InProgressMoment?, Never> {
        $activeMoment.eraseToAnyPublisher()
    }

    var activeWorkspacePublisher: AnyPublisher<MomentWorkspace?, Never> {
        $activeWorkspace.eraseToAnyPublisher()
    }

    var isLoadingMomentWorkspacePublisher: AnyPublisher<Bool, Never> {
        $isLoadingMomentWorkspace.eraseToAnyPublisher()
    }

    var workspaceErrorPublisher: AnyPublisher<String?, Never> {
        $errorMessage.eraseToAnyPublisher()
    }

    func observeMomentWorkspace(ownerUserId: String?, momentId: String?) {
        activeMoment = nil
        activeWorkspace = nil
        isLoadingMomentWorkspace = false
        errorMessage = nil

        guard let ownerUserId, let momentId else {
            workspaceObserver.clearWorkspace()
            return
        }

        workspaceObserver.observeWorkspace(ownerUserId: ownerUserId, momentId: momentId)
        isLoadingMomentWorkspace = true
    }

    func clearMomentWorkspace() {
        workspaceObserver.clearWorkspace()
        activeMoment = nil
        activeWorkspace = nil
        isLoadingMomentWorkspace = false
    }

    private func apply(workspace: MomentWorkspace?) {
        activeWorkspace = workspace
        activeMoment = workspace?.moment
        isLoadingMomentWorkspace = false
    }

    private func applyWorkspaceError(_ message: String?) {
        guard let message else { return }
        errorMessage = message
        isLoadingMomentWorkspace = false
    }
}
