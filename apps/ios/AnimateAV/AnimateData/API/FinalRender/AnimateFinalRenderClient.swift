import Foundation

struct AnimateNetworkRetryPolicy: Sendable {
    var maximumRetries = 2
    var baseDelayNanoseconds: UInt64 = 300_000_000

    func shouldRetry(error: Error, attempt: Int) -> Bool {
        guard attempt < maximumRetries else { return false }

        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else { return false }

        switch nsError.code {
        case NSURLErrorNetworkConnectionLost,
             NSURLErrorTimedOut,
             NSURLErrorCannotConnectToHost,
             NSURLErrorCannotFindHost,
             NSURLErrorDNSLookupFailed,
             NSURLErrorNotConnectedToInternet:
            return true
        default:
            return false
        }
    }

    func delayNanoseconds(forAttempt attempt: Int) -> UInt64 {
        baseDelayNanoseconds * UInt64(1 << max(attempt - 1, 0))
    }

    func shouldRetry(statusCode: Int, attempt: Int) -> Bool {
        guard attempt < maximumRetries else { return false }
        return statusCode == 408 || statusCode == 429 || 500..<600 ~= statusCode
    }

    func run<T>(_ operation: () async throws -> T) async throws -> T {
        var attempt = 0

        while true {
            do {
                return try await operation()
            } catch {
                guard shouldRetry(error: error, attempt: attempt) else {
                    throw error
                }

                attempt += 1
                try await Task.sleep(nanoseconds: delayNanoseconds(forAttempt: attempt))
            }
        }
    }

    func runData(session: URLSession, request: URLRequest) async throws -> (Data, URLResponse) {
        var attempt = 0

        while true {
            do {
                let (data, response) = try await session.data(for: request)
                if let httpResponse = response as? HTTPURLResponse,
                   shouldRetry(statusCode: httpResponse.statusCode, attempt: attempt) {
                    attempt += 1
                    try await Task.sleep(nanoseconds: delayNanoseconds(forAttempt: attempt))
                    continue
                }
                return (data, response)
            } catch {
                guard shouldRetry(error: error, attempt: attempt) else {
                    throw error
                }

                attempt += 1
                try await Task.sleep(nanoseconds: delayNanoseconds(forAttempt: attempt))
            }
        }
    }

    func runDownload(session: URLSession, request: URLRequest) async throws -> (URL, URLResponse) {
        var attempt = 0

        while true {
            do {
                let (fileURL, response) = try await session.download(for: request)
                if let httpResponse = response as? HTTPURLResponse,
                   shouldRetry(statusCode: httpResponse.statusCode, attempt: attempt) {
                    attempt += 1
                    try await Task.sleep(nanoseconds: delayNanoseconds(forAttempt: attempt))
                    continue
                }
                return (fileURL, response)
            } catch {
                guard shouldRetry(error: error, attempt: attempt) else {
                    throw error
                }

                attempt += 1
                try await Task.sleep(nanoseconds: delayNanoseconds(forAttempt: attempt))
            }
        }
    }
}

struct AnimateFinalRenderClient {
    var baseURLString: String
    var session: URLSession = .shared
    var retryPolicy = AnimateNetworkRetryPolicy()

    var isConfigured: Bool {
        URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }

    func prepareRenderPlan(
        videoId: String,
        bearerToken: String,
        template: AnimateVideoTemplate,
        creationStyle: AnimateVideoCreationStyleID?,
        form: AnimateVideoSetupForm,
        removesWatermark: Bool,
        selectedSourceLocalIdentifiers: [String],
        sourceImageUploadId: String? = nil,
        generatedImageArtifactId: String? = nil
    ) async throws -> AnimateRenderPlanResponse {
        guard let baseURL = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AnimateFinalRenderError.apiNotConfigured
        }

