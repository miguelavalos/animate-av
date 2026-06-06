import AVDiagnosticsFoundation
import Foundation

enum MomentsMediaUploadDiagnostics {
    static func addBreadcrumb(operation: String, source: String? = nil, assetCount: Int? = nil) {
        var metadata: [String: String] = [
            "operation": operation,
        ]
        if let source {
            metadata["source"] = source
        }
        if let assetCount {
            metadata["asset_count"] = String(max(assetCount, 0))
        }
        AVDiagnostics.addBreadcrumb(AVDiagnosticsBreadcrumb(
            category: "moments.media",
            message: "moments_media_\(operation)",
            data: metadata
        ))
    }

    static func captureImportError(
        _ error: any Error,
        source: String,
        requestedCount: Int,
        remainingSlots: Int
    ) {
        guard shouldCapture(error) else { return }
        AVDiagnostics.capture(
            error: error,
            context: baseContext(
                operation: "import",
                step: source,
                errorCode: errorCode(for: error),
                extra: [
                    "source": source,
                    "asset_count": String(max(requestedCount, 0)),
                    "remaining_slots": String(max(remainingSlots, 0)),
                ]
            )
        )
    }

    static func captureRestoreError(_ error: any Error, expectedAssetCount: Int) {
        guard shouldCapture(error) else { return }
        AVDiagnostics.capture(
            error: error,
            context: baseContext(
                operation: "restore",
                step: "local_media",
                errorCode: errorCode(for: error),
                extra: [
                    "asset_count": String(max(expectedAssetCount, 0)),
                ]
            )
        )
    }

    static func capturePersistenceError(
        _ error: any Error,
        step: String,
        selectedCount: Int,
        pendingCount: Int,
        alreadySyncedCount: Int,
        requiresProductStateSave: Bool
    ) {
        guard shouldCapture(error) else { return }
        AVDiagnostics.capture(
            error: error,
            context: baseContext(
                operation: "persist",
                step: step,
                errorCode: errorCode(for: error),
                extra: [
                    "selected_count": String(max(selectedCount, 0)),
                    "pending_count": String(max(pendingCount, 0)),
                    "already_synced_count": String(max(alreadySyncedCount, 0)),
                    "requires_product_state_save": String(requiresProductStateSave),
                ]
            )
        )
    }

    private static func baseContext(
        operation: String,
        step: String,
        errorCode: String?,
        extra: [String: String]
    ) -> AVDiagnosticsContext {
        var data: [String: String] = [
            "operation": operation,
            "step": step,
        ]
        extra.forEach { data[$0.key] = $0.value }
        return AVDiagnosticsContext(feature: "moments.media", code: errorCode, data: data)
    }

    private static func shouldCapture(_ error: any Error) -> Bool {
        !(error is CancellationError)
    }

    private static func errorCode(for error: any Error) -> String? {
        if let apiError = error as? MomentsAPIError {
            return apiError.code
        }
        if let uploadError = error as? MomentsUploadError {
            return String(describing: uploadError)
        }
        return nil
    }
}
