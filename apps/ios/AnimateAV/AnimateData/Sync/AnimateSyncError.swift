import Foundation

enum AnimateSyncError: LocalizedError {
    case notConfigured
    case invalidForm
    case missingRenderJob
    case unexpectedResponse

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            "Animate video sync is not configured for this build."
        case .invalidForm:
            "Add the occasion before starting a video."
        case .missingRenderJob:
            "The backend did not return a render job for this request."
        case .unexpectedResponse:
            "The backend response could not be used."
        }
    }
}
