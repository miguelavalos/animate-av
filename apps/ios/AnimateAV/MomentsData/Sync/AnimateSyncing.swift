import Combine
import Foundation

@MainActor
protocol MomentsCreating {
    var isConfigured: Bool { get }
    func createMoment(bearerToken: String, form: AnimateVideoSetupForm) async throws -> String
    func updateMomentSetup(bearerToken: String, momentId: String, form: AnimateVideoSetupForm) async throws
}

@MainActor
protocol MomentsDeleting {
    func deleteMoment(bearerToken: String, momentId: String) async throws
}

@MainActor
protocol MomentsTitleUpdating {
    func updateMomentTitle(bearerToken: String, momentId: String, title: String) async throws
}

@MainActor
protocol AnimateInProgressObserving {
    func observeAnimateVideos(ownerUserId: String) throws -> AnyPublisher<[AnimateVideo], Error>
}

@MainActor
protocol AnimateGalleryObserving {
    func observeGalleryMoments(ownerUserId: String) throws -> AnyPublisher<[AnimateArtifact], Error>
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

    func observeGalleryMoments(ownerUserId: String?)
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

extension AnimateWorkspaceCommandClient: MomentsCreating, MomentsDeleting, MomentsTitleUpdating {}
