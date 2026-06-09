import Combine
import Foundation

@MainActor
final class AnimateWorkspaceSelectionWorkflow: ObservableObject {
    @Published private(set) var activeVideo: AnimateVideo?
    @Published private(set) var activeWorkspace: AnimateWorkspace?
    @Published private(set) var isLoadingAnimateWorkspace = false
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

    var activeVideoPublisher: AnyPublisher<AnimateVideo?, Never> {
        $activeVideo.eraseToAnyPublisher()
    }

    var activeWorkspacePublisher: AnyPublisher<AnimateWorkspace?, Never> {
        $activeWorkspace.eraseToAnyPublisher()
    }

    var isLoadingAnimateWorkspacePublisher: AnyPublisher<Bool, Never> {
        $isLoadingAnimateWorkspace.eraseToAnyPublisher()
    }

    var workspaceErrorPublisher: AnyPublisher<String?, Never> {
        $errorMessage.eraseToAnyPublisher()
    }

    func observeAnimateWorkspace(ownerUserId: String?, videoId: String?) {
        activeVideo = nil
        activeWorkspace = nil
        isLoadingAnimateWorkspace = false
        errorMessage = nil

        guard let ownerUserId, let videoId else {
            workspaceObserver.clearWorkspace()
            return
        }

        workspaceObserver.observeWorkspace(ownerUserId: ownerUserId, videoId: videoId)
        isLoadingAnimateWorkspace = true
    }

    func clearAnimateWorkspace() {
        workspaceObserver.clearWorkspace()
        activeVideo = nil
        activeWorkspace = nil
        isLoadingAnimateWorkspace = false
    }

    private func apply(workspace: AnimateWorkspace?) {
        activeWorkspace = workspace
        activeVideo = workspace?.video
        isLoadingAnimateWorkspace = false
    }

    private func applyWorkspaceError(_ message: String?) {
        guard let message else { return }
        errorMessage = message
        isLoadingAnimateWorkspace = false
    }
}
