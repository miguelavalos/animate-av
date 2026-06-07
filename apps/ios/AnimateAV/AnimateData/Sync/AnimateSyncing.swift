import Combine
import Foundation

@MainActor
protocol AnimateVideoCreating {
    var isConfigured: Bool { get }
    func createVideo(bearerToken: String, form: AnimateVideoSetupForm) async throws -> String
    func updateVideoSetup(bearerToken: String, momentId: String, form: AnimateVideoSetupForm) async throws
}

@MainActor
protocol AnimateVideoDeleting {
    func deleteVideo(bearerToken: String, momentId: String) async throws
}

@MainActor
protocol AnimateVideoTitleUpdating {
    func updateMomentTitle(bearerToken: String, momentId: String, title: String) async throws
}

@MainActor
protocol AnimateInProgressObserving {
    func observeAnimateVideos(ownerUserId: String) throws -> AnyPublisher<[AnimateVideo], Error>
}

@MainActor
protocol AnimateGalleryObserving {
    func observeGalleryArtifacts(ownerUserId: String) throws -> AnyPublisher<[AnimateArtifact], Error>
}

@MainActor
protocol AnimateInProgressListProviding {
    var momentsPublisher: AnyPublisher<[AnimateVideo], Never> { get }
    var momentsErrorPublisher: AnyPublisher<String?, Never> { get }

    func observeAnimateVideos(ownerUserId: String?)
    func clearAnimateVideos()
}

@MainActor
protocol AnimateGalleryListProviding {
    var galleryMomentsPublisher: AnyPublisher<[AnimateArtifact], Never> { get }
    var galleryMomentsErrorPublisher: AnyPublisher<String?, Never> { get }

    func observeGalleryArtifacts(ownerUserId: String?)
    func clearGalleryMoments()
}

@MainActor
protocol AnimateWorkspaceObserving {
    func observeAnimateWorkspace(
        ownerUserId: String,
        momentId: String
    ) throws -> AnyPublisher<AnimateWorkspace?, Error>
}

@MainActor
protocol AnimateActiveWorkspaceObserving {
    var activeWorkspacePublisher: AnyPublisher<AnimateWorkspace?, Never> { get }
    var workspaceErrorPublisher: AnyPublisher<String?, Never> { get }

    func observeWorkspace(ownerUserId: String?, momentId: String?)
    func clearWorkspace()
}

extension AnimateRepository:
    AnimateInProgressObserving,
    AnimateGalleryObserving,
    AnimateWorkspaceObserving {}

extension AnimateWorkspaceCommandClient: AnimateVideoCreating, AnimateVideoDeleting, AnimateVideoTitleUpdating {}
