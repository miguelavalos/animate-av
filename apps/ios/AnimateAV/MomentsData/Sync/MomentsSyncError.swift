import Foundation

enum MomentsSyncError: LocalizedError {
    case notConfigured
    case invalidForm
    case missingRenderJob
    case unexpectedResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            "Moment sync is not configured for this build."
        case .invalidForm:
            "Add the occasion before starting a Moment."
        case .missingRenderJob:
            "The backend did not return a render job for this request."
        case .unexpectedResponse:
            "The backend response could not be used."
        }
    }
}
