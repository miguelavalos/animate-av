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
    let capturedAt: Date?
    var analysis: AVLocalMediaAnalysis? = nil
    var sortOrder: Int
    var selected: Bool

    var displaySize: String {
        ByteCountFormatter.string(fromByteCount: Int64(byteSize), countStyle: .file)
    }
}

struct AnimatePreparedUpload: Decodable, Equatable, Sendable {
    let appId: String
    let momentId: String
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
    let momentId: String
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
