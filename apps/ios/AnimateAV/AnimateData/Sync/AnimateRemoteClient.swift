import Combine
@preconcurrency import ConvexMobile
import Foundation

@MainActor
struct AnimateRemoteClient {
    private let client: ConvexClient?
    private let realtimeSessionStore: AnimateRealtimeSessionStore

    init(deploymentURL: String, realtimeSessionStore: AnimateRealtimeSessionStore = .shared) {
        let trimmedURL = deploymentURL.trimmingCharacters(in: .whitespacesAndNewlines)
        client = trimmedURL.isEmpty ? nil : ConvexClient(deploymentUrl: trimmedURL)
        self.realtimeSessionStore = realtimeSessionStore
    }

    var isConfigured: Bool {
        client != nil
    }

    func observeAnimateVideos(ownerUserId: String) throws -> AnyPublisher<[AnimateVideo], Error> {
        let client = try requireClient()
        let realtimeSessionId = try realtimeSessionStore.sessionId(for: ownerUserId)

        let videoJobs = client.subscribe(
            to: "animate:listVideoJobs",
            with: [
                "ownerUserId": ownerUserId,
                "realtimeSessionId": realtimeSessionId
            ],
            yielding: [AnimateVideoJob].self
        )
        .map { jobs in
            jobs.map(\.inProgressMoment)
        }
        .mapError { $0 as Error }
        .eraseToAnyPublisher()

        let imageJobs = client.subscribe(
            to: "animate:listImageJobs",
            with: [
                "ownerUserId": ownerUserId,
                "realtimeSessionId": realtimeSessionId
            ],
            yielding: [AnimateImageJob].self
        )
        .map { jobs in
            jobs.map(\.inProgressMoment)
        }
        .mapError { $0 as Error }
        .eraseToAnyPublisher()

        return Publishers.CombineLatest(videoJobs, imageJobs)
            .map { videoMoments, imageMoments in
                (videoMoments + imageMoments).sorted { $0.updatedAt > $1.updatedAt }
            }
            .eraseToAnyPublisher()
    }

    private struct AnimateVideoJob: Decodable {
        let id: String
        let title: String
        let status: String
        let phase: String?
        let look: String?
        let language: String?
        let script: String?
        let duration: String
        let durationSeconds: Double?
        let totalCreditCost: Double?
        let updatedAt: Double

        var inProgressMoment: AnimateVideo {
            AnimateVideo(
                id: id,
                template: .birthdayMessage,
                creationMode: "video",
                look: look ?? "cartoon",
                theme: "celebration",
                mood: phase,
                duration: duration,
                mediaUse: "singlePhoto",
                status: status,
                title: title,
                tone: language,
                tempo: nil,
                occasion: nil,
                details: script,
                durationSeconds: durationSeconds ?? 0,
                creditCost: totalCreditCost ?? 0,
                updatedAt: updatedAt,
                mediaCount: 1,
                assetKind: "video"
            )
        }

        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case title
            case status
            case phase
            case look
            case language
            case script
            case duration
            case durationSeconds
            case totalCreditCost
            case updatedAt
        }
    }

    private struct AnimateImageJob: Decodable {
        let id: String
        let title: String
        let status: String
        let phase: String?
        let look: String?
        let updatedAt: Double

        var inProgressMoment: AnimateVideo {
            AnimateVideo(
                id: id,
                template: .birthdayMessage,
                creationMode: "image",
                look: look ?? "cartoon",
                theme: "image",
                mood: phase,
                duration: "image",
                mediaUse: "singlePhoto",
                status: status,
                title: title,
                tone: nil,
                tempo: nil,
                occasion: nil,
                details: nil,
                durationSeconds: 0,
                creditCost: 0,
                updatedAt: updatedAt,
                mediaCount: 1,
                assetKind: "image"
            )
        }

        enum CodingKeys: String, CodingKey {
            case id = "_id"
            case title
            case status
            case phase
            case look
            case updatedAt
        }
    }

    func observeGalleryMoments(ownerUserId: String) throws -> AnyPublisher<[AnimateArtifact], Error> {
        let client = try requireClient()
        let realtimeSessionId = try realtimeSessionStore.sessionId(for: ownerUserId)

        return client.subscribe(
            to: "animate:listGalleryArtifacts",
            with: [
                "ownerUserId": ownerUserId,
                "realtimeSessionId": realtimeSessionId
            ],
            yielding: [AnimateArtifact].self
        )
        .mapError { $0 as Error }
        .eraseToAnyPublisher()
    }

    func observeAnimateWorkspace(
        ownerUserId: String,
        momentId: String
    ) throws -> AnyPublisher<AnimateWorkspace?, Error> {
        let client = try requireClient()
        let realtimeSessionId = try realtimeSessionStore.sessionId(for: ownerUserId)

        return client.subscribe(
            to: "moments:getAnimateWorkspace",
            with: [
                "ownerUserId": ownerUserId,
                "realtimeSessionId": realtimeSessionId,
                "momentId": momentId
            ],
            yielding: AnimateWorkspace?.self
        )
        .mapError { $0 as Error }
        .eraseToAnyPublisher()
    }

    func requireClient() throws -> ConvexClient {
        guard let client else {
            throw AnimateSyncError.notConfigured
        }

        return client
    }

}
