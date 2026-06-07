import Foundation

struct MomentsNetworkRetryPolicy: Sendable {
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
}

struct MomentsFinalRenderClient {
    var baseURLString: String
    var session: URLSession = .shared
    var retryPolicy = MomentsNetworkRetryPolicy()

    var isConfigured: Bool {
        URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }

    func prepareRenderPlan(
        momentId: String,
        bearerToken: String,
        template: MomentTemplate,
        creationStyle: MomentCreationStyleID?,
        form: MomentSetupForm,
        removesWatermark: Bool,
        selectedSourceLocalIdentifiers: [String]
    ) async throws -> MomentsRenderPlanResponse {
        guard let baseURL = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw MomentsFinalRenderError.apiNotConfigured
        }

        let endpoint = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("apps")
            .appendingPathComponent("animateav")
            .appendingPathComponent("renders")
            .appendingPathComponent("plan")
        let messageFields = Self.videoMessageFields(form)
        let body = MomentsRenderPlanRequest(
            momentId: momentId,
            creationMode: form.creationMode.rawValue,
            look: form.look.rawValue,
            theme: form.theme.rawValue,
            mood: form.tone.rawValue,
            duration: form.duration.rawValue,
            mediaUse: form.mediaUse.rawValue,
            selectedSourceLocalIdentifiers: Self.nonBlankIdentifiers(selectedSourceLocalIdentifiers),
            occasion: Self.nonBlankOptional(form.occasion),
            details: Self.nonBlankOptional(form.details),
            message: messageFields.message,
            script: messageFields.script,
            creditCost: nil,
            removeWatermark: removesWatermark,
            renderOptionId: nil
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await retryPolicy.run {
            try await session.data(for: request)
        }
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw MomentsAPIError.decode(
                from: data,
                fallbackCode: "moments_render_plan_failed",
                fallbackMessage: MomentsFinalRenderError.planFailed.localizedDescription
            )
        }

        return try JSONDecoder().decode(MomentsRenderPlanResponse.self, from: data)
    }

    func confirmFinalRender(
        momentId: String,
        bearerToken: String,
        template: MomentTemplate,
        creationStyle: MomentCreationStyleID?,
        form: MomentSetupForm,
        removesWatermark: Bool,
        selectedSourceLocalIdentifiers: [String],
        planId: String,
        renderOptionId: String?
    ) async throws -> MomentsConfirmFinalRenderResponse {
        guard let baseURL = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw MomentsFinalRenderError.apiNotConfigured
        }

        let endpoint = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("apps")
            .appendingPathComponent("animateav")
            .appendingPathComponent("renders")
            .appendingPathComponent("final")
            .appendingPathComponent("confirm")
        let messageFields = Self.videoMessageFields(form)
        let body = MomentsConfirmFinalRenderRequest(
            momentId: momentId,
            creationMode: form.creationMode.rawValue,
            look: form.look.rawValue,
            theme: form.theme.rawValue,
            mood: form.tone.rawValue,
            duration: form.duration.rawValue,
            mediaUse: form.mediaUse.rawValue,
            selectedSourceLocalIdentifiers: Self.nonBlankIdentifiers(selectedSourceLocalIdentifiers),
            occasion: Self.nonBlankOptional(form.occasion),
            details: Self.nonBlankOptional(form.details),
            message: messageFields.message,
            script: messageFields.script,
            creditCost: nil,
            removeWatermark: removesWatermark,
            renderOptionId: renderOptionId,
            planId: planId,
            idempotencyKey: "final-confirm:\(momentId):\(planId):\(template.id.rawValue):\(removesWatermark ? "clean" : "watermarked")"
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await retryPolicy.run {
            try await session.data(for: request)
        }
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw MomentsAPIError.decode(
                from: data,
                fallbackCode: "moments_final_render_confirm_failed",
                fallbackMessage: MomentsFinalRenderError.generationFailed.localizedDescription
            )
        }

        return try JSONDecoder().decode(MomentsConfirmFinalRenderResponse.self, from: data)
    }

    func prepareFinalArtifactDownload(
        momentId: String,
        artifactId: String,
        bearerToken: String
    ) async throws -> MomentsArtifactDownloadResponse {
        guard let baseURL = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw MomentsFinalRenderError.apiNotConfigured
        }

        let endpoint = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("apps")
            .appendingPathComponent("animateav")
            .appendingPathComponent("artifacts")
            .appendingPathComponent(artifactId)
            .appendingPathComponent("download")
        let body = MomentsArtifactDownloadRequest(
            momentId: momentId,
            artifactId: artifactId
        )

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await retryPolicy.run {
            try await session.data(for: request)
        }
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw MomentsAPIError.decode(
                from: data,
                fallbackCode: "moments_artifact_download_failed",
                fallbackMessage: MomentsFinalRenderError.downloadPreparationFailed.localizedDescription
            )
        }

        return try JSONDecoder().decode(MomentsArtifactDownloadResponse.self, from: data)
    }

    func prepareImageArtifactDownload(
        artifactId: String,
        bearerToken: String
    ) async throws -> MomentsArtifactDownloadResponse {
        guard let baseURL = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw MomentsFinalRenderError.apiNotConfigured
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

        let (data, response) = try await retryPolicy.run {
            try await session.data(for: request)
        }
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw MomentsAPIError.decode(
                from: data,
                fallbackCode: "animate_image_artifact_download_failed",
                fallbackMessage: MomentsFinalRenderError.downloadPreparationFailed.localizedDescription
            )
        }

        return try JSONDecoder().decode(MomentsArtifactDownloadResponse.self, from: data)
    }

    func downloadFinalArtifact(from response: MomentsArtifactDownloadResponse) async throws -> URL {
        guard let downloadURL = URL(string: response.downloadUrl) else {
            throw MomentsFinalRenderError.downloadPreparationFailed
        }

        var request = URLRequest(url: downloadURL)
        request.httpMethod = response.method
        response.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        let (fileURL, urlResponse) = try await retryPolicy.run {
            try await session.download(for: request)
        }
        guard let httpResponse = urlResponse as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw MomentsFinalRenderError.downloadFailed
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

    private static func videoMessageFields(_ form: MomentSetupForm) -> (message: String?, script: String?) {
        if let script = nonBlankOptional(form.details) {
            return (message: nil, script: script)
        }

        return (message: nonBlankOptional(form.occasion), script: nil)
    }

    private static func nonBlankIdentifiers(_ values: [String]) -> [String]? {
        let identifiers = values.compactMap(nonBlankOptional)
        return identifiers.isEmpty ? nil : identifiers
    }
}

enum MomentsFinalRenderError: LocalizedError {
    case apiNotConfigured
    case planFailed
    case generationFailed
    case downloadPreparationFailed
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .apiNotConfigured: "Final render is not configured for this build."
        case .planFailed: "Avi could not check this Moment for final video creation."
        case .generationFailed: "Final render failed before delivery. Credits were not committed unless an export was delivered."
        case .downloadPreparationFailed: "The final video download could not be prepared."
        case .downloadFailed: "The final video could not be downloaded."
        }
    }
}
