import Combine
import Foundation

@MainActor
class WorkspaceObservingWorkflow: ObservableObject {
    @Published private(set) var activeWorkspace: MomentWorkspace?

    let workspaceObserver: any MomentsActiveWorkspaceObserving

    private var cancellables = Set<AnyCancellable>()
    private var workflowGeneration = WorkflowGeneration()

    init(workspaceObserver: any MomentsActiveWorkspaceObserving) {
        self.workspaceObserver = workspaceObserver

        workspaceObserver.activeWorkspacePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] workspace in
                self?.updateActiveWorkspace(workspace)
            }
            .store(in: &cancellables)
    }

    func clearActiveWorkspace() {
        updateActiveWorkspace(nil)
    }

    func workspaceDidChange(_ workspace: MomentWorkspace?) {}

    func beginWorkflowGeneration() -> Int {
        workflowGeneration.begin()
    }

    func isCurrentWorkflowGeneration(_ generation: Int) -> Bool {
        workflowGeneration.isCurrent(generation)
    }

    func advanceWorkflowGeneration() {
        workflowGeneration.advance()
    }

    private func updateActiveWorkspace(_ workspace: MomentWorkspace?) {
        activeWorkspace = workspace
        workspaceDidChange(workspace)
    }
}
