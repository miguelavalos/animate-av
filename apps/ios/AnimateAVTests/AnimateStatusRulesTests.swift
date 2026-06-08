import XCTest
@testable import AnimateAV

final class AnimateStatusRulesTests: XCTestCase {
    func testGroupsCompletedVideosAsFinished() {
        let plan = makeVideo(id: "in_progress", status: "in_progress", updatedAt: 10)
        let videoDirectionReady = makeVideo(id: "direction", status: "story_ready", updatedAt: 20)
        let completed = makeVideo(id: "completed", status: "gallery_ready", updatedAt: 30)

        let groups = AnimateStatusRules.group([plan, videoDirectionReady, completed])

        XCTAssertEqual(groups.inProgress.map(\.id), ["direction", "in_progress"])
        XCTAssertEqual(groups.finished.map(\.id), ["completed"])
    }

    func testGroupsSortVideosByLatestUpdateWithinEachSection() {
        let olderInProgress = makeVideo(id: "older-plan", status: "in_progress", updatedAt: 10)
        let newerInProgress = makeVideo(id: "newer-plan", status: "story_ready", updatedAt: 30)
        let olderFinished = makeVideo(id: "older-finished", status: "gallery_ready", updatedAt: 20)
        let newerFinished = makeVideo(id: "newer-finished", status: "gallery_ready", updatedAt: 40)

        let groups = AnimateStatusRules.group([
            olderInProgress,
            olderFinished,
            newerInProgress,
            newerFinished
        ])

        XCTAssertEqual(groups.inProgress.map(\.id), ["newer-plan", "older-plan"])
        XCTAssertEqual(groups.finished.map(\.id), ["newer-finished", "older-finished"])
    }

    func testListSummaryCountsAndLatestVideoUseStatusRules() {
        let oldest = makeVideo(id: "oldest", status: "gallery_ready", updatedAt: 10)
        let newest = makeVideo(id: "newest", status: "story_ready", updatedAt: 30)
        let middle = makeVideo(id: "middle", status: "gallery_ready", updatedAt: 20)

        let summary = AnimateInProgressSummary.make(from: [oldest, newest, middle])

        XCTAssertEqual(summary.videoCount, 3)
        XCTAssertEqual(summary.inProgressCount, 1)
        XCTAssertEqual(summary.finishedCount, 2)
        XCTAssertEqual(summary.latestVideo?.id, "newest")
        XCTAssertTrue(summary.hasVideos)
    }

    func testListSummarySeparatesAnimateVideoAndImageJobs() {
        let video = makeVideo(id: "video", status: "running", updatedAt: 10, assetKind: "video")
        let image = makeVideo(id: "image", status: "running", updatedAt: 20, assetKind: "image")
        let completedImage = makeVideo(id: "completed-image", status: "completed", updatedAt: 30, assetKind: "image")

        let summary = AnimateInProgressSummary.make(from: [video, image, completedImage])

        XCTAssertEqual(summary.videoSummary.videos.map(\.id), ["video"])
        XCTAssertEqual(summary.videoSummary.inProgressCount, 1)
        XCTAssertEqual(summary.imageSummary.videos.map(\.id), ["image", "completed-image"])
        XCTAssertEqual(summary.imageSummary.inProgressCount, 1)
        XCTAssertEqual(summary.imageSummary.finishedCount, 1)
    }

    func testListSummaryExposesLatestInProgressContinuationRequest() {
        let olderInProgress = makeVideo(id: "older-plan", status: "in_progress", updatedAt: 10)
        let newestFinished = makeVideo(id: "newest-finished", status: "gallery_ready", updatedAt: 30)
        let latestInProgress = makeVideo(id: "latest-plan", status: "story_ready", updatedAt: 20)

        let summary = AnimateInProgressSummary.make(from: [olderInProgress, newestFinished, latestInProgress])

        XCTAssertEqual(summary.latestVideo?.id, "newest-finished")
        XCTAssertEqual(summary.latestAnimateVideo?.id, "latest-plan")
        XCTAssertEqual(summary.latestInProgressContinuationRequest?.video.id, "latest-plan")
        XCTAssertEqual(summary.latestInProgressContinuationRequest?.focus, .video)
    }

    func testEmptyListSummaryHasNoVideos() {
        let summary = AnimateInProgressSummary.make(from: [])

        XCTAssertEqual(summary.videoCount, 0)
        XCTAssertEqual(summary.inProgressCount, 0)
        XCTAssertEqual(summary.finishedCount, 0)
        XCTAssertNil(summary.latestVideo)
        XCTAssertNil(summary.latestAnimateVideo)
        XCTAssertNil(summary.latestInProgressContinuationRequest)
        XCTAssertFalse(summary.hasVideos)
    }

    func testDisplayHelpersFormatBackendValuesForUI() {
        XCTAssertEqual(AnimateStatusRules.displayTitle(for: "story_ready"), "Direction ready")
        XCTAssertEqual(AnimateStatusRules.displayKind("final"), "Final")
        XCTAssertEqual(AnimateStatusRules.displayKind("final_export"), "Final Export")
    }

