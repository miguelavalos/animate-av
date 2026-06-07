import Combine
import Foundation

@MainActor
final class AnimateWorkspaceObserver: ObservableObject {
    @Published private(set) var activeWorkspace: AnimateWorkspace?
    @Published private(set) var errorMessage: String?

    private let workspaceObserver: any AnimateWorkspaceObserving
    private var activeWorkspaceTask: Task<Void, Never>?
    private var observationGeneration = 0
    private let diagnosticsObserverName = "workspace"

    init(animateRepository: any AnimateWorkspaceObserving = AnimateRepository()) {
        workspaceObserver = animateRepository
    }

    var activeWorkspacePublisher: AnyPublisher<AnimateWorkspace?, Never> {
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
            let updates = try workspaceObserver.observeAnimateWorkspace(
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
