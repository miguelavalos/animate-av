import Foundation

struct AnimateRenderStatusClient {
    var baseURLString: String
    var session: URLSession = .shared
    var retryPolicy = AnimateNetworkRetryPolicy()

    var isConfigured: Bool {
        URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }

    func fetchStatus(renderJobId: String, bearerToken: String) async throws -> AnimateRenderStatusResponse {
        guard let baseURL = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AnimateRenderStatusError.apiNotConfigured
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

        let (data, response) = try await retryPolicy.runData(session: session, request: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw AnimateAPIError.decode(
                from: data,
                fallbackCode: "animate_render_status_failed",
                fallbackMessage: AnimateRenderStatusError.statusFailed.localizedDescription
            )
        }

        return try JSONDecoder().decode(AnimateRenderStatusResponse.self, from: data)
    }

}

enum AnimateRenderStatusError: LocalizedError {
    case apiNotConfigured
    case statusFailed

    var errorDescription: String? {
        switch self {
        case .apiNotConfigured: "Render status is not configured for this build."
        case .statusFailed: "Render status could not be loaded."
        }
    }
}
