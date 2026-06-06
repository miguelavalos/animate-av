import Foundation

struct MomentsAPIError: LocalizedError {
    let code: String
    let message: String

    var errorDescription: String? {
        message
    }

    static func decode(from data: Data, fallbackCode: String, fallbackMessage: String) -> MomentsAPIError {
        if let envelope = try? JSONDecoder().decode(MomentsAPIErrorEnvelope.self, from: data) {
            return MomentsAPIError(code: envelope.error.code, message: envelope.error.message)
        }

        return MomentsAPIError(code: fallbackCode, message: fallbackMessage)
    }
}

private struct MomentsAPIErrorEnvelope: Decodable {
    let error: MomentsAPIErrorPayload
}

private struct MomentsAPIErrorPayload: Decodable {
    let code: String
    let message: String
}
