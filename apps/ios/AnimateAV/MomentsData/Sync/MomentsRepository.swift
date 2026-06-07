import Combine
import Foundation

@MainActor
struct MomentsRepository {
    let remoteClient: MomentsRemoteClient

    @MainActor
    init() {
        self.init(deploymentURL: AppConfig.momentsConvexURL)
    }

    init(deploymentURL: String) {
        remoteClient = MomentsRemoteClient(deploymentURL: deploymentURL)
    }

    var isConfigured: Bool {
        remoteClient.isConfigured
    }

    func observeInProgressMoments(ownerUserId: String) throws -> AnyPublisher<[InProgressMoment], Error> {
        try remoteClient.observeInProgressMoments(ownerUserId: ownerUserId)
    }

    func observeGalleryMoments(ownerUserId: String) throws -> AnyPublisher<[MomentArtifact], Error> {
        try remoteClient.observeGalleryMoments(ownerUserId: ownerUserId)
    }

    func observeMomentWorkspace(
        ownerUserId: String,
        momentId: String
    ) throws -> AnyPublisher<MomentWorkspace?, Error> {
        try remoteClient.observeMomentWorkspace(
            ownerUserId: ownerUserId,
            momentId: momentId
        )
    }

}
