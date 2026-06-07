import AVDiagnosticsFoundation
import Foundation

enum AnimateSyncDiagnostics {
    static func addObserverBreadcrumb(observer: String, message: String) {
        AVDiagnostics.addBreadcrumb(
            AVDiagnosticsBreadcrumb(
                category: "animate.sync",
                message: message,
                data: [
                    "observer": observer,
                    "operation": "observe"
                ]
            )
        )
    }

    static func captureObserverError(_ error: Error, observer: String) {
        AVDiagnostics.capture(
            error: error,
            context: AVDiagnosticsContext(
                feature: "animate.sync",
                code: diagnosticsErrorCode(for: error),
                data: [
                    "observer": observer,
                    "operation": "observe"
                ]
            )
        )
    }

    private static func diagnosticsErrorCode(for error: Error) -> String {
        if let syncError = error as? AnimateSyncError {
            return String(describing: syncError)
        }
        return String(describing: type(of: error))
    }
}
