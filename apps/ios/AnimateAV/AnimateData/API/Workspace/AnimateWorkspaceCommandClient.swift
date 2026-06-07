import Foundation

struct AnimateWorkspaceCommandClient {
    var baseURLString: String
    var session: URLSession = .shared
    var retryPolicy = AnimateNetworkRetryPolicy()

    var isConfigured: Bool {
        URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }

    func createVideo(bearerToken: String, form: AnimateVideoSetupForm) async throws -> String {
        let response: AnimateWorkspaceCommandResponse = try await send(
            path: ["workspace", "moments"],
            method: "POST",
            bearerToken: bearerToken,
            body: AnimateWorkspaceSetupCommand(form: form)
        )
        return response.momentId
    }

    func updateVideoSetup(bearerToken: String, momentId: String, form: AnimateVideoSetupForm) async throws {
        let _: AnimateWorkspaceCommandResponse = try await send(
            path: ["workspace", "moments", momentId, "setup"],
            method: "PATCH",
            bearerToken: bearerToken,
            body: AnimateWorkspaceSetupCommand(form: form)
        )
    }

    func updateMomentTitle(bearerToken: String, momentId: String, title: String) async throws {
        let _: AnimateWorkspaceCommandResponse = try await send(
            path: ["workspace", "moments", momentId, "title"],
            method: "PATCH",
            bearerToken: bearerToken,
            body: AnimateWorkspaceTitleCommand(title: title)
        )
    }

    func deleteVideo(bearerToken: String, momentId: String) async throws {
        let _: AnimateWorkspaceCommandResponse = try await send(
            path: ["workspace", "moments", momentId],
            method: "DELETE",
            bearerToken: bearerToken,
            body: AnimateWorkspaceDeleteCommand()
        )
    }

    private func send<Body: Encodable, Response: Decodable>(
        path: [String],
        method: String,
        bearerToken: String,
        body: Body
    ) async throws -> Response {
        guard var endpoint = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AnimateAPIError(code: "moments_workspace_not_configured", message: "Moments workspace commands are not configured.")
        }

        endpoint.appendPathComponent("v1")
        endpoint.appendPathComponent("apps")
        endpoint.appendPathComponent("animateav")
        for component in path {
            endpoint.appendPathComponent(component)
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await retryPolicy.run {
            try await session.data(for: request)
        }
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw AnimateAPIError.decode(
                from: data,
                fallbackCode: "moments_workspace_command_failed",
                fallbackMessage: "Moment update failed."
            )
        }

        return try JSONDecoder().decode(Response.self, from: data)
    }
}

private struct AnimateWorkspaceSetupCommand: Encodable {
    let creationMode: String
    let look: String
    let theme: String
    let mood: String
    let duration: String
    let mediaUse: String
    let title: String?
    let occasion: String?
    let details: String?

    init(form: AnimateVideoSetupForm) {
        creationMode = form.creationMode.rawValue
        look = form.look.rawValue
        theme = form.theme.rawValue
        mood = form.tone.rawValue
        duration = form.duration.rawValue
        mediaUse = form.mediaUse.rawValue
        title = form.title
        occasion = form.occasion
        details = form.details
    }
}

private struct AnimateWorkspaceTitleCommand: Encodable {
    let title: String
}

private struct AnimateWorkspaceDeleteCommand: Encodable {
    let deleteSourceMedia = true
    let deleteGeneratedArtifacts = true
    let reason = "user request"
}

private struct AnimateWorkspaceCommandResponse: Decodable {
    let momentId: String
}
