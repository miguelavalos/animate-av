import CryptoKit
import Foundation

struct MomentsStoryMedia: Encodable {
    let mediaAssetId: String
    let mediaKind: String
    let sortOrder: Int
    let selected: Bool
    let moderationStatus: String
}

struct MomentsStoryRequest: Encodable {
    let appId = "animateav"
    let momentId: String
    let creationMode: String
    let look: String
    let theme: String
    let mood: String
    let duration: String
    let mediaUse: String
    let occasion: String
    let details: String
    let narrationVoice = "avi_clear"
    let media: [MomentsStoryMedia]
    let safetyAcknowledged = true
    let idempotencyKey: String
}

enum MomentsStoryInputSignature {
    static func make(
        momentId: String,
        form: MomentSetupForm,
        selectedMedia: [MomentsStoryMedia]
    ) -> String {
        let mediaSignature = selectedMedia
            .filter(\.selected)
            .sorted { left, right in
                if left.sortOrder == right.sortOrder {
                    return left.mediaAssetId < right.mediaAssetId
                }
                return left.sortOrder < right.sortOrder
            }
            .map { "\($0.sortOrder):\($0.mediaAssetId):\($0.mediaKind)" }
            .joined(separator: "|")

        let input = [
            momentId,
            form.creationMode.rawValue,
            form.look.rawValue,
            form.theme.rawValue,
            form.tone.rawValue,
            form.duration.rawValue,
            form.mediaUse.rawValue,
            form.occasion.trimmingCharacters(in: .whitespacesAndNewlines),
            form.details.trimmingCharacters(in: .whitespacesAndNewlines),
            mediaSignature
        ].joined(separator: "\u{1F}")

        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

struct MomentsStorySceneResponse: Decodable, Identifiable, Equatable {
    var id: Int { sceneIndex }
    let sceneIndex: Int
    let mediaAssetIds: [String]
    let caption: String
    let narrationText: String
    let mood: String?
    let tone: String?
    let musicCue: String?
    let durationMs: Int
    let createdBy: String
    let editable: Bool
}

struct MomentsStoryResponse: Decodable, Equatable {
    let appId: String
    let momentId: String
    let workflowRunId: String
    let status: String
    let provider: String?
    let model: String?
    let moderationStatus: String
    let errorCode: String?
    let errorMessage: String?
    let narrationVoice: String
    let helperCopy: String
    let scenes: [MomentsStorySceneResponse]
    let generatedAt: String
}

enum MomentsStoryRules {
    enum BlockReason {
        case missingMedia
        case tooFewSelectedMedia(missingCount: Int)
        case tooManySelectedMedia(extraCount: Int)
    }

    struct Availability {
        let canPlan: Bool
        let blockReason: BlockReason?
    }

    static func canPlan(mediaAssets: [MomentMediaAsset], template: MomentTemplate) -> Bool {
        availability(mediaAssets: mediaAssets, template: template).canPlan
    }

    static func availability(
        mediaAssets: [MomentMediaAsset]?,
        template: MomentTemplate
    ) -> Availability {
        guard let mediaAssets else {
            return Availability(canPlan: false, blockReason: .missingMedia)
        }

        let selectedMediaCount = mediaAssets.filter(\.selected).count
        let selectedCount = selectedMediaCount > 0 ? selectedMediaCount : mediaAssets.count
        switch MomentsMediaRules.availability(template: template, selectedCount: selectedCount).blockReason {
        case nil:
            return Availability(canPlan: true, blockReason: nil)
        case .tooFewSelected(let missingCount):
            return Availability(
                canPlan: false,
                blockReason: .tooFewSelectedMedia(missingCount: missingCount)
            )
        case .tooManySelected(let extraCount):
            return Availability(
                canPlan: false,
                blockReason: .tooManySelectedMedia(extraCount: extraCount)
            )
        }
    }

    static func availabilityMessage(_ availability: Availability, missingMediaMessage: String) -> String? {
        switch availability.blockReason {
        case nil:
            return nil
        case .missingMedia:
            return missingMediaMessage
        case .tooFewSelectedMedia(let missingCount):
            let label = missingCount == 1 ? "source image" : "source images"
            return "Add \(missingCount) more \(label) before preparing the video."
        case .tooManySelectedMedia(let extraCount):
            let label = extraCount == 1 ? "source image" : "source images"
            return "Remove \(extraCount) \(label) before preparing the video."
        }
    }
}
