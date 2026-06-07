import Combine
import Foundation

@MainActor
class WorkspaceObservingWorkflow: ObservableObject {
    @Published private(set) var activeWorkspace: AnimateWorkspace?

    let workspaceObserver: any AnimateActiveWorkspaceObserving

    private var cancellables = Set<AnyCancellable>()
    private var workflowGeneration = WorkflowGeneration()

    init(workspaceObserver: any AnimateActiveWorkspaceObserving) {
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

    func workspaceDidChange(_ workspace: AnimateWorkspace?) {}

    func beginWorkflowGeneration() -> Int {
        workflowGeneration.begin()
    }

    func isCurrentWorkflowGeneration(_ generation: Int) -> Bool {
        workflowGeneration.isCurrent(generation)
    }

    func advanceWorkflowGeneration() {
        workflowGeneration.advance()
    }

    private func updateActiveWorkspace(_ workspace: AnimateWorkspace?) {
        activeWorkspace = workspace
        workspaceDidChange(workspace)
    }
}
