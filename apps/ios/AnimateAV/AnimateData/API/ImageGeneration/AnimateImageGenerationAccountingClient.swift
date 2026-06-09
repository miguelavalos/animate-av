import Foundation

struct AnimateImageGenerationAccountingClient {
    var baseURLString: String
    var session: URLSession = .shared
    var retryPolicy = AnimateNetworkRetryPolicy()

    var isConfigured: Bool {
        URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }

    func fetchAvailability(bearerToken: String) async throws -> AnimateImageGenerationAvailabilityResponse {
        guard let baseURL = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AnimateImageGenerationAccountingError.apiNotConfigured
        }

        let endpoint = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("apps")
            .appendingPathComponent("animateav")
            .appendingPathComponent("images")
            .appendingPathComponent("availability")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await retryPolicy.runData(session: session, request: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw AnimateAPIError.decode(
                from: data,
                fallbackCode: "animate_image_availability_failed",
                fallbackMessage: AnimateImageGenerationAccountingError.availabilityFailed.localizedDescription
            )
        }

        return try JSONDecoder().decode(AnimateImageGenerationAvailabilityResponse.self, from: data)
    }

    func startGeneration(
        sourceImageUploadId: String,
        looks: [String],
        idempotencyKey: String,
        bearerToken: String
    ) async throws -> AnimateImageGenerationStartResponse {
        guard let baseURL = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AnimateImageGenerationAccountingError.apiNotConfigured
        }

        let endpoint = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("apps")
            .appendingPathComponent("animateav")
            .appendingPathComponent("images")
            .appendingPathComponent("generations")
        let body = AnimateImageGenerationStartRequest(
            sourceImageUploadId: sourceImageUploadId,
            looks: looks,
            idempotencyKey: idempotencyKey
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
                fallbackCode: "animate_image_generation_failed",
                fallbackMessage: AnimateImageGenerationAccountingError.startFailed.localizedDescription
            )
        }

        return try JSONDecoder().decode(AnimateImageGenerationStartResponse.self, from: data)
    }

    func prepareSourceImageUpload(
        sourceLocalIdentifier: String,
        originalFilename: String,
        contentType: String,
        byteSize: Int,
        sha256: String,
        width: Int?,
        height: Int?,
        bearerToken: String
    ) async throws -> AnimateSourceImagePreparedUpload {
        guard let baseURL = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AnimateImageGenerationAccountingError.apiNotConfigured
        }

        let endpoint = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("apps")
            .appendingPathComponent("animateav")
            .appendingPathComponent("images")
            .appendingPathComponent("source-uploads")
            .appendingPathComponent("prepare")
        let body = AnimateSourceImagePrepareUploadRequest(
            sourceLocalIdentifier: sourceLocalIdentifier,
            originalFilename: originalFilename,
            contentType: contentType,
            byteSize: byteSize,
            sha256: sha256,
            width: width,
            height: height
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
                fallbackCode: "animate_source_image_prepare_failed",
                fallbackMessage: AnimateImageGenerationAccountingError.sourceUploadFailed.localizedDescription
            )
        }

        return try JSONDecoder().decode(AnimateSourceImagePreparedUpload.self, from: data)
    }

    func uploadSourceImage(
        data: Data,
        preparedUpload: AnimateSourceImagePreparedUpload
    ) async throws -> AnimateSourceImageUploadCompletion {
        guard let uploadUrl = preparedUpload.uploadUrl,
              let endpoint = URL(string: uploadUrl)
        else {
            throw AnimateImageGenerationAccountingError.sourceUploadFailed
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = preparedUpload.method
        preparedUpload.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.httpBody = data

        let (responseData, response) = try await uploadDataWithRetry(request: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw AnimateAPIError.decode(
                from: responseData,
                fallbackCode: "animate_source_image_upload_failed",
                fallbackMessage: AnimateImageGenerationAccountingError.sourceUploadFailed.localizedDescription
            )
        }

        return try JSONDecoder().decode(AnimateSourceImageUploadCompletion.self, from: responseData)
    }

    func purchasePack(
        idempotencyKey: String,
        bearerToken: String
    ) async throws -> AnimateImageGenerationPackPurchaseResponse {
        guard let baseURL = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AnimateImageGenerationAccountingError.apiNotConfigured
        }

        let endpoint = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("apps")
            .appendingPathComponent("animateav")
            .appendingPathComponent("images")
            .appendingPathComponent("packs")
            .appendingPathComponent("purchase")
        let body = AnimateImageGenerationPackPurchaseRequest(idempotencyKey: idempotencyKey)

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await retryPolicy.runData(session: session, request: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            throw AnimateAPIError.decode(
                from: data,
                fallbackCode: "animate_image_pack_purchase_failed",
                fallbackMessage: AnimateImageGenerationAccountingError.packPurchaseFailed.localizedDescription
            )
        }

        return try JSONDecoder().decode(AnimateImageGenerationPackPurchaseResponse.self, from: data)
    }

    private func uploadDataWithRetry(request: URLRequest) async throws -> (Data, URLResponse) {
        var attempt = 0

        while true {
            let (data, response) = try await retryPolicy.runData(session: session, request: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  shouldRetryUpload(statusCode: httpResponse.statusCode),
                  attempt < retryPolicy.maximumRetries
            else {
                return (data, response)
            }

            attempt += 1
            try await Task.sleep(nanoseconds: retryPolicy.delayNanoseconds(forAttempt: attempt))
        }
    }

    private func shouldRetryUpload(statusCode: Int) -> Bool {
        statusCode == 408 || statusCode == 429 || 500..<600 ~= statusCode
    }
}

