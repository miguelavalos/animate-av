import AVDiagnosticsFoundation
import Foundation

enum MomentsSyncDiagnostics {
    static func addObserverBreadcrumb(observer: String, message: String) {
        AVDiagnostics.addBreadcrumb(
            AVDiagnosticsBreadcrumb(
                category: "moments.sync",
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
                feature: "moments.sync",
                code: diagnosticsErrorCode(for: error),
                data: [
                    "observer": observer,
                    "operation": "observe"
                ]
            )
        )
    }

    private static func diagnosticsErrorCode(for error: Error) -> String {
        if let syncError = error as? MomentsSyncError {
            return String(describing: syncError)
        }
        return String(describing: type(of: error))
    }
}
