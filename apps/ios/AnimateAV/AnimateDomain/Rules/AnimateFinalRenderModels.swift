import Foundation

struct AnimateCreditReservationResponse: Decodable, Equatable {
    let id: String
    let appId: String
    let userId: String?
    let videoId: String
    let workflowRunId: String?
    let amount: Int
    let status: String
    let idempotencyKey: String?
    let expiresAt: String
    let createdAt: String
    let updatedAt: String
}

struct AnimateStartWorkflowResponse: Decodable, Equatable {
    let appId: String
    let videoId: String
    let renderJobId: String
    let workflowRunId: String
    let status: String
    let startedAt: String
}

struct AnimateRenderPlanRequest: Encodable {
    let appId = "animateav"
    let videoId: String
    let creationMode: String
    let look: String
    let theme: String
    let mood: String
    let duration: String
    let mediaUse: String
    let selectedSourceLocalIdentifiers: [String]?
    let sourceImageUploadId: String?
    let generatedImageArtifactId: String?
    let occasion: String?
    let details: String?
    let message: String?
    let script: String?
    let narrationVoice: String?
    let voiceTone: String?
    let creditCost: Int?
    let removeWatermark: Bool
    let renderOptionId: String?
}

struct AnimateConfirmFinalRenderRequest: Encodable {
    let appId = "animateav"
    let videoId: String
    let creationMode: String
    let look: String
    let theme: String
    let mood: String
    let duration: String
    let mediaUse: String
    let selectedSourceLocalIdentifiers: [String]?
    let sourceImageUploadId: String?
    let generatedImageArtifactId: String?
    let occasion: String?
    let details: String?
    let message: String?
    let script: String?
    let narrationVoice: String?
    let voiceTone: String?
    let creditCost: Int?
    let removeWatermark: Bool
    let renderOptionId: String?
    let planId: String
    let idempotencyKey: String
}

struct AnimateConfirmFinalRenderResponse: Decodable, Equatable {
    let appId: String
    let videoId: String
    let planId: String
    let reservation: AnimateCreditReservationResponse
    let workflow: AnimateStartWorkflowResponse
    let renderPlan: AnimateRenderPlanResponse
    let confirmedAt: String
}

struct AnimateRenderPlanResponse: Decodable, Equatable {
    let appId: String
    let videoId: String
    let planId: String
    let watermark: AnimateRenderWatermarkPlan?
    let plan: AnimateRenderPlan
    let canCreateVideo: Bool
    let createVideoBlockers: [String]
    let generatedAt: String

    enum CodingKeys: String, CodingKey {
        case appId
        case videoId
        case planId
        case watermark
        case plan
        case canCreateVideo
        case createVideoBlockers
        case generatedAt
    }

    init(
        appId: String,
        videoId: String,
        planId: String,
        watermark: AnimateRenderWatermarkPlan? = nil,
        plan: AnimateRenderPlan,
        canCreateVideo: Bool,
        createVideoBlockers: [String] = [],
        generatedAt: String
    ) {
        self.appId = appId
        self.videoId = videoId
        self.planId = planId
        self.watermark = watermark
        self.plan = plan
        self.canCreateVideo = canCreateVideo
        self.createVideoBlockers = createVideoBlockers
        self.generatedAt = generatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appId = try container.decode(String.self, forKey: .appId)
        videoId = try container.decode(String.self, forKey: .videoId)
        planId = try container.decode(String.self, forKey: .planId)
        watermark = try container.decodeIfPresent(AnimateRenderWatermarkPlan.self, forKey: .watermark)
        plan = try container.decode(AnimateRenderPlan.self, forKey: .plan)
        canCreateVideo = try container.decode(Bool.self, forKey: .canCreateVideo)
        createVideoBlockers = try container.decodeIfPresent([String].self, forKey: .createVideoBlockers) ?? []
        generatedAt = try container.decode(String.self, forKey: .generatedAt)
    }
}

struct AnimateRenderWatermarkPlan: Decodable, Equatable {
    let includedForPro: Bool
    let userHasWatermarkFree: Bool
    let nonProRemovalCreditCost: Int
    let selectedRemoveWatermark: Bool
    let watermarkCreditCost: Int
}

struct AnimateArtifactDownloadRequest: Encodable {
    let appId = "animateav"
    let videoId: String
    let artifactId: String
}

struct AnimateArtifactDownloadResponse: Decodable, Equatable {
    let appId: String
    let videoId: String?
    let artifactId: String
    let artifactKind: String
    let downloadUrl: String
    let method: String
    let headers: [String: String]
    let r2Key: String?
    let expiresAt: String
    let generatedAt: String
}

struct AnimateRenderPlan: Decodable, Equatable {
    let schemaVersion: Int?
    let minimumDurationMs: Int?
    let targetDurationMs: Int
    let creditCost: Int
    let totalCreditCost: Int
    let secondsPerCredit: Int
    let plannedAssetCount: Int
    let usedAssetCount: Int
    let rejectedAssetCount: Int
    let rendererMode: String
    let renderOptionId: String?
    let renderOptionTitle: String?
    let userMessage: String
    let qualityWarnings: [String]
}

enum AnimateFinalRenderRules {
    enum BlockReason {
        case missingVideo
        case insufficientCredits
        case storyNotReady
    }

    struct Availability {
        let canGenerate: Bool
        let blockReason: BlockReason?
    }

    static func canGenerate(
        video: AnimateVideo,
        template: AnimateVideoTemplate,
        balance: AnimateCreditBalance,
        storySceneCount: Int = 0
    ) -> Bool {
        availability(
            video: video,
            template: template,
            balance: balance,
            storySceneCount: storySceneCount
        ).canGenerate
    }

    static func canPreparePlan(video: AnimateVideo?, storySceneCount: Int = 0) -> Bool {
        if storySceneCount > 0 { return true }
        guard let video else { return false }
        return video.status == "story_ready"
            || video.status == "gallery_ready"
    }

    static func availability(
        video: AnimateVideo?,
        template: AnimateVideoTemplate,
        balance: AnimateCreditBalance,
        storySceneCount: Int = 0
    ) -> Availability {
        guard let video else {
            return Availability(canGenerate: false, blockReason: .missingVideo)
        }
        if !canPreparePlan(video: video, storySceneCount: storySceneCount) {
            return Availability(canGenerate: false, blockReason: .storyNotReady)
        }
        if !AnimateCreditGate.canAfford(template, balance: balance) {
            return Availability(canGenerate: false, blockReason: .insufficientCredits)
        }
        return Availability(canGenerate: true, blockReason: nil)
    }

    static func availabilityMessage(
        _ availability: Availability,
        missingVideoMessage: String,
        insufficientCreditsMessage: String
    ) -> String? {
        switch availability.blockReason {
        case nil:
            return nil
        case .missingVideo:
            return missingVideoMessage
        case .insufficientCredits:
            return insufficientCreditsMessage
        case .storyNotReady:
            return "Prepare the video before creating the final video."
        }
    }
}
