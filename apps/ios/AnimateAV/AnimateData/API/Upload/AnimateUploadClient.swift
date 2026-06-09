import Foundation
import OSLog

struct AnimateUploadClient: Sendable {
    var baseURLString: String
    var session: URLSession = .shared
    var uploadRetryPolicy = AnimateUploadRetryPolicy()
    var networkRetryPolicy = AnimateNetworkRetryPolicy()
    private let logger = Logger(subsystem: "com.avalsys.animateav", category: "upload-client")

    var isConfigured: Bool {
        URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
    }

    func prepareUpload(momentId: String, bearerToken: String, media: AnimateSelectedMedia) async throws -> AnimatePreparedUpload {
        guard let baseURL = URL(string: baseURLString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AnimateUploadError.apiNotConfigured
        }

        let endpoint = baseURL
            .appendingPathComponent("v1")
            .appendingPathComponent("apps")
            .appendingPathComponent("animateav")
            .appendingPathComponent("media")
            .appendingPathComponent("prepare-upload")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(AnimatePrepareUploadRequest(momentId: momentId, media: media))

        let (data, response) = try await retryingData(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            logger.error("prepare-upload failed status=\(statusCode, privacy: .public)")
            throw AnimateAPIError.decode(
                from: data,
                fallbackCode: "moments_upload_prepare_failed",
                fallbackMessage: AnimateUploadError.prepareFailed.localizedDescription
            )
        }

        do {
            let preparedUpload = try JSONDecoder().decode(AnimatePreparedUpload.self, from: data)
            logger.info("prepare-upload succeeded direct=\(preparedUpload.completionUrl != nil, privacy: .public)")
            return preparedUpload
        } catch {
            logger.error("prepare-upload decode failed error=\(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    func upload(media: AnimateSelectedMedia, preparedUpload: AnimatePreparedUpload) async throws -> AnimateUploadCompletion {
        guard let uploadURL = preparedUpload.uploadUrl else {
            throw AnimateUploadError.signedUploadUnavailable
        }

        var request = URLRequest(url: uploadURL)
        request.httpMethod = preparedUpload.method
        request.timeoutInterval = 45
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.networkServiceType = .responsiveData
        preparedUpload.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        request.setValue(preparedUpload.momentId, forHTTPHeaderField: "x-appsav-animate-moment-id")
        request.setValue(String(media.sortOrder), forHTTPHeaderField: "x-appsav-videos-sort-order")
        request.setValue(media.selected ? "true" : "false", forHTTPHeaderField: "x-appsav-videos-selected")

        if let completionUrl = preparedUpload.completionUrl {
            _ = try await uploadWithRetry(request: request, data: media.data)
            logger.info("direct upload put succeeded uploadId=\(preparedUpload.uploadId, privacy: .public)")
            return try await completeUpload(uploadId: preparedUpload.uploadId, completionUrl: completionUrl, media: media)
        }

        let uploadResponseData = try await uploadWithRetry(request: request, data: media.data)
        do {
            let completion = try JSONDecoder().decode(AnimateUploadCompletion.self, from: uploadResponseData)
            logger.info("api upload completed uploadId=\(completion.uploadId, privacy: .public)")
            return completion
        } catch {
            logger.error("api upload completion decode failed error=\(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    private func completeUpload(uploadId: String, completionUrl: URL, media: AnimateSelectedMedia) async throws -> AnimateUploadCompletion {
        var request = URLRequest(url: completionUrl)
        request.httpMethod = "POST"
        request.timeoutInterval = 20
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(AnimateUploadCompletionIntent(media: media))

        let (data, response) = try await retryingData(for: request)
        guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            logger.error("direct upload complete failed uploadId=\(uploadId, privacy: .public) status=\(statusCode, privacy: .public)")
            throw AnimateAPIError.decode(
                from: data,
                fallbackCode: "moments_upload_complete_failed",
                fallbackMessage: AnimateUploadError.uploadFailed.localizedDescription
            )
        }

        do {
            let completion = try JSONDecoder().decode(AnimateUploadCompletion.self, from: data)
            logger.info("direct upload completed uploadId=\(uploadId, privacy: .public)")
            return completion
        } catch {
            logger.error("direct upload completion decode failed uploadId=\(uploadId, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            throw error
        }
    }

    private func uploadWithRetry(request: URLRequest, data: Data) async throws -> Data {
        var attempt = 0

        while true {
            do {
                let (responseData, response) = try await session.upload(for: request, from: data)
                guard let httpResponse = response as? HTTPURLResponse, 200..<300 ~= httpResponse.statusCode else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                    logger.error("upload request failed status=\(statusCode, privacy: .public) attempt=\(attempt, privacy: .public)")
                    if shouldRetryUpload(statusCode: statusCode, attempt: attempt) {
                        attempt += 1
                        try await Task.sleep(nanoseconds: uploadRetryPolicy.delayNanoseconds(forAttempt: attempt))
                        continue
                    }
                    throw AnimateAPIError.decode(
                        from: responseData,
                        fallbackCode: "moments_upload_failed",
                        fallbackMessage: AnimateUploadError.uploadFailed.localizedDescription
                    )
                }
                return responseData
            } catch {
                guard uploadRetryPolicy.shouldRetry(error: error, attempt: attempt) else {
                    throw error
                }

                attempt += 1
                try await Task.sleep(nanoseconds: uploadRetryPolicy.delayNanoseconds(forAttempt: attempt))
            }
        }
    }

    private func retryingData(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await networkRetryPolicy.runData(session: session, request: request)
    }

    private func shouldRetryUpload(statusCode: Int, attempt: Int) -> Bool {
        guard attempt < uploadRetryPolicy.maximumRetries else { return false }
        return statusCode == 408 || statusCode == 429 || 500..<600 ~= statusCode
    }
}

private struct AnimateUploadCompletionIntent: Encodable {
    let sortOrder: Int
    let selected: Bool

    init(media: AnimateSelectedMedia) {
        sortOrder = media.sortOrder
        selected = media.selected
    }
}

struct AnimateUploadRetryPolicy: Sendable {
    var maximumRetries = 3
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
}

private struct AnimatePrepareUploadRequest: Encodable {
    let appId = "animateav"
    let momentId: String
    let mediaKind: String
    let sourceLocalIdentifier: String
    let originalFilename: String
    let contentType: String
    let byteSize: Int
    let sha256: String

    init(momentId: String, media: AnimateSelectedMedia) {
        self.momentId = momentId
        mediaKind = media.kind
        sourceLocalIdentifier = media.sourceLocalIdentifier
        originalFilename = media.originalFilename
        contentType = media.contentType
        byteSize = media.byteSize
        sha256 = media.sha256
    }
}

enum AnimateUploadError: LocalizedError {
    case unreadableSelection
    case apiNotConfigured
    case prepareFailed
    case signedUploadUnavailable
    case uploadFailed
    case photoLibraryAccessDenied

    var errorDescription: String? {
        switch self {
        case .unreadableSelection: "The selected item could not be read."
        case .apiNotConfigured: "Media upload preparation is not configured for this build."
        case .prepareFailed: "Upload preparation failed."
        case .signedUploadUnavailable: "Signed upload storage is not enabled for this build."
        case .uploadFailed: "Media upload failed."
        case .photoLibraryAccessDenied: "Allow Photos access to import recent photos."
        }
    }
}
