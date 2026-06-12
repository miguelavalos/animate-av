import CryptoKit
import Foundation

struct AnimateVideoDirectionMedia: Encodable {
    let mediaAssetId: String
    let mediaKind: String
    let sortOrder: Int
    let selected: Bool
    let moderationStatus: String
}

struct AnimateVideoDirectionRequest: Encodable {
    let appId = "animateav"
    let videoId: String
    let creationMode: String
    let look: String
    let theme: String
    let mood: String
    let duration: String
    let mediaUse: String
    let movementDirection: String?
    let motionDirection: String?
    let occasion: String
    let details: String
    let narrationVoice: String
    let voiceTone: String
    let media: [AnimateVideoDirectionMedia]
    let safetyAcknowledged = true
    let idempotencyKey: String
}

enum AnimateVideoDirectionInputSignature {
    static func make(
        videoId: String,
        form: AnimateVideoSetupForm,
        selectedMedia: [AnimateVideoDirectionMedia]
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
            videoId,
            form.creationMode.rawValue,
            form.look.rawValue,
            form.theme.rawValue,
            form.tone.rawValue,
            "\(form.hasMessage)",
            form.activeMessageText ?? "",
            "\(form.audioEnabled)",
            "\(form.musicEnabled)",
            "\(form.voiceEnabled)",
            form.voiceProfile.rawValue,
            form.voiceTone.rawValue,
            form.duration.rawValue,
            form.mediaUse.rawValue,
            form.movementDirection.rawValue,
            form.occasion.trimmingCharacters(in: .whitespacesAndNewlines),
            mediaSignature
        ].joined(separator: "\u{1F}")

        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

struct AnimateVideoDirectionSceneResponse: Decodable, Identifiable, Equatable {
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

struct AnimateVideoDirectionResponse: Decodable, Equatable {
    let appId: String
    let videoId: String
    let workflowRunId: String
    let status: String
    let provider: String?
    let model: String?
    let moderationStatus: String
    let errorCode: String?
    let errorMessage: String?
    let narrationVoice: String
    let helperCopy: String
    let scenes: [AnimateVideoDirectionSceneResponse]
    let generatedAt: String
}

enum AnimateVideoDirectionRules {
    enum BlockReason {
        case missingMedia
        case tooFewSelectedMedia(missingCount: Int)
        case tooManySelectedMedia(extraCount: Int)
    }

    struct Availability {
        let canPlan: Bool
        let blockReason: BlockReason?
    }

    static func canPlan(mediaAssets: [AnimateMediaAsset], template: AnimateVideoTemplate) -> Bool {
        availability(mediaAssets: mediaAssets, template: template).canPlan
    }

    static func availability(
        mediaAssets: [AnimateMediaAsset]?,
        template: AnimateVideoTemplate
    ) -> Availability {
        guard let mediaAssets else {
            return Availability(canPlan: false, blockReason: .missingMedia)
        }

        let selectedMediaCount = mediaAssets.filter(\.selected).count
        let selectedCount = selectedMediaCount > 0 ? selectedMediaCount : mediaAssets.count
        switch AnimateMediaRules.availability(template: template, selectedCount: selectedCount).blockReason {
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
            let label = missingCount == 1 ? "photo" : "photos"
            return "Add \(missingCount) more \(label) before preparing the video."
        case .tooManySelectedMedia(let extraCount):
            let label = extraCount == 1 ? "photo" : "photos"
            return "Remove \(extraCount) \(label) before preparing the video."
        }
    }
}
