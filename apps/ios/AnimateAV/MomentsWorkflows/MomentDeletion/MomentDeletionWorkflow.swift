import Combine
import Foundation

@MainActor
final class MomentDeletionWorkflow: ObservableObject {
    @Published private(set) var isDeletingMoment = false
    @Published private(set) var errorMessage: String?

    private let currentUserProvider: any AnimateCurrentUserProviding
    private let authTokenProvider: any AnimateAuthTokenProviding
    private let momentDeleter: any MomentsDeleting
    private var deletionGeneration = 0

    init(
        currentUserProvider: any AnimateCurrentUserProviding,
        authTokenProvider: any AnimateAuthTokenProviding,
        momentDeleter: any MomentsDeleting
    ) {
        self.currentUserProvider = currentUserProvider
        self.authTokenProvider = authTokenProvider
        self.momentDeleter = momentDeleter
    }

    var isDeletingMomentPublisher: AnyPublisher<Bool, Never> {
        $isDeletingMoment.eraseToAnyPublisher()
    }

    var deletionErrorPublisher: AnyPublisher<String?, Never> {
        $errorMessage.eraseToAnyPublisher()
    }

    func deleteMoment(_ moment: AnimateVideo) async -> Bool {
        guard !isDeletingMoment else { return false }
        guard let ownerUserId = currentUserProvider.currentUserId else {
            errorMessage = "Sign in before deleting a moment."
            return false
        }
        guard let bearerToken = try? await authTokenProvider.currentBearerToken() else {
            errorMessage = "Sign in again before deleting a moment."
            return false
        }
        _ = ownerUserId

        isDeletingMoment = true
        errorMessage = nil
        deletionGeneration += 1
        let generation = deletionGeneration

        do {
            try await momentDeleter.deleteMoment(bearerToken: bearerToken, momentId: moment.id)
            guard deletionGeneration == generation else { return false }
            isDeletingMoment = false
            return true
        } catch {
            guard deletionGeneration == generation else { return false }
            errorMessage = error.localizedDescription
            isDeletingMoment = false
            return false
        }
    }
}
