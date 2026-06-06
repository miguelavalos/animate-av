import Foundation

struct MomentsRenderStatusClient {
    var baseURLString: String
    var session: URLSession = .shared
    var retryPolicy = MomentsNetworkRetryPolicy()

    var isConfigured: Bool {
        URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }

    func fetchStatus(renderJobId: String, bearerToken: String) async throws -> MomentsRenderStatusResponse {
        guard let baseURL = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw MomentsRenderStatusError.apiNotConfigured
        }

        let endpoint = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("apps")
            .appendingPathComponent("animateav")
            .appendingPathComponent("renders")
            .appendingPathComponent(renderJobId)
            .appendingPathComponent("status")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await retryPolicy.run {
            try await session.data(for: request)
        }
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw MomentsAPIError.decode(
                from: data,
                fallbackCode: "moments_render_status_failed",
                fallbackMessage: MomentsRenderStatusError.statusFailed.localizedDescription
            )
        }

        return try JSONDecoder().decode(MomentsRenderStatusResponse.self, from: data)
    }

}

enum MomentsRenderStatusError: LocalizedError {
    case apiNotConfigured
    case statusFailed

    var errorDescription: String? {
        switch self {
        case .apiNotConfigured: "Render status is not configured for this build."
        case .statusFailed: "Render status could not be loaded."
        }
    }
}
