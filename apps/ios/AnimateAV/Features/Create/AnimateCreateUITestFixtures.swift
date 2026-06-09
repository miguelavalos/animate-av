import Foundation

enum AnimateCreateUITestFixtures {
    enum Mode: String {
        case storyReady = "story_ready"
        case videoPlanReady = "video_plan_ready"
        case videoPlanReadyNoMessage = "video_plan_ready_no_message"
        case videoPlanReadyWithMessage = "video_plan_ready_with_message"
        case videoPlanInsufficientCredits = "video_plan_insufficient_credits"
        case finalQueued = "final_queued"
        case finalRunning = "final_running"
        case full

        static var current: Mode? {
            guard let fixture = AnimateUITestEnvironment.current.createFixture else { return nil }
            return Mode(rawValue: fixture)
        }
    }

    static let videoId = "videos-ui-video-1"

    static var mode: Mode? {
        Mode.current
    }

    static var isActive: Bool {
        mode != nil
    }

    static var video: AnimateVideo {
        video(for: .full)
    }

    static func video(for mode: Mode) -> AnimateVideo {
        AnimateVideo(
            id: videoId,
            template: .birthdayMessage,
            status: videoStatus(for: mode),
            title: "Animated Portrait",
            tone: "warm",
            tempo: "balanced",
            occasion: "Portrait animation",
            details: "Keep the animation warm, expressive, and focused on the photo.",
            storyInputSignature: nil,
            durationSeconds: 5,
            creditCost: 1,
            updatedAt: 1_781_592_000_000
        )
    }

    static var workspace: AnimateWorkspace {
        workspace(for: .full)
    }

    static func workspace(for mode: Mode) -> AnimateWorkspace {
        AnimateWorkspace(
            video: video(for: mode),
            mediaAssets: mediaAssets,
            storyScenes: storyScenes,
            renderJobs: renderJobs(for: mode),
            artifacts: artifacts(for: mode)
        )
    }

    static var balance: AnimateCreditBalance {
        balance(for: .full)
    }

    static func balance(for mode: Mode) -> AnimateCreditBalance {
        switch mode {
        case .videoPlanInsufficientCredits:
            return .empty
        case .storyReady, .videoPlanReady, .videoPlanReadyNoMessage, .videoPlanReadyWithMessage, .finalQueued, .finalRunning, .full:
            return AnimateCreditBalance(proMonthly: 4, promotional: 1, purchased: 3)
        }
    }

    static var selectedMedia: [AnimateSelectedMedia] {
        [
            selectedMedia(id: "11111111-1111-1111-1111-111111111111", filename: "portrait-source.jpg", sortOrder: 0)
        ]
    }

    static var mediaAssets: [AnimateMediaAsset] {
        [
            mediaAsset(id: "media-1", kind: "image", sortOrder: 0)
        ]
    }

    static var storyScenes: [AnimateVideoDirectionScene] {
        [
            storyScene(
                id: "scene-1",
                index: 0,
                caption: "Avi sketches the portrait into a bright cartoon close-up.",
                narration: "We start with a playful hello and let the photo come to life."
            ),
            storyScene(
                id: "scene-2",
                index: 1,
                caption: "The character waves, smiles, and lands on the celebration message.",
                narration: "Then the motion, voice, and style turn it into a tiny animated greeting."
            )
        ]
    }

    static var renderJobs: [AnimateRenderJob] {
        renderJobs(for: .full)
    }

    static func renderJobs(for mode: Mode) -> [AnimateRenderJob] {
        switch mode {
        case .storyReady, .videoPlanReady, .videoPlanReadyNoMessage, .videoPlanReadyWithMessage, .videoPlanInsufficientCredits:
            return []
        case .finalQueued:
            return [
                renderJob(id: "final-job-1", kind: "final", status: "queued", model: "mock/videos-final-v1")
            ]
        case .finalRunning:
            return [
                renderJob(id: "final-job-1", kind: "final", status: "running", model: "mock/videos-final-v1")
            ]
        case .full:
            return [
                renderJob(id: "final-job-1", kind: "final", status: "completed", model: "mock/videos-final-v1")
            ]
        }
    }

    static var artifacts: [AnimateArtifact] {
        artifacts(for: .full)
    }

    static func artifacts(for mode: Mode) -> [AnimateArtifact] {
        switch mode {
        case .storyReady, .videoPlanReady, .videoPlanReadyNoMessage, .videoPlanReadyWithMessage, .videoPlanInsufficientCredits:
            return []
        case .finalQueued, .finalRunning:
            return []
        case .full:
            return [
                artifact(id: "final-artifact-1", kind: "final_export", key: "animateav/ui-test/video-1/final/final-1.mp4", hasWatermark: false)
            ]
        }
    }

    static var renderPlan: AnimateRenderPlanResponse {
        renderPlan(for: .videoPlanReady)
    }

