import Foundation

@MainActor
protocol AccountDeletionAPI {
    func fetchAccountDeletionSummary() async throws -> AccountSummary
    func requestAccountDeletion() async throws -> DeleteAccountRequestResponse
    func finalizeAccountDeletion() async throws -> DeleteAccountFinalizeResponse
    func unlinkCurrentApp() async throws -> UnlinkAppResponse
}

@MainActor
struct AnimateAccountDeletionClient: AccountDeletionAPI {
    var baseURLString: String = AppConfig.accountAPIBaseURL
    var tokenProvider: () async throws -> String?
    var session: URLSession = .shared
    var decoder = JSONDecoder()

    func fetchAccountDeletionSummary() async throws -> AccountSummary {
        let data = try await requestData(path: "/v1/me", method: "GET")
        return try decoder.decode(AccountSummary.self, from: data)
    }

    func requestAccountDeletion() async throws -> DeleteAccountRequestResponse {
        let data = try await requestData(path: "/v1/me/delete-account-request", method: "POST")
        return try decoder.decode(DeleteAccountRequestResponse.self, from: data)
    }

    func finalizeAccountDeletion() async throws -> DeleteAccountFinalizeResponse {
        let data = try await requestData(path: "/v1/me/delete-account-finalize", method: "POST")
        return try decoder.decode(DeleteAccountFinalizeResponse.self, from: data)
    }

    func unlinkCurrentApp() async throws -> UnlinkAppResponse {
        let data = try await requestData(path: "/v1/apps/animateav/link", method: "DELETE")
        return try decoder.decode(UnlinkAppResponse.self, from: data)
    }

    private func requestData(path: String, method: String) async throws -> Data {
        guard let baseURL = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AnimateAPIError(code: "invalid_account_api_url", message: L10n.string("access.apiURLMissing"))
        }
        guard let token = try await tokenProvider() else {
            throw AnimateAPIError(code: "animate_auth_token_missing", message: L10n.string("access.signInRequired.generic"))
        }

        let endpoint = path
            .split(separator: "/")
            .reduce(baseURL) { url, component in
                url.appendingPathComponent(String(component))
            }
        var request = URLRequest(url: endpoint)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw AnimateAPIError.decode(
                from: data,
                fallbackCode: "account_deletion_request_failed",
                fallbackMessage: L10n.string("accountDeletion.statusUpdateFailed.detail")
            )
        }

        return data
    }
}
