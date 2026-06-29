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
        guard shouldCapture(error) else { return }

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

    static func shouldCapture(_ error: Error) -> Bool {
        if let syncError = error as? AnimateSyncError,
           syncError == .notConfigured {
            return false
        }
        return true
    }

    private static func diagnosticsErrorCode(for error: Error) -> String {
        if let syncError = error as? AnimateSyncError {
            return String(describing: syncError)
        }
        return String(describing: type(of: error))
    }
}
