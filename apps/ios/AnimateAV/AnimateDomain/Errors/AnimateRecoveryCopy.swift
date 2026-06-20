import Foundation

enum AnimateRecoveryCopy {
    static func mediaImportFailure() -> String {
        L10n.string("recovery.mediaImportFailure")
    }

    static func mediaUploadUnavailable() -> String {
        L10n.string("recovery.mediaUploadUnavailable")
    }

    static func mediaVideoDirectionSaveFailure() -> String {
        L10n.string("recovery.mediaVideoDirectionSaveFailure")
    }

    static func mediaVideoSaveFailure() -> String {
        L10n.string("recovery.mediaVideoSaveFailure")
    }

    static func videoDirectionStartFailure() -> String {
        L10n.string("recovery.videoDirectionStartFailure")
    }

    static func videoDirectionFailure() -> String {
        L10n.string("recovery.videoDirectionFailure")
    }

    static func renderStartFailure() -> String {
        L10n.string("recovery.renderStartFailure")
    }

    static func renderRefreshFailure() -> String {
        L10n.string("recovery.renderRefreshFailure")
    }

    static func failedRenderDetail(userMessage: String?, errorMessage: String?) -> String {
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