    static func renderPlan(for mode: Mode) -> AnimateRenderPlanResponse {
        let hasCredits = mode != .videoPlanInsufficientCredits
        let creditCost = mode == .videoPlanReadyWithMessage ? 2 : 1
        return AnimateRenderPlanResponse(
            appId: "animateav",
            videoId: videoId,
            planId: hasCredits ? "ui-test-plan-1" : "ui-test-plan-low-credits",
            watermark: AnimateRenderWatermarkPlan(
                includedForPro: true,
                userHasWatermarkFree: false,
                nonProRemovalCreditCost: 1,
                selectedRemoveWatermark: false,
                watermarkCreditCost: 0
            ),
            plan: AnimateRenderPlan(
                schemaVersion: 1,
                minimumDurationMs: 5_000,
                targetDurationMs: 5_000,
                creditCost: creditCost,
                totalCreditCost: creditCost,
                secondsPerCredit: 5,
                plannedAssetCount: 1,
                usedAssetCount: 1,
                rejectedAssetCount: 0,
                rendererMode: "image_to_video",
                renderOptionId: "animate_short",
                renderOptionTitle: "Short animation",
                userMessage: "Avi will animate the photo with audio into an up to 5 second cartoon video.",
                qualityWarnings: []
            ),
            canCreateVideo: hasCredits,
            createVideoBlockers: hasCredits ? [] : ["insufficient_credits"],
            generatedAt: "2026-06-02T00:00:00Z"
        )
    }

    private static func videoStatus(for mode: Mode) -> String {
        switch mode {
        case .full:
            return "gallery_ready"
        case .finalQueued, .finalRunning:
            return "rendering"
        case .storyReady, .videoPlanReady, .videoPlanReadyNoMessage, .videoPlanReadyWithMessage, .videoPlanInsufficientCredits:
            return "story_ready"
        }
    }

    private static func selectedMedia(
        id: String,
        filename: String,
        kind: String = "image",
        contentType: String = "image/jpeg",
        sortOrder: Double
    ) -> AnimateSelectedMedia {
        AnimateSelectedMedia(
            id: UUID(uuidString: id)!,
            sourceLocalIdentifier: id,
            originalFilename: filename,
            contentType: contentType,
            kind: kind,
            byteSize: kind == "video" ? 8_800_000 : 2_400_000,
            sha256: "ui-test-\(id)",
            data: Data([1, 2, 3, 4]),
            capturedAt: nil,
            sortOrder: Int(sortOrder),
            selected: true
        )
    }

    private static func mediaAsset(id: String, kind: String, sortOrder: Double) -> AnimateMediaAsset {
        AnimateMediaAsset(
            id: id,
            platformMediaAssetId: "platform-\(id)",
            uploadId: "upload-\(id)",
            kind: kind,
            sortOrder: sortOrder,
            selected: true,
            moderationStatus: "approved",
            uploadedAt: 1_781_591_000_000 + sortOrder,
            sourceExpiresAt: nil
        )
    }

    private static func storyScene(
        id: String,
        index: Double,
        caption: String,
        narration: String
    ) -> AnimateVideoDirectionScene {
        AnimateVideoDirectionScene(
            id: id,
            sceneIndex: index,
            mediaAssetIds: [],
            caption: caption,
            narrationText: narration,
            tone: "warm",
            musicCue: "gentle acoustic pulse",
            durationMs: 6_000,
            createdBy: "avi"
        )
    }

    private static func renderJob(
        id: String,
        kind: String,
        status: String,
        model: String
    ) -> AnimateRenderJob {
        let isCompleted = status == "completed"
        let isQueued = status == "queued"

        return AnimateRenderJob(
            id: id,
            kind: kind,
            status: status,
            phase: isCompleted ? "completed" : isQueued ? "queued" : "running",
            progressPercent: isCompleted ? 100 : isQueued ? 10 : 56,
            userMessage: isCompleted ? "Your video is ready." : isQueued ? "Your video is queued." : "Avi is creating the final video.",
            canEditSetup: status != "running",
            canRetry: status == "failed",
            targetDurationMs: 15_000,
            plannedAssetCount: 10,
            usedAssetCount: 10,
            rejectedAssetCount: 0,
            rendererMode: "ui-test",
            workflowRunId: "workflow-\(id)",
            provider: "apps-av-ui-test",
            model: model,
            providerRequestId: "request-\(id)",
            errorCode: nil,
            errorMessage: nil,
            createdAt: 1_781_591_000_000,
            updatedAt: 1_781_592_000_000
        )
    }

    private static func artifact(
        id: String,
        kind: String,
        key: String,
        hasWatermark: Bool
    ) -> AnimateArtifact {
        AnimateArtifact(
            id: id,
            kind: kind,
            r2Key: key,
            status: "available",
            hasWatermark: hasWatermark,
            expiresAt: 1_781_852_000_000
        )
    }
}