        let endpoint = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("apps")
            .appendingPathComponent("animateav")
            .appendingPathComponent("renders")
            .appendingPathComponent("plan")
        let message = Self.videoMessageIntent(form)
        let body = AnimateRenderPlanRequest(
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
            selectedSourceLocalIdentifiers: Self.nonBlankIdentifiers(selectedSourceLocalIdentifiers),
            sourceImageUploadId: Self.nonBlankOptional(sourceImageUploadId),
            generatedImageArtifactId: Self.nonBlankOptional(generatedImageArtifactId),
            hasMessage: message.hasMessage,
            messageText: message.messageText,
            audioEnabled: message.audioEnabled,
            musicEnabled: message.musicEnabled,
            voiceEnabled: message.voiceEnabled,
            voiceType: message.voiceType,
            occasion: Self.nonBlankOptional(form.occasion),
            details: nil,
            message: nil,
            script: nil,
            narrationVoice: message.voiceType,
            voiceTone: message.voiceTone,
            creditCost: nil,
            removeWatermark: removesWatermark,
            renderOptionId: nil,
            mockNoSpend: Self.shouldUseMockNoSpendFinalRender ? true : nil
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await retryPolicy.runData(session: session, request: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw AnimateAPIError.decode(
                from: data,
                fallbackCode: "animate_render_plan_failed",
                fallbackMessage: AnimateFinalRenderError.planFailed.localizedDescription
            )
        }

        return try JSONDecoder().decode(AnimateRenderPlanResponse.self, from: data)
    }

    func confirmFinalRender(
        videoId: String,
        bearerToken: String,
        template: AnimateVideoTemplate,
        creationStyle: AnimateVideoCreationStyleID?,
        form: AnimateVideoSetupForm,
        removesWatermark: Bool,
        selectedSourceLocalIdentifiers: [String],
        sourceImageUploadId: String? = nil,
        generatedImageArtifactId: String? = nil,
        planId: String,
        renderOptionId: String?
    ) async throws -> AnimateConfirmFinalRenderResponse {
        guard let baseURL = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AnimateFinalRenderError.apiNotConfigured
        }

        let endpoint = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("apps")
            .appendingPathComponent("animateav")
            .appendingPathComponent("renders")
            .appendingPathComponent("final")
            .appendingPathComponent("confirm")
        let message = Self.videoMessageIntent(form)
        let body = AnimateConfirmFinalRenderRequest(
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
            selectedSourceLocalIdentifiers: Self.nonBlankIdentifiers(selectedSourceLocalIdentifiers),
            sourceImageUploadId: Self.nonBlankOptional(sourceImageUploadId),
            generatedImageArtifactId: Self.nonBlankOptional(generatedImageArtifactId),
            hasMessage: message.hasMessage,
            messageText: message.messageText,
            audioEnabled: message.audioEnabled,
            musicEnabled: message.musicEnabled,
            voiceEnabled: message.voiceEnabled,
            voiceType: message.voiceType,
            occasion: Self.nonBlankOptional(form.occasion),
            details: nil,
            message: nil,
            script: nil,
            narrationVoice: message.voiceType,
            voiceTone: message.voiceTone,
            creditCost: nil,
            removeWatermark: removesWatermark,
            renderOptionId: renderOptionId,
            planId: planId,
            idempotencyKey: "final-confirm:\(videoId):\(planId):\(template.id.rawValue):\(removesWatermark ? "clean" : "watermarked")",
            mockNoSpend: Self.shouldUseMockNoSpendFinalRender ? true : nil
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await retryPolicy.runData(session: session, request: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw AnimateAPIError.decode(
                from: data,
                fallbackCode: "animate_final_render_confirm_failed",
                fallbackMessage: AnimateFinalRenderError.generationFailed.localizedDescription
            )
        }

        return try JSONDecoder().decode(AnimateConfirmFinalRenderResponse.self, from: data)
    }

    func prepareFinalArtifactDownload(
        videoId: String,
        artifactId: String,
        bearerToken: String
    ) async throws -> AnimateArtifactDownloadResponse {
        guard let baseURL = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AnimateFinalRenderError.apiNotConfigured
        }

