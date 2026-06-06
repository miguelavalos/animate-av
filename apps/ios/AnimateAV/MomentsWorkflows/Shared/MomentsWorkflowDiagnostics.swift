import AVDiagnosticsFoundation
import Foundation

enum MomentsWorkflowDiagnostics {
    static func addBreadcrumb(feature: String, operation: String, data: [String: String] = [:]) {
        var breadcrumbData = data
        breadcrumbData["operation"] = operation
        AVDiagnostics.addBreadcrumb(AVDiagnosticsBreadcrumb(
            category: feature,
            message: "\(feature).\(operation)",
            data: breadcrumbData
        ))
    }

    static func capture(
        _ error: any Error,
        feature: String,
        operation: String,
        step: String,
        data: [String: String] = [:]
    ) {
        guard !(error is CancellationError) else { return }

        var contextData = data
        contextData["operation"] = operation
        contextData["step"] = step
        AVDiagnostics.capture(
            error: error,
            context: AVDiagnosticsContext(
                feature: feature,
                code: errorCode(for: error),
                data: contextData
            )
        )
    }

    static func errorCode(for error: any Error) -> String? {
        if let apiError = error as? MomentsAPIError {
            return apiError.code
        }
        if let storyError = error as? StoryWorkflowError {
            return String(describing: storyError)
        }
        if let renderError = error as? MomentsFinalRenderError {
            return String(describing: renderError)
        }
        if let purchaseError = error as? MomentsPurchaseError {
            return String(describing: purchaseError)
        }
        return nil
    }
}
