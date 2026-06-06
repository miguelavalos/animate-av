import Foundation

struct MomentsStoryClient {
    var baseURLString: String
    var session: URLSession = .shared
    var retryPolicy = MomentsNetworkRetryPolicy()

    var isConfigured: Bool {
        URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }

    func generatePlan(
        momentId: String,
        ownerUserId: String,
        bearerToken: String,
        form: MomentSetupForm,
        mediaAssets: [MomentMediaAsset]
    ) async throws -> MomentsStoryResponse {
        let selectedMedia = mediaAssets
            .filter(\.selected)
            .sorted { left, right in left.sortOrder < right.sortOrder }
            .map {
                MomentsStoryMedia(
                    mediaAssetId: $0.id,
                    mediaKind: $0.kind,
                    sortOrder: Int($0.sortOrder),
                    selected: $0.selected,
                    moderationStatus: $0.moderationStatus
                )
            }

        return try await generatePlan(
            momentId: momentId,
            ownerUserId: ownerUserId,
            bearerToken: bearerToken,
            form: form,
            selectedMedia: selectedMedia
        )
    }

    func generatePlan(
        momentId: String,
        ownerUserId: String,
        bearerToken: String,
        form: MomentSetupForm,
        selectedMedia: [MomentsStoryMedia]
    ) async throws -> MomentsStoryResponse {
        guard let baseURL = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw MomentsStoryError.apiNotConfigured
        }

        let endpoint = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("apps")
            .appendingPathComponent("animateav")
            .appendingPathComponent("story")
            .appendingPathComponent("plans")

        let requestBody = MomentsStoryRequest(
            momentId: momentId,
            creationMode: form.creationMode.rawValue,
            look: form.look.rawValue,
            theme: form.theme.rawValue,
            mood: form.tone.rawValue,
            duration: form.duration.rawValue,
            mediaUse: form.mediaUse.rawValue,
            occasion: form.occasion,
            details: form.details,
            media: selectedMedia,
            idempotencyKey: "story:\(momentId):\(MomentsStoryInputSignature.make(momentId: momentId, form: form, selectedMedia: selectedMedia))"
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await retryingData(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            let apiError = MomentsAPIError.decode(
                from: data,
                fallbackCode: "moments_story_plan_failed",
                fallbackMessage: MomentsStoryError.planFailed.localizedDescription
            )
            throw apiError
        }

        let plan = try JSONDecoder().decode(MomentsStoryResponse.self, from: data)
        if plan.status == "blocked" {
            throw MomentsStoryError.blocked(plan.errorMessage ?? "Avi needs safer inputs before planning this story.")
        }
        if plan.status == "provider_failed" {
            throw MomentsStoryError.providerFailed(plan.errorMessage ?? "Story plan failed.")
        }

        return plan
    }

    private func retryingData(for request: URLRequest) async throws -> (Data, URLResponse) {
        var attempt = 0

        while true {
            do {
                return try await session.data(for: request)
            } catch {
                guard retryPolicy.shouldRetry(error: error, attempt: attempt) else {
                    throw error
                }

                attempt += 1
                try await Task.sleep(nanoseconds: retryPolicy.delayNanoseconds(forAttempt: attempt))
            }
        }
    }
}

enum MomentsStoryError: LocalizedError {
    case apiNotConfigured
    case planFailed
    case blocked(String)
    case providerFailed(String)

    var errorDescription: String? {
        switch self {
        case .apiNotConfigured: "Story planning is not configured for this build."
        case .planFailed: "Story plan request failed."
        case .blocked(let message): message
        case .providerFailed(let message): message
        }
    }
}
