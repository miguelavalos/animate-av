import Foundation

struct AnimateAPIError: LocalizedError {
    let code: String
    let message: String

    var errorDescription: String? {
        message
    }

    var isLikelyConfigurationOrServerContractError: Bool {
        code == "unsupported_media_type"
            || code == "invalid_request"
            || code == "invalid_content_type"
            || code == "api_not_configured"
            || code.hasSuffix("_not_configured")
    }

    static func decode(from data: Data, fallbackCode: String, fallbackMessage: String) -> AnimateAPIError {
        if let envelope = try? JSONDecoder().decode(AnimateAPIErrorEnvelope.self, from: data) {
            return AnimateAPIError(code: envelope.error.code, message: envelope.error.message)
        }

        return AnimateAPIError(code: fallbackCode, message: fallbackMessage)
    }
}

private struct AnimateAPIErrorEnvelope: Decodable {
    let error: AnimateAPIErrorPayload
}

private struct AnimateAPIErrorPayload: Decodable {
    let code: String
    let message: String
}