struct AnimateImageGenerationStartRequest: Encodable, Equatable {
    let sourceImageUploadId: String
    let looks: [String]
    let idempotencyKey: String
}

struct AnimateSourceImagePrepareUploadRequest: Encodable, Equatable {
    let sourceLocalIdentifier: String
    let originalFilename: String
    let contentType: String
    let byteSize: Int
    let sha256: String
    let width: Int?
    let height: Int?
}

struct AnimateSourceImagePreparedUpload: Decodable, Equatable {
    let appId: String
    let sourceImageUploadId: String
    let uploadId: String
    let uploadUrl: String?
    let method: String
    let headers: [String: String]
    let expiresAt: String
    let generatedAt: String
}

struct AnimateSourceImageUploadCompletion: Decodable, Equatable {
    let appId: String
    let sourceImageUploadId: String
    let uploadId: String
    let sourceLocalIdentifier: String
    let contentType: String
    let width: Int?
    let height: Int?
    let status: String
    let uploadedAt: String
    let bytesReceived: Int
}

struct AnimateImageGenerationPackPurchaseRequest: Encodable, Equatable {
    let idempotencyKey: String
}

struct AnimateImageGenerationAvailabilityResponse: Decodable, Equatable {
    let appId: String
    let outputKind: String
    let monthlyProAllowance: AnimateImageGenerationMonthlyAllowance
    let purchasedImages: AnimateImageGenerationPurchasedImages
    let availableImages: Int
    let packOffer: AnimateImageGenerationPackOffer
}

struct AnimateImageGenerationMonthlyAllowance: Decodable, Equatable {
    let included: Bool
    let period: String
    let allowance: Int
    let used: Int
    let remaining: Int
}

struct AnimateImageGenerationPurchasedImages: Decodable, Equatable {
    let balance: Int
}

struct AnimateImageGenerationPackOffer: Decodable, Equatable {
    let enabled: Bool
    let creditCost: Int
    let imageGenerations: Int
    let userCanPurchase: Bool
    let blocker: String?
}

struct AnimateImageGenerationStartResponse: Decodable, Equatable {
    let appId: String
    let sourceImageUploadId: String
    let sourceImageLocalIdentifier: String
    let jobs: [AnimateImageGenerationStartedJob]
    let availability: AnimateImageGenerationAvailabilityResponse
    let generatedAt: String
}

struct AnimateImageGenerationStartedJob: Decodable, Equatable {
    let imageJobId: String
    let look: String
    let status: String
    let reservation: AnimateImageGenerationReservation
}

struct AnimateImageGenerationReservation: Decodable, Equatable {
    let idempotencyKey: String
    let monthlyReserved: Int
    let purchasedReserved: Int
}

struct AnimateImageGenerationPackPurchaseResponse: Decodable, Equatable {
    let appId: String
    let outputKind: String
    let monthlyProAllowance: AnimateImageGenerationMonthlyAllowance
    let purchasedImages: AnimateImageGenerationPurchasedImages
    let availableImages: Int
    let packOffer: AnimateImageGenerationPackOffer
    let purchase: AnimateImageGenerationPackPurchase

    var availability: AnimateImageGenerationAvailabilityResponse {
        AnimateImageGenerationAvailabilityResponse(
            appId: appId,
            outputKind: outputKind,
            monthlyProAllowance: monthlyProAllowance,
            purchasedImages: purchasedImages,
            availableImages: availableImages,
            packOffer: packOffer
        )
    }
}

struct AnimateImageGenerationPackPurchase: Decodable, Equatable {
    let creditReservationId: String
    let creditCost: Int
    let imageGenerationsAdded: Int
    let idempotencyKey: String
    let createdAt: String
}

enum AnimateImageGenerationAccountingError: LocalizedError {
    case apiNotConfigured
    case signInRequired
    case availabilityFailed
    case startFailed
    case sourceUploadFailed
    case packPurchaseFailed

    var errorDescription: String? {
        switch self {
        case .apiNotConfigured: "Image generation accounting is not configured for this build."
        case .signInRequired: "Sign in to load image generation balance."
        case .availabilityFailed: "Avi could not load image generation balance."
        case .startFailed: "Avi could not start image generation."
        case .sourceUploadFailed: "Avi could not upload the photo."
        case .packPurchaseFailed: "Avi could not get image generations."
        }
    }
}
