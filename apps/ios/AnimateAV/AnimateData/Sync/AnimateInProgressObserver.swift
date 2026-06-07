import Combine
import Foundation

@MainActor
final class AnimateInProgressObserver: ObservableObject {
    @Published private(set) var moments: [AnimateVideo] = []
    @Published private(set) var errorMessage: String?

    private let videosObserver: any AnimateInProgressObserving
    private var momentsTask: Task<Void, Never>?
    private var observationGeneration = 0
    private let diagnosticsObserverName = "in_progress"

    init(momentsRepository: any AnimateInProgressObserving = AnimateRepository()) {
        videosObserver = momentsRepository
    }

    var momentsPublisher: AnyPublisher<[AnimateVideo], Never> {
        $moments.eraseToAnyPublisher()
    }

    var momentsErrorPublisher: AnyPublisher<String?, Never> {
        $errorMessage.eraseToAnyPublisher()
    }

    func observeAnimateVideos(ownerUserId: String?) {
        observationGeneration += 1
        let generation = observationGeneration
        momentsTask?.cancel()
        moments = []
        errorMessage = nil

        guard let ownerUserId else { return }
        AnimateSyncDiagnostics.addObserverBreadcrumb(observer: diagnosticsObserverName, message: "observer_started")

        do {
            let updates = try videosObserver.observeAnimateVideos(ownerUserId: ownerUserId).values

            momentsTask = Task { [weak self] in
                do {
                    for try await moments in updates {
                        await MainActor.run {
                            guard self?.observationGeneration == generation else { return }
                            self?.moments = moments
                            self?.errorMessage = nil
                        }
                    }
                } catch {
                    await MainActor.run {
                        guard self?.observationGeneration == generation else { return }
                        AnimateSyncDiagnostics.captureObserverError(error, observer: self?.diagnosticsObserverName ?? "in_progress")
                        self?.moments = []
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        } catch {
            guard observationGeneration == generation else { return }
            AnimateSyncDiagnostics.captureObserverError(error, observer: diagnosticsObserverName)
            moments = []
            errorMessage = error.localizedDescription
        }
    }

    func clearAnimateVideos() {
        observationGeneration += 1
        momentsTask?.cancel()
        moments = []
        errorMessage = nil
    }

    deinit {
        momentsTask?.cancel()
    }
}

extension AnimateInProgressObserver: AnimateInProgressListProviding {}
