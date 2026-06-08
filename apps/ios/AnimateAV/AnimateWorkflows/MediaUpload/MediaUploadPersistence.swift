import CryptoKit
import Foundation
import UIKit

struct MediaUploadPersistenceResult {
    let savedCount: Int
    let savedMedia: [AnimateVideoDirectionMedia]
    let storageBlocked: Bool

    var statusMessage: String {
        if storageBlocked {
            return L10n.string("create.media.persistence.added", savedCount, itemWord)
        }
        return L10n.string("create.media.persistence.added", savedCount, itemWord)
    }

    private var itemWord: String {
        savedCount == 1
            ? L10n.string("media.item.singular")
            : L10n.string("media.item.plural")
    }
}

enum MediaUploadPersistence {
    private static let uploadConcurrencyLimit = 3

    private struct UploadedMedia {
        let media: AnimateSelectedMedia
        let preparedUpload: AnimatePreparedUpload
        let uploadCompletion: AnimateUploadCompletion
    }

    @MainActor
    static func save(
        imported mediaItems: [AnimateSelectedMedia],
        ownerUserId: String,
        bearerToken: String,
        momentId: String,
        uploadClient: AnimateUploadClient,
        requiresProductStateSave: Bool = true,
        progress: @MainActor @escaping (_ completedCount: Int, _ totalCount: Int) -> Void = { _, _ in },
        shouldContinue: @MainActor () -> Bool
    ) async throws -> MediaUploadPersistenceResult {
        let totalCount = mediaItems.count
        guard totalCount > 0 else {
            return MediaUploadPersistenceResult(savedCount: 0, savedMedia: [], storageBlocked: false)
        }

        var completedUploads = 0
        let uploadedMedia = try await uploadMedia(
            mediaItems,
            momentId: momentId,
            bearerToken: bearerToken,
            uploadClient: uploadClient,
            shouldContinue: shouldContinue,
            progress: { completedCount in
                completedUploads = completedCount
                progress(completedCount, totalCount)
            }
        )

        guard shouldContinue() else {
            throw CancellationError()
        }

        let savedMediaAssetIds = uploadedMedia.map(\.uploadCompletion.mediaAssetId)

        let savedMedia = zip(uploadedMedia, savedMediaAssetIds).map { uploaded, savedMediaAssetId in
            AnimateLocalMediaThumbnailCache.store(uploaded.media, mediaAssetId: savedMediaAssetId)
            return AnimateVideoDirectionMedia(
                mediaAssetId: savedMediaAssetId,
                mediaKind: uploaded.media.kind,
                sortOrder: uploaded.media.sortOrder,
                selected: uploaded.media.selected,
                moderationStatus: "pending"
            )
        }

        return MediaUploadPersistenceResult(
            savedCount: completedUploads,
            savedMedia: savedMedia,
            storageBlocked: uploadedMedia.contains { $0.preparedUpload.uploadUrl == nil }
        )
    }

    @MainActor
    private static func uploadMedia(
        _ mediaItems: [AnimateSelectedMedia],
        momentId: String,
        bearerToken: String,
        uploadClient: AnimateUploadClient,
        shouldContinue: @MainActor () -> Bool,
        progress: @MainActor @escaping (_ completedCount: Int) -> Void
    ) async throws -> [UploadedMedia] {
        var nextIndex = 0
        var completedCount = 0
        var uploadedMedia: [UploadedMedia] = []

        try await withThrowingTaskGroup(of: UploadedMedia.self) { group in
            func enqueueNextUpload() {
                guard nextIndex < mediaItems.count else { return }
                let media = mediaItems[nextIndex]
                nextIndex += 1
                group.addTask {
                    let prepared = try await uploadClient.prepareUpload(
                        momentId: momentId,
                        bearerToken: bearerToken,
                        media: media
                    )

                    let completion = try await uploadClient.upload(
                        media: media,
                        preparedUpload: prepared
                    )

                    return UploadedMedia(media: media, preparedUpload: prepared, uploadCompletion: completion)
                }
            }

            for _ in 0..<min(uploadConcurrencyLimit, mediaItems.count) {
                enqueueNextUpload()
            }

            while let uploaded = try await group.next() {
                guard shouldContinue() else {
                    group.cancelAll()
                    throw CancellationError()
                }

                completedCount += 1
                uploadedMedia.append(uploaded)
                progress(completedCount)
                enqueueNextUpload()
            }
        }

        return uploadedMedia.sorted { $0.media.sortOrder < $1.media.sortOrder }
    }
}

enum AnimateLocalMediaThumbnailCache {
    private static let thumbnailSize = CGSize(width: 320, height: 320)

    static func store(_ media: AnimateSelectedMedia, mediaAssetId: String) {
        guard let image = UIImage(data: media.data) else { return }
        store(image, mediaAssetId: mediaAssetId, platformMediaAssetId: media.sourceLocalIdentifier)
    }

    static func store(
        _ image: UIImage,
        mediaAssetId: String,
        platformMediaAssetId: String?
    ) {
        guard let data = resizedJPEGData(from: image) else { return }
        write(data, for: mediaAssetId)
        if let platformMediaAssetId, !platformMediaAssetId.isEmpty {
            write(data, for: platformMediaAssetId)
        }
    }

    static func thumbnail(mediaAssetId: String, platformMediaAssetId: String?) -> UIImage? {
        if let image = read(for: mediaAssetId) {
            return image
        }
        guard let platformMediaAssetId, !platformMediaAssetId.isEmpty else { return nil }
        return read(for: platformMediaAssetId)
    }

    static func clearAll() {
        try? FileManager.default.removeItem(at: cacheDirectory)
    }

    private static func resizedJPEGData(from image: UIImage) -> Data? {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return image.jpegData(compressionQuality: 0.72) }
        let scale = min(thumbnailSize.width / size.width, thumbnailSize.height / size.height, 1)
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let renderedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return renderedImage.jpegData(compressionQuality: 0.72)
    }

    private static func read(for key: String) -> UIImage? {
        guard let data = try? Data(contentsOf: url(for: key)) else { return nil }
        return UIImage(data: data)
    }

    private static func write(_ data: Data, for key: String) {
        do {
            try FileManager.default.createDirectory(
                at: cacheDirectory,
                withIntermediateDirectories: true
            )
            try data.write(to: url(for: key), options: .atomic)
        } catch {
            return
        }
    }

    private static func url(for key: String) -> URL {
        cacheDirectory.appendingPathComponent("\(cacheKey(for: key)).jpg")
    }

    private static var cacheDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AnimateLocalMediaThumbnails", isDirectory: true)
    }

    private static func cacheKey(for key: String) -> String {
        SHA256.hash(data: Data(key.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
