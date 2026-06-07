import Combine
import Foundation

@MainActor
final class AnimateGalleryObserver: ObservableObject {
    @Published private(set) var moments: [AnimateArtifact] = []
    @Published private(set) var errorMessage: String?

    private let videosObserver: any AnimateGalleryObserving
    private var momentsTask: Task<Void, Never>?
    private var observationGeneration = 0
    private let diagnosticsObserverName = "gallery"

    init(animateRepository: any AnimateGalleryObserving = AnimateRepository()) {
        videosObserver = animateRepository
    }

    var galleryMomentsPublisher: AnyPublisher<[AnimateArtifact], Never> {
        $moments.eraseToAnyPublisher()
    }

    var galleryMomentsErrorPublisher: AnyPublisher<String?, Never> {
        $errorMessage.eraseToAnyPublisher()
    }

    func observeGalleryArtifacts(ownerUserId: String?) {
        observationGeneration += 1
        let generation = observationGeneration
        momentsTask?.cancel()
        moments = []
        errorMessage = nil

        guard let ownerUserId else { return }
        AnimateSyncDiagnostics.addObserverBreadcrumb(observer: diagnosticsObserverName, message: "observer_started")

        do {
            let updates = try videosObserver.observeGalleryArtifacts(ownerUserId: ownerUserId).values

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
                        AnimateSyncDiagnostics.captureObserverError(error, observer: self?.diagnosticsObserverName ?? "gallery")
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

    func clearGalleryMoments() {
        observationGeneration += 1
        momentsTask?.cancel()
        moments = []
        errorMessage = nil
    }

    deinit {
        momentsTask?.cancel()
    }
}

extension AnimateGalleryObserver: AnimateGalleryListProviding {}
