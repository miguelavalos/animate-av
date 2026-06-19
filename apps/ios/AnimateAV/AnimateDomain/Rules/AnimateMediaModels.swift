import AVMediaAnalysisFoundation
import Foundation

struct AnimateSelectedMedia: Identifiable, Equatable {
    let id: UUID
    let sourceLocalIdentifier: String
    let originalFilename: String
    let contentType: String
    let kind: String
    let byteSize: Int
    let sha256: String
    let data: Data
    let originalData: Data?
    let capturedAt: Date?
    var analysis: AVLocalMediaAnalysis? = nil
    var sortOrder: Int
    var selected: Bool

    init(
        id: UUID,
        sourceLocalIdentifier: String,
        originalFilename: String,
        contentType: String,
        kind: String,
        byteSize: Int,
        sha256: String,
        data: Data,
        originalData: Data? = nil,
        capturedAt: Date?,
        analysis: AVLocalMediaAnalysis? = nil,
        sortOrder: Int,
        selected: Bool
    ) {
        self.id = id
        self.sourceLocalIdentifier = sourceLocalIdentifier
        self.originalFilename = originalFilename
        self.contentType = contentType
        self.kind = kind
        self.byteSize = byteSize
        self.sha256 = sha256
        self.data = data
        self.originalData = originalData
        self.capturedAt = capturedAt
        self.analysis = analysis
        self.sortOrder = sortOrder
        self.selected = selected
    }

    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: Int64(byteSize), countStyle: .file)
    }

    var sourceImageDataForEditing: Data {
        originalData ?? data
    }

    var activeSourceImageData: Data {
        data
    }

    var hasFrameAdjustment: Bool {
        sourceLocalIdentifier.contains(":crop:") || (originalData != nil && originalData != data)
    }

    func updatedPhotoData(_ data: Data, sha256: String) -> AnimateSelectedMedia {
        AnimateSelectedMedia(
            id: id,
            sourceLocalIdentifier: "\(baseSourceLocalIdentifier):crop:\(sha256.prefix(12))",
            originalFilename: originalFilename,
            contentType: "image/jpeg",
            kind: kind,
            byteSize: data.count,
            sha256: sha256,
            data: data,
            originalData: originalData ?? self.data,
            capturedAt: capturedAt,
            analysis: analysis,
            sortOrder: sortOrder,
            selected: selected
        )
    }

    func restoredOriginalPhotoData(sha256: String) -> AnimateSelectedMedia {
        let restoredData = originalData ?? data
        return AnimateSelectedMedia(
            id: id,
            sourceLocalIdentifier: baseSourceLocalIdentifier,
            originalFilename: originalFilename,
            contentType: "image/jpeg",
            kind: kind,
            byteSize: restoredData.count,
            sha256: sha256,
            data: restoredData,
            originalData: restoredData,
            capturedAt: capturedAt,
            analysis: analysis,
            sortOrder: sortOrder,
            selected: selected
        )
    }

    private var baseSourceLocalIdentifier: String {
        sourceLocalIdentifier.components(separatedBy: ":crop:").first ?? sourceLocalIdentifier
    }
}

struct AnimatePreparedUpload: Decodable, Equatable, Sendable {
    let appId: String
    let videoId: String
    let mediaAssetId: String
    let uploadId: String
    let uploadUrl: URL?
    let completionUrl: URL?
    let method: String
    let headers: [String: String]
    let expiresAt: String
    let generatedAt: String
}

struct AnimateUploadCompletion: Decodable, Equatable, Sendable {
    let appId: String
    let videoId: String
    let mediaAssetId: String
    let uploadId: String
    let storageKey: String
    let status: String
    let uploadedAt: String
    let bytesReceived: Int
}

enum AnimateMediaRules {
    enum BlockReason {
        case tooFewSelected(missingCount: Int)
        case tooManySelected(extraCount: Int)
    }

    struct Availability {
        let canUseSelection: Bool
        let blockReason: BlockReason?
    }

    static func canUseSelection(template: AnimateVideoTemplate, selectedCount: Int) -> Bool {
        availability(template: template, selectedCount: selectedCount).canUseSelection
    }

    static func availability(template: AnimateVideoTemplate, selectedCount: Int) -> Availability {
        if selectedCount < template.minimumAssets {
            return Availability(
                canUseSelection: false,
                blockReason: .tooFewSelected(missingCount: template.minimumAssets - selectedCount)
            )
        }
        if selectedCount > template.maximumAssets {
            return Availability(
                canUseSelection: false,
                blockReason: .tooManySelected(extraCount: selectedCount - template.maximumAssets)
            )
        }
        return Availability(canUseSelection: true, blockReason: nil)
    }

    static func remainingSlots(template: AnimateVideoTemplate, selectedCount: Int) -> Int {
        max(template.maximumAssets - selectedCount, 0)
    }

    static func selectedCount(
        localMedia: [AnimateSelectedMedia],
        syncedMedia: [AnimateMediaAsset]
    ) -> Int {
        if localMedia.isEmpty {
            let selectedSyncedCount = syncedMedia.filter(\.selected).count
            return selectedSyncedCount > 0 ? selectedSyncedCount : syncedMedia.count
        }

        return localMedia.filter(\.selected).count
    }

    static func selectionMessage(
        _ availability: Availability,
        readyMessage: String = "Ready to continue.",
        tooFewMessage: (Int) -> String,
        tooManyMessage: (Int) -> String
    ) -> String {
        switch availability.blockReason {
        case nil:
            return readyMessage
        case .tooFewSelected(let missingCount):
            return tooFewMessage(missingCount)
        case .tooManySelected(let extraCount):
            return tooManyMessage(extraCount)
        }
    }

    static func message(template: AnimateVideoTemplate, selectedCount: Int) -> String {
        selectionMessage(
            availability(template: template, selectedCount: selectedCount),
            tooFewMessage: { "Add \($0) more." },
            tooManyMessage: { "Remove \($0)." }
        )
    }
}
