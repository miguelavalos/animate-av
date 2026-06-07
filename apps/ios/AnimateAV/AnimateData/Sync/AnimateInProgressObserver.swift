import Combine
import Foundation

@MainActor
final class AnimateInProgressObserver: ObservableObject {
    @Published private(set) var videos: [AnimateVideo] = []
    @Published private(set) var errorMessage: String?

    private let videosObserver: any AnimateInProgressObserving
    private var momentsTask: Task<Void, Never>?
    private var observationGeneration = 0
    private let diagnosticsObserverName = "in_progress"

    init(animateRepository: any AnimateInProgressObserving = AnimateRepository()) {
        videosObserver = animateRepository
    }

    var momentsPublisher: AnyPublisher<[AnimateVideo], Never> {
        $videos.eraseToAnyPublisher()
    }

    var momentsErrorPublisher: AnyPublisher<String?, Never> {
        $errorMessage.eraseToAnyPublisher()
    }

    func observeAnimateVideos(ownerUserId: String?) {
        observationGeneration += 1
        let generation = observationGeneration
        momentsTask?.cancel()
        videos = []
        errorMessage = nil

        guard let ownerUserId else { return }
        AnimateSyncDiagnostics.addObserverBreadcrumb(observer: diagnosticsObserverName, message: "observer_started")

        do {
            let updates = try videosObserver.observeAnimateVideos(ownerUserId: ownerUserId).values

            momentsTask = Task { [weak self] in
                do {
                    for try await videos in updates {
                        await MainActor.run {
                            guard self?.observationGeneration == generation else { return }
                            self?.videos = videos
                            self?.errorMessage = nil
                        }
                    }
                } catch {
                    await MainActor.run {
                        guard self?.observationGeneration == generation else { return }
                        AnimateSyncDiagnostics.captureObserverError(error, observer: self?.diagnosticsObserverName ?? "in_progress")
                        self?.videos = []
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        } catch {
            guard observationGeneration == generation else { return }
            AnimateSyncDiagnostics.captureObserverError(error, observer: diagnosticsObserverName)
            videos = []
            errorMessage = error.localizedDescription
        }
    }

    func clearAnimateVideos() {
        observationGeneration += 1
        momentsTask?.cancel()
        videos = []
        errorMessage = nil
    }

    deinit {
        momentsTask?.cancel()
    }
}

extension AnimateInProgressObserver: AnimateInProgressListProviding {}
