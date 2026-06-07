import Foundation

enum AnimateRecoveryCopy {
    static func mediaImportFailure() -> String {
        L10n.string("recovery.mediaImportFailure")
    }

    static func mediaUploadUnavailable() -> String {
        L10n.string("recovery.mediaUploadUnavailable")
    }

    static func mediaStorySaveFailure() -> String {
        L10n.string("recovery.mediaStorySaveFailure")
    }

    static func mediaVideoSaveFailure() -> String {
        L10n.string("recovery.mediaVideoSaveFailure")
    }

    static func storyStartFailure() -> String {
        L10n.string("recovery.storyStartFailure")
    }

    static func storyFailure() -> String {
        L10n.string("recovery.storyFailure")
    }

    static func renderStartFailure() -> String {
        L10n.string("recovery.renderStartFailure")
    }

    static func renderRefreshFailure() -> String {
        L10n.string("recovery.renderRefreshFailure")
    }

    static func failedRenderDetail(userMessage: String?, errorMessage: String?) -> String {
        if let userMessage, !userMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return userMessage
        }

        return L10n.string("recovery.failedRenderDetail")
    }

    static func artifactActionDetail(kind: String, status: String) -> String {
        let kindTitle = AnimateStatusRules.displayKind(kind)

        switch status {
        case "available":
            return kind == "final_export"
                ? "Your finished video is ready to save or share."
                : "\(kindTitle) is ready to check."
        case "expired":
            return "\(kindTitle) is no longer available. Return to Create and generate it again."
        case "failed", "error", "blocked":
            return "\(kindTitle) is not available. Credits are only finalized after a usable final video is ready. Please retry in Create or contact support."
        case "processing", "running", "queued":
            return "\(kindTitle) is still being prepared. Refresh in a moment."
        default:
            return "\(kindTitle) is not ready to save or share yet."
        }
    }
}
