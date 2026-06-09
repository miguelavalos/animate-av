import Foundation

struct AnimateRealtimeSessionClient {
    var baseURLString: String
    var session: URLSession = .shared
    var retryPolicy = AnimateNetworkRetryPolicy()

    func createRealtimeSession(bearerToken: String) async throws -> String {
        guard var endpoint = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AnimateAPIError(code: "animate_realtime_not_configured", message: "Animate realtime is not configured.")
        }

        endpoint.appendPathComponent("v1")
        endpoint.appendPathComponent("apps")
        endpoint.appendPathComponent("animateav")
        endpoint.appendPathComponent("workspace")
        endpoint.appendPathComponent("realtime-sessions")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = Data("{}".utf8)

        let (data, response) = try await retryPolicy.runData(session: session, request: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw AnimateAPIError.decode(
                from: data,
                fallbackCode: "animate_realtime_session_failed",
                fallbackMessage: "Realtime session failed."
            )
        }

        return try JSONDecoder().decode(AnimateRealtimeSessionResponse.self, from: data).realtimeSessionId
    }
}

private struct AnimateRealtimeSessionResponse: Decodable {
    let realtimeSessionId: String
}
