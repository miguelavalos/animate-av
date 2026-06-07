import Foundation

@MainActor
final class AnimateRealtimeSessionStore {
    static let shared = AnimateRealtimeSessionStore()

    private(set) var ownerUserId: String?
    private(set) var realtimeSessionId: String?

    private init() {}

    func update(ownerUserId: String, realtimeSessionId: String) {
        self.ownerUserId = ownerUserId
        self.realtimeSessionId = realtimeSessionId
    }

    func clear() {
        ownerUserId = nil
        realtimeSessionId = nil
    }

    func sessionId(for ownerUserId: String) throws -> String {
        guard self.ownerUserId == ownerUserId, let realtimeSessionId else {
            throw MomentsSyncError.notConfigured
        }

        return realtimeSessionId
    }
}
