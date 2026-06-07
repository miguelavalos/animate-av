import Foundation

struct MomentsImageGenerationAccountingClient {
    var baseURLString: String
    var session: URLSession = .shared
    var retryPolicy = MomentsNetworkRetryPolicy()

    var isConfigured: Bool {
        URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }

    func fetchAvailability(bearerToken: String) async throws -> AnimateImageGenerationAvailabilityResponse {
        guard let baseURL = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw MomentsImageGenerationAccountingError.apiNotConfigured
        }

        let endpoint = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("apps")
            .appendingPathComponent("animateav")
            .appendingPathComponent("images")
            .appendingPathComponent("availability")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await retryPolicy.run {
            try await session.data(for: request)
        }
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw MomentsAPIError.decode(
                from: data,
                fallbackCode: "animate_image_availability_failed",
                fallbackMessage: MomentsImageGenerationAccountingError.availabilityFailed.localizedDescription
            )
        }

        return try JSONDecoder().decode(AnimateImageGenerationAvailabilityResponse.self, from: data)
    }
}

struct AnimateImageGenerationAvailabilityResponse: Decodable, Equatable {
    let appId: String
    let outputKind: String
    let monthlyProAllowance: AnimateImageGenerationMonthlyAllowance
    let purchasedImages: AnimateImageGenerationPurchasedImages
    let availableImages: Int
    let packOffer: AnimateImageGenerationPackOffer
}

struct AnimateImageGenerationMonthlyAllowance: Decodable, Equatable {
    let included: Bool
    let period: String
    let allowance: Int
    let used: Int
    let remaining: Int
}

struct AnimateImageGenerationPurchasedImages: Decodable, Equatable {
    let balance: Int
}

struct AnimateImageGenerationPackOffer: Decodable, Equatable {
    let enabled: Bool
    let creditCost: Int
    let imageGenerations: Int
    let userCanPurchase: Bool
    let blocker: String?
}

enum MomentsImageGenerationAccountingError: LocalizedError {
    case apiNotConfigured
    case signInRequired
    case availabilityFailed

    var errorDescription: String? {
        switch self {
        case .apiNotConfigured: "Image generation accounting is not configured for this build."
        case .signInRequired: "Sign in to load image generation balance."
        case .availabilityFailed: "Avi could not load image generation balance."
        }
    }
}
