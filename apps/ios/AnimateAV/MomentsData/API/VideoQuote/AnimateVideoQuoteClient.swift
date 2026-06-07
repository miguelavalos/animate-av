import Foundation

struct AnimateVideoQuoteClient {
    var baseURLString: String
    var session: URLSession = .shared
    var retryPolicy = AnimateNetworkRetryPolicy()

    var isConfigured: Bool {
        URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }

    func quoteVideo(
        duration: AnimateVideoQuoteDuration? = nil,
        message: String?,
        script: String?,
        removeBranding: Bool,
        bearerToken: String
    ) async throws -> AnimateVideoQuoteResponse {
        guard let baseURL = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AnimateVideoQuoteError.apiNotConfigured
        }

        let endpoint = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("apps")
            .appendingPathComponent("animateav")
            .appendingPathComponent("video")
            .appendingPathComponent("quotes")
        let body = AnimateVideoQuoteRequest(
            duration: duration,
            message: Self.nonBlankOptional(message),
            script: Self.nonBlankOptional(script),
            removeBranding: removeBranding
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await retryPolicy.run {
            try await session.data(for: request)
        }
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw AnimateAPIError.decode(
                from: data,
                fallbackCode: "animate_video_quote_failed",
                fallbackMessage: AnimateVideoQuoteError.quoteFailed.localizedDescription
            )
        }

        return try JSONDecoder().decode(AnimateVideoQuoteResponse.self, from: data)
    }

    private static func nonBlankOptional(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}

enum AnimateVideoQuoteDuration: String, Codable, Equatable {
    case upTo5s
    case upTo10s
    case upTo15s
}

struct AnimateVideoQuoteRequest: Encodable, Equatable {
    let appId = "animateav"
    let duration: AnimateVideoQuoteDuration?
    let message: String?
    let script: String?
    let removeBranding: Bool
}

struct AnimateVideoQuoteResponse: Decodable, Equatable {
    let appId: String
    let outputKind: String
    let duration: AnimateVideoQuoteDuration
    let baseCreditCost: Int
    let brandingRemovalCreditCost: Int
    let totalCreditCost: Int
    let proIncludesBrandingFreeVideo: Bool
    let branding: AnimateVideoQuoteBranding
}

struct AnimateVideoQuoteBranding: Decodable, Equatable {
    let enabled: Bool
    let included: Bool
    let removalAvailable: Bool
    let removalRequested: Bool
    let removalIncluded: Bool
    let assetId: String?
    let placement: AnimateVideoBrandingPlacement?
    let reason: String
}

struct AnimateVideoBrandingPlacement: Decodable, Equatable {
    let anchor: String
    let widthPercentRange: [Int]
    let safeAreaMarginPercentRange: [Int]
}

enum AnimateVideoQuoteError: LocalizedError {
    case apiNotConfigured
    case quoteFailed

    var errorDescription: String? {
        switch self {
        case .apiNotConfigured: "Video quotes are not configured for this build."
        case .quoteFailed: "Avi could not quote this Animate AV video."
        }
    }
}