    func testNextActionAsksForMediaWhenWorkspaceHasNoMedia() {
        let action = AnimateStatusRules.nextAction(for: makeWorkspace())

        XCTAssertEqual(action.title, "Add photo")
        XCTAssertEqual(action.systemImage, "photo.badge.plus")
        XCTAssertEqual(action.primaryButtonTitle, "Add Photo in Create")
        XCTAssertEqual(action.continuationFocus, .media)
    }

    func testNextActionAsksForVideoDirectionWhenMediaExistsWithoutScenes() {
        let action = AnimateStatusRules.nextAction(for: makeWorkspace(mediaAssets: [makeMediaAsset()]))

        XCTAssertEqual(action.title, "Prepare video")
        XCTAssertEqual(action.systemImage, "text.bubble")
        XCTAssertEqual(action.primaryButtonTitle, "Prepare Video in Create")
        XCTAssertEqual(action.continuationFocus, .story)
    }

    func testNextActionAsksForFinalWhenVideoDirectionExistsWithoutFinalArtifact() {
        let action = AnimateStatusRules.nextAction(
            for: makeWorkspace(
                mediaAssets: [makeMediaAsset()],
                storyScenes: [makeVideoDirectionScene()]
            )
        )

        XCTAssertEqual(action.title, "Create video")
        XCTAssertEqual(action.systemImage, "video.fill")
        XCTAssertEqual(action.primaryButtonTitle, "Create Video in Create")
        XCTAssertEqual(action.continuationFocus, .finalRender)
    }

    func testNextActionMarksFinishedWhenFinalExportIsAvailable() {
        let action = AnimateStatusRules.nextAction(
            for: makeWorkspace(
                mediaAssets: [makeMediaAsset()],
                storyScenes: [makeVideoDirectionScene()],
                artifacts: [
                    makeArtifact(kind: "final_export")
                ]
            )
        )

        XCTAssertEqual(action.title, "Finished")
        XCTAssertEqual(action.systemImage, "checkmark.circle")
        XCTAssertEqual(action.primaryButtonTitle, "Open in Create")
        XCTAssertEqual(action.continuationFocus, .finalRender)
    }

    func testNextActionPrioritizesFailedRenderJobs() {
        let action = AnimateStatusRules.nextAction(
            for: makeWorkspace(
                mediaAssets: [makeMediaAsset()],
                storyScenes: [makeVideoDirectionScene()],
                renderJobs: [makeRenderJob(kind: "final", status: "failed")]
            )
        )

        XCTAssertEqual(action.title, "Video needs attention")
        XCTAssertEqual(action.systemImage, "exclamationmark.triangle")
        XCTAssertEqual(action.primaryButtonTitle, "Open in Create")
        XCTAssertEqual(action.continuationFocus, .finalRender)
    }

    private func makeVideo(
        id: String,
        status: String,
        updatedAt: Double,
        assetKind: String = "video"
    ) -> AnimateVideo {
        AnimateVideo(
            id: id,
            template: .birthdayMessage,
            status: status,
            title: id,
            tone: nil,
            tempo: nil,
            occasion: nil,
            details: nil,
            durationSeconds: 30,
            creditCost: 2,
            updatedAt: updatedAt,
            assetKind: assetKind
        )
    }

    private func makeWorkspace(
        mediaAssets: [AnimateMediaAsset] = [],
        storyScenes: [AnimateVideoDirectionScene] = [],
        renderJobs: [AnimateRenderJob] = [],
        artifacts: [AnimateArtifact] = []
    ) -> AnimateWorkspace {
        AnimateWorkspace(
            video: makeVideo(id: "moment-1", status: "in_progress", updatedAt: 10),
            mediaAssets: mediaAssets,
            storyScenes: storyScenes,
            renderJobs: renderJobs,
            artifacts: artifacts
        )
    }

    private func makeMediaAsset() -> AnimateMediaAsset {
        AnimateMediaAsset(
            id: "media-1",
            platformMediaAssetId: "platform-media-1",
            uploadId: "upload-1",
            kind: "photo",
            sortOrder: 0,
            selected: true,
            moderationStatus: "pending",
            uploadedAt: 1_779_000_000_000,
            sourceExpiresAt: 1_781_592_000_000
        )
    }

    private func makeVideoDirectionScene() -> AnimateVideoDirectionScene {
        AnimateVideoDirectionScene(
            id: "scene-1",
            sceneIndex: 0,
            mediaAssetIds: ["media-1"],
            caption: "Opening",
            narrationText: "The first scene.",
            tone: "warm",
            musicCue: "soft piano",
            durationMs: 4_000,
            createdBy: "avi"
        )
    }

    private func makeArtifact(kind: String) -> AnimateArtifact {
        AnimateArtifact(
            id: "\(kind)-1",
            kind: kind,
            r2Key: "animateav/user/moment/\(kind).mp4",
            status: "available",
            hasWatermark: false,
            expiresAt: 1_781_592_000_000
        )
    }

    private func makeRenderJob(kind: String, status: String) -> AnimateRenderJob {
        AnimateRenderJob(
            id: "\(kind)-job-1",
            kind: kind,
            status: status,
            workflowRunId: "workflow-1",
            provider: "mock-provider",
            model: "mock-model",
            providerRequestId: "provider-request-1",
            errorCode: status == "failed" ? "provider_failed" : nil,
            errorMessage: status == "failed" ? "Render failed." : nil,
            createdAt: 1_779_000_000_000,
            updatedAt: 1_779_000_001_000
        )
    }
}
