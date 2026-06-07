import Foundation

struct MomentsCreditReservationResponse: Decodable, Equatable {
    let id: String
    let appId: String
    let userId: String?
    let momentId: String
    let workflowRunId: String?
    let amount: Int
    let status: String
    let idempotencyKey: String?
    let expiresAt: String
    let createdAt: String
    let updatedAt: String
}

struct MomentsStartWorkflowResponse: Decodable, Equatable {
    let appId: String
    let momentId: String
    let renderJobId: String
    let workflowRunId: String
    let status: String
    let startedAt: String
}

struct MomentsRenderPlanRequest: Encodable {
    let appId = "animateav"
    let momentId: String
    let creationMode: String
    let look: String
    let theme: String
    let mood: String
    let duration: String
    let mediaUse: String
    let selectedSourceLocalIdentifiers: [String]?
    let occasion: String?
    let details: String?
    let message: String?
    let script: String?
    let creditCost: Int?
    let removeWatermark: Bool
    let renderOptionId: String?
}

struct MomentsConfirmFinalRenderRequest: Encodable {
    let appId = "animateav"
    let momentId: String
    let creationMode: String
    let look: String
    let theme: String
    let mood: String
    let duration: String
    let mediaUse: String
    let selectedSourceLocalIdentifiers: [String]?
    let occasion: String?
    let details: String?
    let message: String?
    let script: String?
    let creditCost: Int?
    let removeWatermark: Bool
    let renderOptionId: String?
    let planId: String
    let idempotencyKey: String
}

struct MomentsConfirmFinalRenderResponse: Decodable, Equatable {
    let appId: String
    let momentId: String
    let planId: String
    let reservation: MomentsCreditReservationResponse
    let workflow: MomentsStartWorkflowResponse
    let renderPlan: MomentsRenderPlanResponse
    let confirmedAt: String
}

struct MomentsRenderPlanResponse: Decodable, Equatable {
    let appId: String
    let momentId: String
    let planId: String
    let watermark: MomentsRenderWatermarkPlan?
    let plan: MomentsRenderPlan
    let canCreateVideo: Bool
    let createVideoBlockers: [String]
    let generatedAt: String

    enum CodingKeys: String, CodingKey {
        case appId
        case momentId
        case planId
        case watermark
        case plan
        case canCreateVideo
        case createVideoBlockers
        case generatedAt
    }

    init(
        appId: String,
        momentId: String,
        planId: String,
        watermark: MomentsRenderWatermarkPlan? = nil,
        plan: MomentsRenderPlan,
        canCreateVideo: Bool,
        createVideoBlockers: [String] = [],
        generatedAt: String
    ) {
        self.appId = appId
        self.momentId = momentId
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
        momentId = try container.decode(String.self, forKey: .momentId)
        planId = try container.decode(String.self, forKey: .planId)
        watermark = try container.decodeIfPresent(MomentsRenderWatermarkPlan.self, forKey: .watermark)
        plan = try container.decode(MomentsRenderPlan.self, forKey: .plan)
        canCreateVideo = try container.decode(Bool.self, forKey: .canCreateVideo)
        createVideoBlockers = try container.decodeIfPresent([String].self, forKey: .createVideoBlockers) ?? []
        generatedAt = try container.decode(String.self, forKey: .generatedAt)
    }
}

struct MomentsRenderWatermarkPlan: Decodable, Equatable {
    let includedForPro: Bool
    let userHasWatermarkFree: Bool
    let nonProRemovalCreditCost: Int
    let selectedRemoveWatermark: Bool
    let watermarkCreditCost: Int
}

struct MomentsArtifactDownloadRequest: Encodable {
    let appId = "animateav"
    let momentId: String
    let artifactId: String
}

struct MomentsArtifactDownloadResponse: Decodable, Equatable {
    let appId: String
    let momentId: String
    let artifactId: String
    let artifactKind: String
    let downloadUrl: String
    let method: String
    let headers: [String: String]
    let r2Key: String?
    let expiresAt: String
    let generatedAt: String
}

struct MomentsRenderPlan: Decodable, Equatable {
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

enum MomentsFinalRenderRules {
    enum BlockReason {
        case missingMoment
        case insufficientCredits
        case storyNotReady
    }

    struct Availability {
        let canGenerate: Bool
        let blockReason: BlockReason?
    }

    static func canGenerate(
        moment: InProgressMoment,
        template: MomentTemplate,
        balance: MomentsCreditBalance,
        storySceneCount: Int = 0
    ) -> Bool {
        availability(
            moment: moment,
            template: template,
            balance: balance,
            storySceneCount: storySceneCount
        ).canGenerate
    }

    static func canPreparePlan(moment: InProgressMoment?, storySceneCount: Int = 0) -> Bool {
        if storySceneCount > 0 { return true }
        guard let moment else { return false }
        return moment.status == "story_ready"
            || moment.status == "gallery_ready"
    }

    static func availability(
        moment: InProgressMoment?,
        template: MomentTemplate,
        balance: MomentsCreditBalance,
        storySceneCount: Int = 0
    ) -> Availability {
        guard let moment else {
            return Availability(canGenerate: false, blockReason: .missingMoment)
        }
        if !canPreparePlan(moment: moment, storySceneCount: storySceneCount) {
            return Availability(canGenerate: false, blockReason: .storyNotReady)
        }
        if !MomentsCreditGate.canAfford(template, balance: balance) {
            return Availability(canGenerate: false, blockReason: .insufficientCredits)
        }
        return Availability(canGenerate: true, blockReason: nil)
    }

    static func availabilityMessage(
        _ availability: Availability,
        missingMomentMessage: String,
        insufficientCreditsMessage: String
    ) -> String? {
        switch availability.blockReason {
        case nil:
            return nil
        case .missingMoment:
            return missingMomentMessage
        case .insufficientCredits:
            return insufficientCreditsMessage
        case .storyNotReady:
            return "Prepare the video before creating the final video."
        }
    }
}
