import Combine
import Foundation

@MainActor
struct AnimateRepository {
    let remoteClient: AnimateRemoteClient

    @MainActor
    init() {
        self.init(deploymentURL: AppConfig.animateConvexURL)
    }

    init(deploymentURL: String) {
        remoteClient = AnimateRemoteClient(deploymentURL: deploymentURL)
    }

    var isConfigured: Bool {
        remoteClient.isConfigured
    }

    func observeAnimateVideos(ownerUserId: String) throws -> AnyPublisher<[AnimateVideo], Error> {
        try remoteClient.observeAnimateVideos(ownerUserId: ownerUserId)
    }

    func observeGalleryMoments(ownerUserId: String) throws -> AnyPublisher<[AnimateArtifact], Error> {
        try remoteClient.observeGalleryMoments(ownerUserId: ownerUserId)
    }

    func observeAnimateWorkspace(
        ownerUserId: String,
        momentId: String
    ) throws -> AnyPublisher<AnimateWorkspace?, Error> {
        try remoteClient.observeAnimateWorkspace(
            ownerUserId: ownerUserId,
            momentId: momentId
        )
    }

}
