import Combine
@preconcurrency import ConvexMobile
import Foundation

@MainActor
struct MomentsRemoteClient {
    private let client: ConvexClient?
    private let realtimeSessionStore: MomentsRealtimeSessionStore

    init(deploymentURL: String, realtimeSessionStore: MomentsRealtimeSessionStore = .shared) {
        let trimmedURL = deploymentURL.trimmingCharacters(in: .whitespacesAndNewlines)
        client = trimmedURL.isEmpty ? nil : ConvexClient(deploymentUrl: trimmedURL)
        self.realtimeSessionStore = realtimeSessionStore
    }

    var isConfigured: Bool {
        client != nil
    }

    func observeInProgressMoments(ownerUserId: String) throws -> AnyPublisher<[InProgressMoment], Error> {
        let client = try requireClient()
        let realtimeSessionId = try realtimeSessionStore.sessionId(for: ownerUserId)

        return client.subscribe(
            to: "moments:listMoments",
            with: [
                "ownerUserId": ownerUserId,
                "realtimeSessionId": realtimeSessionId,
                "collection": "in_progress"
            ],
            yielding: [InProgressMoment].self
        )
        .mapError { $0 as Error }
        .eraseToAnyPublisher()
    }

    func observeGalleryMoments(ownerUserId: String) throws -> AnyPublisher<[InProgressMoment], Error> {
        let client = try requireClient()
        let realtimeSessionId = try realtimeSessionStore.sessionId(for: ownerUserId)

        return client.subscribe(
            to: "moments:listMoments",
            with: [
                "ownerUserId": ownerUserId,
                "realtimeSessionId": realtimeSessionId,
                "collection": "gallery"
            ],
            yielding: [InProgressMoment].self
        )
        .mapError { $0 as Error }
        .eraseToAnyPublisher()
    }

    func observeMomentWorkspace(
        ownerUserId: String,
        momentId: String
    ) throws -> AnyPublisher<MomentWorkspace?, Error> {
        let client = try requireClient()
        let realtimeSessionId = try realtimeSessionStore.sessionId(for: ownerUserId)

        return client.subscribe(
            to: "moments:getMomentWorkspace",
            with: [
                "ownerUserId": ownerUserId,
                "realtimeSessionId": realtimeSessionId,
                "momentId": momentId
            ],
            yielding: MomentWorkspace?.self
        )
        .mapError { $0 as Error }
        .eraseToAnyPublisher()
    }

    func requireClient() throws -> ConvexClient {
        guard let client else {
            throw MomentsSyncError.notConfigured
        }

        return client
    }

}
