import AVMediaAnalysisFoundation
import CryptoKit
import Foundation
import ImageIO
import Photos
import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

enum MediaPickerImport {
    private static let analyzer = AVVisionLocalMediaAnalyzer()

    struct PhotoAlbum: Identifiable, Equatable {
        let id: String
        let title: String
        let assetCount: Int
        let coverData: Data?
    }

    static func load(
        items: [PhotosPickerItem],
        limit: Int,
        startingSortOrder: Int,
        progress: (@MainActor (Int, Int) -> Void)? = nil
    ) async throws -> [MomentsSelectedMedia] {
        var imported: [MomentsSelectedMedia] = []
        let total = min(items.count, limit)

        for (offset, item) in items.prefix(limit).enumerated() {
            let media = try await loadMedia(
                from: item,
                sortOrder: startingSortOrder + offset
            )
            imported.append(media)
            await progress?(imported.count, total)
        }

        return imported
    }

    static func loadLatestPhotos(
        limit: Int,
        startingSortOrder: Int,
        progress: (@MainActor (Int, Int) -> Void)? = nil
    ) async throws -> [MomentsSelectedMedia] {
        guard limit > 0 else { return [] }
        let status = await requestPhotoLibraryAccess()
        guard status == .authorized || status == .limited else {
            throw MomentsUploadError.photoLibraryAccessDenied
        }

        let options = PHFetchOptions()
        options.fetchLimit = limit
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false),
            NSSortDescriptor(key: "modificationDate", ascending: false)
        ]

        let assets = PHAsset.fetchAssets(with: options)
        var imported: [MomentsSelectedMedia] = []

        for index in 0..<assets.count {
            let media = try await loadPhotoAsset(
                assets.object(at: index),
                sortOrder: startingSortOrder + index
            )
            imported.append(media)
            await progress?(imported.count, assets.count)
        }

        return imported
    }

    static func loadPhotoAlbums() async throws -> [PhotoAlbum] {
        let status = await requestPhotoLibraryAccess()
        guard status == .authorized || status == .limited else {
            throw MomentsUploadError.photoLibraryAccessDenied
        }

        let smartAlbums = albums(
            from: PHAssetCollection.fetchAssetCollections(
                with: .smartAlbum,
                subtype: .any,
                options: nil
            )
        )
        let userAlbums = albums(
            from: PHAssetCollection.fetchAssetCollections(
                with: .album,
                subtype: .any,
                options: nil
            )
        )
        let albums = (smartAlbums + userAlbums).reduce(into: [PhotoAlbum]()) { uniqueAlbums, album in
            guard !uniqueAlbums.contains(where: { $0.id == album.id }) else { return }
            uniqueAlbums.append(album)
        }

        return albums.sorted {
            if $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedSame {
                return $0.id < $1.id
            }
            return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    static func loadPhotoAlbum(
        id albumId: String,
        limit: Int,
        startingSortOrder: Int,
        progress: (@MainActor (Int, Int) -> Void)? = nil
    ) async throws -> [MomentsSelectedMedia] {
        guard limit > 0 else { return [] }
        let status = await requestPhotoLibraryAccess()
        guard status == .authorized || status == .limited else {
            throw MomentsUploadError.photoLibraryAccessDenied
        }
        guard let collection = PHAssetCollection
            .fetchAssetCollections(withLocalIdentifiers: [albumId], options: nil)
            .firstObject else {
            return []
        }

        let options = photoFetchOptions()
        options.fetchLimit = limit
        let assets = PHAsset.fetchAssets(in: collection, options: options)
        var imported: [MomentsSelectedMedia] = []

        for index in 0..<assets.count {
            let media = try await loadPhotoAsset(
                assets.object(at: index),
                sortOrder: startingSortOrder + index
            )
            imported.append(media)
            await progress?(imported.count, assets.count)
        }

        return imported
    }

    static func loadLocalMediaAssets(
        _ mediaAssets: [MomentMediaAsset],
        progress: (@MainActor (Int, Int) -> Void)? = nil
    ) async throws -> [MomentsSelectedMedia] {
        let status = await requestPhotoLibraryAccess()
        guard status == .authorized || status == .limited else {
            throw MomentsUploadError.photoLibraryAccessDenied
        }

        let candidates = mediaAssets
            .filter(\.selected)
            .sorted { $0.sortOrder < $1.sortOrder }
            .compactMap { media -> (asset: PHAsset, source: MomentMediaAsset)? in
                guard let localIdentifier = media.platformMediaAssetId else { return nil }
                guard let asset = PHAsset
                    .fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil)
                    .firstObject else { return nil }
                guard asset.mediaType == .image || asset.mediaType == .video else { return nil }
                return (asset, media)
            }

        var imported: [MomentsSelectedMedia] = []
        imported.reserveCapacity(candidates.count)
        await progress?(0, candidates.count)

        for (index, candidate) in candidates.enumerated() {
            let media = try await loadLibraryAsset(candidate.asset, sortOrder: Int(candidate.source.sortOrder))
            if let image = UIImage(data: media.data) {
                MomentsLocalMediaThumbnailCache.store(
                    image,
                    mediaAssetId: candidate.source.id,
                    platformMediaAssetId: candidate.source.platformMediaAssetId
                )
            }
            imported.append(media)
            await progress?(index + 1, candidates.count)
        }

        return imported
    }

    private static func loadMedia(from item: PhotosPickerItem, sortOrder: Int) async throws -> MomentsSelectedMedia {
        guard let data = try await item.loadTransferable(type: Data.self) else {
            throw MomentsUploadError.unreadableSelection
        }

        let kind = item.supportedContentTypes.contains(where: { $0.conforms(to: .movie) }) ? "video" : "photo"
        let originalFilename = originalFilename(for: photoAsset(for: item), fallbackKind: kind)
        let normalized = try normalizedMediaData(data: data, filename: originalFilename, kind: kind)
        let digest = SHA256.hash(data: normalized.data)
            .map { String(format: "%02x", $0) }
            .joined()

        let asset = photoAsset(for: item)
        let capturedAt = capturedDate(fromImageData: data) ?? asset?.creationDate
        let pixelSize = imagePixelSize(fromImageData: normalized.data) ?? imagePixelSize(fromImageData: data)
        let analysis = await analyzer.analyze(
            AVLocalMediaInput(
                data: normalized.data,
                filename: normalized.filename,
                contentType: normalized.contentType,
                kind: kind == "video" ? .video : .photo,
                capturedAt: capturedAt,
                pixelWidth: pixelSize?.width,
                pixelHeight: pixelSize?.height
            )
        )

        return MomentsSelectedMedia(
            id: UUID(),
            sourceLocalIdentifier: item.itemIdentifier ?? UUID().uuidString,
            originalFilename: normalized.filename,
            contentType: normalized.contentType,
            kind: kind,
            byteSize: normalized.data.count,
            sha256: digest,
            data: normalized.data,
            capturedAt: capturedAt,
            analysis: analysis,
            sortOrder: sortOrder,
            selected: true
        )
    }

    private static func photoAsset(for item: PhotosPickerItem) -> PHAsset? {
        guard let identifier = item.itemIdentifier else { return nil }

        return PHAsset
            .fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            .firstObject
    }

    private static func originalFilename(for asset: PHAsset?, fallbackKind: String) -> String {
        guard let asset,
              let filename = PHAssetResource.assetResources(for: asset).first?.originalFilename,
              !filename.isEmpty else {
            return "\(UUID().uuidString).\(fallbackKind == "video" ? "mov" : "jpg")"
        }

        return filename
    }

    private static func requestPhotoLibraryAccess() async -> PHAuthorizationStatus {
        let current = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard current == .notDetermined else { return current }
        return await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    private static func photoCount(in collection: PHAssetCollection) -> Int {
        PHAsset.fetchAssets(in: collection, options: photoFetchOptions()).count
    }

    private static func albums(from collections: PHFetchResult<PHAssetCollection>) -> [PhotoAlbum] {
        var albums: [PhotoAlbum] = []
        collections.enumerateObjects { collection, _, _ in
            let count = photoCount(in: collection)
            guard count > 0,
                  let title = collection.localizedTitle,
                  !title.isEmpty else { return }
            albums.append(
                PhotoAlbum(
                    id: collection.localIdentifier,
                    title: title,
                    assetCount: count,
                    coverData: coverData(in: collection)
                )
            )
        }
        return albums
    }

    private static func coverData(in collection: PHAssetCollection) -> Data? {
        let options = photoFetchOptions()
        options.fetchLimit = 1
        guard let asset = PHAsset.fetchAssets(in: collection, options: options).firstObject else {
            return nil
        }

        let requestOptions = PHImageRequestOptions()
        requestOptions.isNetworkAccessAllowed = true
        requestOptions.deliveryMode = .opportunistic
        requestOptions.resizeMode = .fast
        requestOptions.isSynchronous = true

        var imageData: Data?
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 160, height: 160),
            contentMode: .aspectFill,
            options: requestOptions
        ) { image, _ in
            imageData = image?.jpegData(compressionQuality: 0.72)
        }
        return imageData
    }

    private static func photoFetchOptions() -> PHFetchOptions {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: true),
            NSSortDescriptor(key: "modificationDate", ascending: true)
        ]
        return options
    }

    private static func loadPhotoAsset(_ asset: PHAsset, sortOrder: Int) async throws -> MomentsSelectedMedia {
        let (sourceData, sourceFilename) = try await imageData(for: asset)
        let normalized = try normalizedPhotoData(data: sourceData, filename: sourceFilename)
        let digest = SHA256.hash(data: normalized.data)
            .map { String(format: "%02x", $0) }
            .joined()
        let capturedAt = capturedDate(fromImageData: sourceData) ?? asset.creationDate
        let analysis = await analyzer.analyze(
            AVLocalMediaInput(
                data: normalized.data,
                filename: normalized.filename,
                contentType: normalized.contentType,
                kind: .photo,
                capturedAt: capturedAt,
                pixelWidth: asset.pixelWidth,
                pixelHeight: asset.pixelHeight
            )
        )

        return MomentsSelectedMedia(
            id: UUID(),
            sourceLocalIdentifier: asset.localIdentifier,
            originalFilename: normalized.filename,
            contentType: normalized.contentType,
            kind: "photo",
            byteSize: normalized.data.count,
            sha256: digest,
            data: normalized.data,
            capturedAt: capturedAt,
            analysis: analysis,
            sortOrder: sortOrder,
            selected: true
        )
    }

    private static func loadLibraryAsset(_ asset: PHAsset, sortOrder: Int) async throws -> MomentsSelectedMedia {
        switch asset.mediaType {
        case .image:
            return try await loadPhotoAsset(asset, sortOrder: sortOrder)
        case .video:
            return try await loadVideoAsset(asset, sortOrder: sortOrder)
        default:
            throw MomentsUploadError.unreadableSelection
        }
    }

    private static func loadVideoAsset(_ asset: PHAsset, sortOrder: Int) async throws -> MomentsSelectedMedia {
        let (data, filename) = try await videoData(for: asset)
        let contentType = contentType(for: filename) ?? "video/quicktime"
        let digest = SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
        let analysis = await analyzer.analyze(
            AVLocalMediaInput(
                data: data,
                filename: filename,
                contentType: contentType,
                kind: .video,
                capturedAt: asset.creationDate,
                pixelWidth: asset.pixelWidth,
                pixelHeight: asset.pixelHeight
            )
        )

        return MomentsSelectedMedia(
            id: UUID(),
            sourceLocalIdentifier: asset.localIdentifier,
            originalFilename: filename,
            contentType: contentType,
            kind: "video",
            byteSize: data.count,
            sha256: digest,
            data: data,
            capturedAt: asset.creationDate,
            analysis: analysis,
            sortOrder: sortOrder,
            selected: true
        )
    }

    private static func imageData(for asset: PHAsset) async throws -> (Data, String) {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.version = .current
        options.deliveryMode = .highQualityFormat

        return try await withCheckedThrowingContinuation { continuation in
            PHImageManager.default().requestImageDataAndOrientation(
                for: asset,
                options: options
            ) { data, _, _, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let data else {
                    continuation.resume(throwing: MomentsUploadError.unreadableSelection)
                    return
                }

                continuation.resume(returning: (data, originalFilename(for: asset, fallbackKind: "photo")))
            }
        }
    }

    private static func videoData(for asset: PHAsset) async throws -> (Data, String) {
        guard let resource = PHAssetResource.assetResources(for: asset)
            .first(where: { $0.type == .video || $0.type == .fullSizeVideo }) else {
            throw MomentsUploadError.unreadableSelection
        }
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true

        return try await withCheckedThrowingContinuation { continuation in
            var data = Data()
            PHAssetResourceManager.default().requestData(
                for: resource,
                options: options,
                dataReceivedHandler: { chunk in
                    data.append(chunk)
                },
                completionHandler: { error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume(returning: (data, resource.originalFilename))
                }
            )
        }
    }

    private static func contentType(for filename: String) -> String? {
        let ext = (filename as NSString).pathExtension
        guard !ext.isEmpty else { return nil }
        return UTType(filenameExtension: ext)?.preferredMIMEType
    }

    private static func normalizedMediaData(
        data: Data,
        filename: String,
        kind: String
    ) throws -> (data: Data, filename: String, contentType: String) {
        if kind == "photo" {
            return try normalizedPhotoData(data: data, filename: filename)
        }
        return (data, filename, contentType(for: filename) ?? "video/quicktime")
    }

    private static func normalizedPhotoData(
        data: Data,
        filename: String
    ) throws -> (data: Data, filename: String, contentType: String) {
        guard let image = UIImage(data: data),
              let jpegData = image.jpegData(compressionQuality: 0.92) else {
            throw MomentsUploadError.unreadableSelection
        }
        return (jpegData, jpegFilename(from: filename), "image/jpeg")
    }

    private static func jpegFilename(from filename: String) -> String {
        let base = (filename as NSString).deletingPathExtension
        let safeBase = base.isEmpty ? UUID().uuidString : base
        return "\(safeBase).jpg"
    }

    private static func capturedDate(fromImageData data: Data) -> Date? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return nil
        }

        let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any]
        let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any]

        let candidates = [
            exif?[kCGImagePropertyExifDateTimeOriginal] as? String,
            exif?[kCGImagePropertyExifDateTimeDigitized] as? String,
            tiff?[kCGImagePropertyTIFFDateTime] as? String
        ]

        for candidate in candidates.compactMap({ $0 }) {
            if let date = exifDateFormatter.date(from: candidate) {
                return date
            }
        }

        return nil
    }

    private static func imagePixelSize(fromImageData data: Data) -> (width: Int, height: Int)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return nil
        }

        return (width, height)
    }

    private static let exifDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter
    }()
}
