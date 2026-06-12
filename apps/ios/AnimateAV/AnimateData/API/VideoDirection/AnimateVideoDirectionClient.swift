import Foundation

struct AnimateVideoDirectionClient {
    var baseURLString: String
    var session: URLSession = .shared
    var retryPolicy = AnimateNetworkRetryPolicy()

    var isConfigured: Bool {
        URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }

    func generatePlan(
        videoId: String,
        ownerUserId: String,
        bearerToken: String,
        form: AnimateVideoSetupForm,
        mediaAssets: [AnimateMediaAsset]
    ) async throws -> AnimateVideoDirectionResponse {
        let selectedMedia = mediaAssets
            .filter(\.selected)
            .sorted { left, right in left.sortOrder < right.sortOrder }
            .map {
                AnimateVideoDirectionMedia(
                    mediaAssetId: $0.id,
                    mediaKind: $0.kind,
                    sortOrder: Int($0.sortOrder),
                    selected: $0.selected,
                    moderationStatus: $0.moderationStatus
                )
            }

        return try await generatePlan(
            videoId: videoId,
            ownerUserId: ownerUserId,
            bearerToken: bearerToken,
            form: form,
            selectedMedia: selectedMedia
        )
    }

    func generatePlan(
        videoId: String,
        ownerUserId: String,
        bearerToken: String,
        form: AnimateVideoSetupForm,
        selectedMedia: [AnimateVideoDirectionMedia]
    ) async throws -> AnimateVideoDirectionResponse {
        guard let baseURL = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AnimateVideoDirectionError.apiNotConfigured
        }

        let endpoint = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("apps")
            .appendingPathComponent("animateav")
            .appendingPathComponent("story")
            .appendingPathComponent("plans")

        let requestBody = AnimateVideoDirectionRequest(
            videoId: videoId,
            creationMode: form.creationMode.rawValue,
            look: form.look.rawValue,
            theme: form.theme.rawValue,
            mood: form.tone.rawValue,
            duration: form.duration.rawValue,
            mediaUse: form.mediaUse.rawValue,
            movementDirection: form.movementDirection.rawValue,
            motionDirection: form.movementDirection.rawValue,
            animationDirection: Self.nonBlankOptional(form.animationDirection),
            occasion: form.occasion,
            details: form.activeMessageText ?? "",
            narrationVoice: form.activeVoiceProfile?.rawValue ?? "none",
            voiceTone: form.activeVoiceProfile == nil ? "" : form.voiceTone.rawValue,
            media: selectedMedia,
            idempotencyKey: "story:\(videoId):\(AnimateVideoDirectionInputSignature.make(videoId: videoId, form: form, selectedMedia: selectedMedia))"
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await retryingData(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            let apiError = AnimateAPIError.decode(
                from: data,
                fallbackCode: "animate_story_plan_failed",
                fallbackMessage: AnimateVideoDirectionError.planFailed.localizedDescription
            )
            throw apiError
        }

        let plan = try JSONDecoder().decode(AnimateVideoDirectionResponse.self, from: data)
        if plan.status == "blocked" {
            throw AnimateVideoDirectionError.blocked(plan.errorMessage ?? "Avi needs safer inputs before preparing this video.")
        }
        if plan.status == "provider_failed" {
            throw AnimateVideoDirectionError.providerFailed(plan.errorMessage ?? "Video direction failed.")
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

    private static func nonBlankOptional(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}

enum AnimateVideoDirectionError: LocalizedError {
    case apiNotConfigured
    case planFailed
    case blocked(String)
    case providerFailed(String)

    var errorDescription: String? {
        switch self {
        case .apiNotConfigured: "Video direction is not configured for this build."
        case .planFailed: "Video direction request failed."
        case .blocked(let message): message
        case .providerFailed(let message): message
        }
    }
}
