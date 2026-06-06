import Combine
import Foundation

@MainActor
final class InProgressMomentsObserver: ObservableObject {
    @Published private(set) var moments: [InProgressMoment] = []
    @Published private(set) var errorMessage: String?

    private let momentsObserver: any InProgressMomentsObserving
    private var momentsTask: Task<Void, Never>?
    private var observationGeneration = 0
    private let diagnosticsObserverName = "in_progress"

    init(momentsRepository: any InProgressMomentsObserving = MomentsRepository()) {
        momentsObserver = momentsRepository
    }

    var momentsPublisher: AnyPublisher<[InProgressMoment], Never> {
        $moments.eraseToAnyPublisher()
    }

    var momentsErrorPublisher: AnyPublisher<String?, Never> {
        $errorMessage.eraseToAnyPublisher()
    }

    func observeInProgressMoments(ownerUserId: String?) {
        observationGeneration += 1
        let generation = observationGeneration
        momentsTask?.cancel()
        moments = []
        errorMessage = nil

        guard let ownerUserId else { return }
        MomentsSyncDiagnostics.addObserverBreadcrumb(observer: diagnosticsObserverName, message: "observer_started")

        do {
            let updates = try momentsObserver.observeInProgressMoments(ownerUserId: ownerUserId).values

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
                        MomentsSyncDiagnostics.captureObserverError(error, observer: self?.diagnosticsObserverName ?? "in_progress")
                        self?.moments = []
                        self?.errorMessage = error.localizedDescription
                    }
                }
            }
        } catch {
            guard observationGeneration == generation else { return }
            MomentsSyncDiagnostics.captureObserverError(error, observer: diagnosticsObserverName)
            moments = []
            errorMessage = error.localizedDescription
        }
    }

    func clearInProgressMoments() {
        observationGeneration += 1
        momentsTask?.cancel()
        moments = []
        errorMessage = nil
    }

    deinit {
        momentsTask?.cancel()
    }
}

extension InProgressMomentsObserver: InProgressMomentsListProviding {}
