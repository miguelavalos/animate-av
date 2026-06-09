import Combine
import Foundation

@MainActor
final class AnimateVideoDeletionWorkflow: ObservableObject {
    @Published private(set) var isDeletingVideo = false
    @Published private(set) var errorMessage: String?

    private let currentUserProvider: any AnimateCurrentUserProviding
    private let authTokenProvider: any AnimateAuthTokenProviding
    private let videoDeleter: any AnimateVideoDeleting
    private var deletionGeneration = 0

    init(
        currentUserProvider: any AnimateCurrentUserProviding,
        authTokenProvider: any AnimateAuthTokenProviding,
        videoDeleter: any AnimateVideoDeleting
    ) {
        self.currentUserProvider = currentUserProvider
        self.authTokenProvider = authTokenProvider
        self.videoDeleter = videoDeleter
    }

    var isDeletingVideoPublisher: AnyPublisher<Bool, Never> {
        $isDeletingVideo.eraseToAnyPublisher()
    }

    var deletionErrorPublisher: AnyPublisher<String?, Never> {
        $errorMessage.eraseToAnyPublisher()
    }

    func deleteVideo(_ video: AnimateVideo) async -> Bool {
        guard !isDeletingVideo else { return false }
        guard let ownerUserId = currentUserProvider.currentUserId else {
            errorMessage = "Sign in before deleting a video."
            return false
        }
        guard let bearerToken = try? await authTokenProvider.currentBearerToken() else {
            errorMessage = "Sign in again before deleting a video."
            return false
        }
        _ = ownerUserId

        isDeletingVideo = true
        errorMessage = nil
        deletionGeneration += 1
        let generation = deletionGeneration

        do {
            try await videoDeleter.deleteVideo(bearerToken: bearerToken, videoId: video.id)
            guard deletionGeneration == generation else { return false }
            isDeletingVideo = false
            return true
        } catch {
            guard deletionGeneration == generation else { return false }
            errorMessage = error.localizedDescription
            isDeletingVideo = false
            return false
        }
    }
}
