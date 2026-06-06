import Foundation

struct MomentsWorkspaceCommandClient {
    var baseURLString: String
    var session: URLSession = .shared
    var retryPolicy = MomentsNetworkRetryPolicy()

    var isConfigured: Bool {
        URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }

    func createMoment(bearerToken: String, form: MomentSetupForm) async throws -> String {
        let response: MomentWorkspaceCommandResponse = try await send(
            path: ["workspace", "moments"],
            method: "POST",
            bearerToken: bearerToken,
            body: MomentWorkspaceSetupCommand(form: form)
        )
        return response.momentId
    }

    func updateMomentSetup(bearerToken: String, momentId: String, form: MomentSetupForm) async throws {
        let _: MomentWorkspaceCommandResponse = try await send(
            path: ["workspace", "moments", momentId, "setup"],
            method: "PATCH",
            bearerToken: bearerToken,
            body: MomentWorkspaceSetupCommand(form: form)
        )
    }

    func updateMomentTitle(bearerToken: String, momentId: String, title: String) async throws {
        let _: MomentWorkspaceCommandResponse = try await send(
            path: ["workspace", "moments", momentId, "title"],
            method: "PATCH",
            bearerToken: bearerToken,
            body: MomentWorkspaceTitleCommand(title: title)
        )
    }

    func deleteMoment(bearerToken: String, momentId: String) async throws {
        let _: MomentWorkspaceCommandResponse = try await send(
            path: ["workspace", "moments", momentId],
            method: "DELETE",
            bearerToken: bearerToken,
            body: MomentWorkspaceDeleteCommand()
        )
    }

    private func send<Body: Encodable, Response: Decodable>(
        path: [String],
        method: String,
        bearerToken: String,
        body: Body
    ) async throws -> Response {
        guard var endpoint = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw MomentsAPIError(code: "moments_workspace_not_configured", message: "Moments workspace commands are not configured.")
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
            throw MomentsAPIError.decode(
                from: data,
                fallbackCode: "moments_workspace_command_failed",
                fallbackMessage: "Moment update failed."
            )
        }

        return try JSONDecoder().decode(Response.self, from: data)
    }
}

private struct MomentWorkspaceSetupCommand: Encodable {
    let creationMode: String
    let look: String
    let theme: String
    let mood: String
    let duration: String
    let mediaUse: String
    let title: String?
    let occasion: String?
    let details: String?

    init(form: MomentSetupForm) {
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

private struct MomentWorkspaceTitleCommand: Encodable {
    let title: String
}

private struct MomentWorkspaceDeleteCommand: Encodable {
    let deleteSourceMedia = true
    let deleteGeneratedArtifacts = true
    let reason = "user request"
}

private struct MomentWorkspaceCommandResponse: Decodable {
    let momentId: String
}
