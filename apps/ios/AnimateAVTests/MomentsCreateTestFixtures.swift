import Foundation
@testable import AnimateAV

enum MomentsCreateTestFixtures {
    static func makeMoment(
        id: String,
        template: MomentTemplateID = .birthdayMessage,
        creationMode: String = "quick",
        look: String = "cartoon",
        theme: String = "celebration",
        mood: String? = nil,
        duration: String = "short",
        mediaUse: String = "aviPick",
        status: String = "in_progress",
        occasion: String? = nil,
        details: String? = nil,
        storyInputSignature: String? = nil
    ) -> InProgressMoment {
        InProgressMoment(
            id: id,
            template: template,
            creationMode: creationMode,
            look: look,
            theme: theme,
            mood: mood,
            duration: duration,
            mediaUse: mediaUse,
            status: status,
            title: "Family Weekend",
            tone: nil,
            tempo: nil,
            occasion: occasion,
            details: details,
            storyInputSignature: storyInputSignature,
            durationSeconds: 5,
            creditCost: 1,
            updatedAt: 10
        )
    }

    static func makeMediaAsset(
        id: String,
        sortOrder: Double = 0,
        sourceLocalIdentifier: String? = nil
    ) -> MomentMediaAsset {
        MomentMediaAsset(
            id: id,
            platformMediaAssetId: sourceLocalIdentifier ?? "platform-\(id)",
            uploadId: "upload-\(id)",
            kind: "image",
            sortOrder: sortOrder,
            selected: true,
            moderationStatus: "approved",
            uploadedAt: nil,
            sourceExpiresAt: nil
        )
    }

    static func makeSelectedMedia(
        id: String,
        sourceLocalIdentifier: String? = nil,
        sha256: String? = nil
    ) -> MomentsSelectedMedia {
        MomentsSelectedMedia(
            id: UUID(uuidString: id)!,
            sourceLocalIdentifier: sourceLocalIdentifier ?? id,
            originalFilename: "\(id).jpg",
            contentType: "image/jpeg",
            kind: "image",
            byteSize: 4,
            sha256: sha256 ?? id,
            data: Data([1, 2, 3, 4]),
            capturedAt: nil,
            sortOrder: 0,
            selected: true
        )
    }

    static func makeScene(id: String, sceneIndex: Double = 0, caption: String = "Opening") -> MomentStoryScene {
        MomentStoryScene(
            id: id,
            sceneIndex: sceneIndex,
            mediaAssetIds: [],
            caption: caption,
            narrationText: nil,
            tone: nil,
            musicCue: nil,
            durationMs: 3_000,
            createdBy: "avi"
        )
    }

    static func makeArtifact(id: String, kind: String) -> MomentArtifact {
        MomentArtifact(
            id: id,
            kind: kind,
            r2Key: "animateav/\(id).mp4",
            status: "available",
            hasWatermark: false,
            expiresAt: 1_781_592_000_000
        )
    }

    static func makeRenderJob(
        id: String,
        kind: String,
        status: String,
        phase: String? = nil,
        progressPercent: Double? = nil,
        userMessage: String? = nil,
        canEditSetup: Bool? = nil,
        canRetry: Bool? = nil,
        totalCreditCost: Double? = nil,
        plannedAssetCount: Double? = nil,
        usedAssetCount: Double? = nil,
        errorMessage: String? = nil
    ) -> MomentRenderJob {
        MomentRenderJob(
            id: id,
            kind: kind,
            status: status,
            phase: phase,
            progressPercent: progressPercent,
            userMessage: userMessage,
            canEditSetup: canEditSetup,
            canRetry: canRetry,
            totalCreditCost: totalCreditCost,
            targetDurationMs: nil,
            plannedAssetCount: plannedAssetCount,
            usedAssetCount: usedAssetCount,
            rejectedAssetCount: nil,
            rendererMode: nil,
            workflowRunId: "workflow-\(id)",
            provider: "mock-provider",
            model: "mock-model",
            providerRequestId: "request-\(id)",
            errorCode: nil,
            errorMessage: errorMessage,
            createdAt: 9,
            updatedAt: 10
        )
    }

    static func makeRenderPlan(
        momentId: String = "moment-1",
        canCreateVideo: Bool = true,
        totalCreditCost: Int = 2,
        minimumDurationMs: Int = 16_000,
        targetDurationMs: Int = 30_000,
        plannedAssetCount: Int = 4,
        usedAssetCount: Int = 3,
        createVideoBlockers: [String]? = nil
    ) -> MomentsRenderPlanResponse {
        MomentsRenderPlanResponse(
            appId: "animateav",
            momentId: momentId,
            planId: "plan-1",
            plan: MomentsRenderPlan(
                schemaVersion: 1,
                minimumDurationMs: minimumDurationMs,
                targetDurationMs: targetDurationMs,
                creditCost: totalCreditCost,
                totalCreditCost: totalCreditCost,
                secondsPerCredit: 15,
                plannedAssetCount: plannedAssetCount,
                usedAssetCount: usedAssetCount,
                rejectedAssetCount: max(0, plannedAssetCount - usedAssetCount),
                rendererMode: "image_to_video",
                renderOptionId: "animate_short",
                renderOptionTitle: "Short animation",
                userMessage: "Avi will animate the source image.",
                qualityWarnings: ["One item may be cropped."]
            ),
            canCreateVideo: canCreateVideo,
            createVideoBlockers: createVideoBlockers ?? (canCreateVideo ? [] : ["blocked"]),
            generatedAt: "2026-06-02T00:00:00Z"
        )
    }

}
