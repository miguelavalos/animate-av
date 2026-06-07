import Combine
import Foundation

@MainActor
protocol MomentsCreating {
    var isConfigured: Bool { get }
    func createMoment(bearerToken: String, form: MomentSetupForm) async throws -> String
    func updateMomentSetup(bearerToken: String, momentId: String, form: MomentSetupForm) async throws
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
    func observeInProgressMoments(ownerUserId: String) throws -> AnyPublisher<[InProgressMoment], Error>
}

@MainActor
protocol AnimateGalleryObserving {
    func observeGalleryMoments(ownerUserId: String) throws -> AnyPublisher<[MomentArtifact], Error>
}

@MainActor
protocol AnimateInProgressListProviding {
    var momentsPublisher: AnyPublisher<[InProgressMoment], Never> { get }
    var momentsErrorPublisher: AnyPublisher<String?, Never> { get }

    func observeInProgressMoments(ownerUserId: String?)
    func clearInProgressMoments()
}

@MainActor
protocol AnimateGalleryListProviding {
    var galleryMomentsPublisher: AnyPublisher<[MomentArtifact], Never> { get }
    var galleryMomentsErrorPublisher: AnyPublisher<String?, Never> { get }

    func observeGalleryMoments(ownerUserId: String?)
    func clearGalleryMoments()
}

@MainActor
protocol AnimateWorkspaceObserving {
    func observeMomentWorkspace(
        ownerUserId: String,
        momentId: String
    ) throws -> AnyPublisher<MomentWorkspace?, Error>
}

@MainActor
protocol AnimateActiveWorkspaceObserving {
    var activeWorkspacePublisher: AnyPublisher<MomentWorkspace?, Never> { get }
    var workspaceErrorPublisher: AnyPublisher<String?, Never> { get }

    func observeWorkspace(ownerUserId: String?, momentId: String?)
    func clearWorkspace()
}

extension AnimateRepository:
    AnimateInProgressObserving,
    AnimateGalleryObserving,
    AnimateWorkspaceObserving {}

extension AnimateWorkspaceCommandClient: MomentsCreating, MomentsDeleting, MomentsTitleUpdating {}