        let endpoint = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("apps")
            .appendingPathComponent("animateav")
            .appendingPathComponent("artifacts")
            .appendingPathComponent(artifactId)
            .appendingPathComponent("download")
        let body = AnimateArtifactDownloadRequest(
            videoId: videoId,
            artifactId: artifactId
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await retryPolicy.runData(session: session, request: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw AnimateAPIError.decode(
                from: data,
                fallbackCode: "animate_artifact_download_failed",
                fallbackMessage: AnimateFinalRenderError.downloadPreparationFailed.localizedDescription
            )
        }

        return try JSONDecoder().decode(AnimateArtifactDownloadResponse.self, from: data)
    }

    func prepareImageArtifactDownload(
        artifactId: String,
        bearerToken: String
    ) async throws -> AnimateArtifactDownloadResponse {
        guard let baseURL = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AnimateFinalRenderError.apiNotConfigured
        }

        let endpoint = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("apps")
            .appendingPathComponent("animateav")
            .appendingPathComponent("images")
            .appendingPathComponent("artifacts")
            .appendingPathComponent(artifactId)
            .appendingPathComponent("download")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await retryPolicy.runData(session: session, request: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw AnimateAPIError.decode(
                from: data,
                fallbackCode: "animate_image_artifact_download_failed",
                fallbackMessage: AnimateFinalRenderError.downloadPreparationFailed.localizedDescription
            )
        }

        return try JSONDecoder().decode(AnimateArtifactDownloadResponse.self, from: data)
    }

    func downloadFinalArtifact(from response: AnimateArtifactDownloadResponse) async throws -> URL {
        guard let downloadURL = URL(string: response.downloadUrl) else {
            throw AnimateFinalRenderError.downloadPreparationFailed
        }

        var request = URLRequest(url: downloadURL)
        request.httpMethod = response.method
        response.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (fileURL, urlResponse) = try await retryPolicy.runDownload(session: session, request: request)
        guard let httpResponse = urlResponse as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw AnimateFinalRenderError.downloadFailed
        }

        return fileURL
    }

    private static func nonBlankOptional(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private static func videoMessageIntent(_ form: AnimateVideoSetupForm) -> (
        hasMessage: Bool,
        messageText: String?,
        audioEnabled: Bool,
        musicEnabled: Bool,
        voiceEnabled: Bool,
        voiceType: String?,
        voiceTone: String?
    ) {
        let messageText = form.activeMessageText
        let voiceProfile = form.activeVoiceProfile
        return (
            hasMessage: messageText != nil,
            messageText: messageText,
            audioEnabled: form.audioEnabled,
            musicEnabled: form.audioEnabled && form.musicEnabled,
            voiceEnabled: voiceProfile != nil,
            voiceType: voiceProfile?.rawValue,
            voiceTone: voiceProfile == nil ? nil : form.voiceTone.rawValue
        )
    }

    private static func nonBlankIdentifiers(_ values: [String]) -> [String]? {
        let identifiers = values.compactMap(nonBlankOptional)
        return identifiers.isEmpty ? nil : identifiers
    }

    private static var shouldUseMockNoSpendFinalRender: Bool {
        let value = Bundle.main.object(forInfoDictionaryKey: "ANIMATEAV_MOCK_NO_SPEND_FINAL_RENDER") as? String
        return ["1", "true", "yes"].contains(value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? "")
    }
}

enum AnimateFinalRenderError: LocalizedError {
    case apiNotConfigured
    case planFailed
    case generationFailed
    case downloadPreparationFailed
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .apiNotConfigured: "Final render is not configured for this build."
        case .planFailed: "Avi could not check this video for final video creation."
        case .generationFailed: "Final render failed before delivery. Credits were not committed unless an export was delivered."
        case .downloadPreparationFailed: "The final video download could not be prepared."
        case .downloadFailed: "The final video could not be downloaded."
        }
    }
}
