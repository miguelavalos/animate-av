import Combine
import Foundation

@MainActor
final class AnimateWorkspaceObserver: ObservableObject {
    @Published private(set) var activeWorkspace: MomentWorkspace?
    @Published private(set) var errorMessage: String?

    private let workspaceObserver: any AnimateWorkspaceObserving
    private var activeWorkspaceTask: Task<Void, Never>?
    private var observationGeneration = 0
    private let diagnosticsObserverName = "workspace"

    init(momentsRepository: any AnimateWorkspaceObserving = AnimateRepository()) {
        workspaceObserver = momentsRepository
    }

    var activeWorkspacePublisher: AnyPublisher<MomentWorkspace?, Never> {
        $activeWorkspace.eraseToAnyPublisher()
    }

    var workspaceErrorPublisher: AnyPublisher<String?, Never> {
        $errorMessage.eraseToAnyPublisher()
    }

    func observeWorkspace(ownerUserId: String?, momentId: String?) {
        observationGeneration += 1
        let generation = observationGeneration
        activeWorkspaceTask?.cancel()
        activeWorkspace = nil
        errorMessage = nil

        guard let ownerUserId, let momentId else { return }
        AnimateSyncDiagnostics.addObserverBreadcrumb(observer: diagnosticsObserverName, message: "observer_started")

        do {
            let updates = try workspaceObserver.observeMomentWorkspace(
                ownerUserId: ownerUserId,
                momentId: momentId
            )
            .values

            activeWorkspaceTask = Task { [weak self] in
                do {
                    for try await workspace in updates {
                        await MainActor.run {
                            guard self?.observationGeneration == generation else { return }
                            self?.activeWorkspace = workspace
                            self?.errorMessage = nil
                        }
                    }
                } catch {
                    await MainActor.run {
                        guard self?.observationGeneration == generation else { return }
                        AnimateSyncDiagnostics.captureObserverError(error, observer: self?.diagnosticsObserverName ?? "workspace")
                        self?.activeWorkspace = nil
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        } catch {
            guard observationGeneration == generation else { return }
            AnimateSyncDiagnostics.captureObserverError(error, observer: diagnosticsObserverName)
            activeWorkspace = nil
            errorMessage = error.localizedDescription
        }
    }

    func clearWorkspace() {
        observationGeneration += 1
        activeWorkspaceTask?.cancel()
        activeWorkspace = nil
        errorMessage = nil
    }

    deinit {
        activeWorkspaceTask?.cancel()
    }
}

extension AnimateWorkspaceObserver: AnimateActiveWorkspaceObserving {}
