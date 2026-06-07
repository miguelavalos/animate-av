import XCTest
@testable import AnimateAV

final class AnimateStatusRulesTests: XCTestCase {
    func testGroupsCompletedVideosAsFinished() {
        let plan = makeMoment(id: "in_progress", status: "in_progress", updatedAt: 10)
        let story = makeMoment(id: "story", status: "story_ready", updatedAt: 20)
        let completed = makeMoment(id: "completed", status: "gallery_ready", updatedAt: 30)

        let groups = AnimateStatusRules.group([plan, story, completed])

        XCTAssertEqual(groups.inProgress.map(\.id), ["story", "in_progress"])
        XCTAssertEqual(groups.finished.map(\.id), ["completed"])
    }

    func testGroupsSortVideosByLatestUpdateWithinEachSection() {
        let olderInProgress = makeMoment(id: "older-plan", status: "in_progress", updatedAt: 10)
        let newerInProgress = makeMoment(id: "newer-plan", status: "story_ready", updatedAt: 30)
        let olderFinished = makeMoment(id: "older-finished", status: "gallery_ready", updatedAt: 20)
        let newerFinished = makeMoment(id: "newer-finished", status: "gallery_ready", updatedAt: 40)

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
        let oldest = makeMoment(id: "oldest", status: "gallery_ready", updatedAt: 10)
        let newest = makeMoment(id: "newest", status: "story_ready", updatedAt: 30)
        let middle = makeMoment(id: "middle", status: "gallery_ready", updatedAt: 20)

        let summary = AnimateInProgressSummary.make(from: [oldest, newest, middle])

        XCTAssertEqual(summary.momentCount, 3)
        XCTAssertEqual(summary.inProgressCount, 1)
        XCTAssertEqual(summary.finishedCount, 2)
        XCTAssertEqual(summary.latestMoment?.id, "newest")
        XCTAssertTrue(summary.hasMoments)
    }

    func testListSummarySeparatesAnimateVideoAndImageJobs() {
        let video = makeMoment(id: "video", status: "running", updatedAt: 10, assetKind: "video")
        let image = makeMoment(id: "image", status: "running", updatedAt: 20, assetKind: "image")
        let completedImage = makeMoment(id: "completed-image", status: "completed", updatedAt: 30, assetKind: "image")

        let summary = AnimateInProgressSummary.make(from: [video, image, completedImage])

        XCTAssertEqual(summary.videoSummary.moments.map(\.id), ["video"])
        XCTAssertEqual(summary.videoSummary.inProgressCount, 1)
        XCTAssertEqual(summary.imageSummary.moments.map(\.id), ["image", "completed-image"])
        XCTAssertEqual(summary.imageSummary.inProgressCount, 1)
        XCTAssertEqual(summary.imageSummary.finishedCount, 1)
    }

    func testListSummaryExposesLatestInProgressContinuationRequest() {
        let olderInProgress = makeMoment(id: "older-plan", status: "in_progress", updatedAt: 10)
        let newestFinished = makeMoment(id: "newest-finished", status: "gallery_ready", updatedAt: 30)
        let latestInProgress = makeMoment(id: "latest-plan", status: "story_ready", updatedAt: 20)

        let summary = AnimateInProgressSummary.make(from: [olderInProgress, newestFinished, latestInProgress])

        XCTAssertEqual(summary.latestMoment?.id, "newest-finished")
        XCTAssertEqual(summary.latestAnimateVideo?.id, "latest-plan")
        XCTAssertEqual(summary.latestInProgressContinuationRequest?.moment.id, "latest-plan")
        XCTAssertEqual(summary.latestInProgressContinuationRequest?.focus, .moment)
    }

    func testEmptyListSummaryHasNoVideos() {
        let summary = AnimateInProgressSummary.make(from: [])

        XCTAssertEqual(summary.momentCount, 0)
        XCTAssertEqual(summary.inProgressCount, 0)
        XCTAssertEqual(summary.finishedCount, 0)
        XCTAssertNil(summary.latestMoment)
        XCTAssertNil(summary.latestAnimateVideo)
        XCTAssertNil(summary.latestInProgressContinuationRequest)
        XCTAssertFalse(summary.hasMoments)
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

    func testNextActionAsksForStoryWhenMediaExistsWithoutScenes() {
        let action = AnimateStatusRules.nextAction(for: makeWorkspace(mediaAssets: [makeMediaAsset()]))

        XCTAssertEqual(action.title, "Prepare video")
        XCTAssertEqual(action.systemImage, "text.bubble")
        XCTAssertEqual(action.primaryButtonTitle, "Prepare Video in Create")
        XCTAssertEqual(action.continuationFocus, .story)
    }

    func testNextActionAsksForFinalWhenStoryExistsWithoutFinalArtifact() {
        let action = AnimateStatusRules.nextAction(
            for: makeWorkspace(
                mediaAssets: [makeMediaAsset()],
                storyScenes: [makeStoryScene()]
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
                storyScenes: [makeStoryScene()],
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
                storyScenes: [makeStoryScene()],
                renderJobs: [makeRenderJob(kind: "final", status: "failed")]
            )
        )

        XCTAssertEqual(action.title, "Video needs attention")
        XCTAssertEqual(action.systemImage, "exclamationmark.triangle")
        XCTAssertEqual(action.primaryButtonTitle, "Open in Create")
        XCTAssertEqual(action.continuationFocus, .finalRender)
    }

    private func makeMoment(
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
        storyScenes: [AnimateStoryScene] = [],
        renderJobs: [AnimateRenderJob] = [],
        artifacts: [AnimateArtifact] = []
    ) -> AnimateWorkspace {
        AnimateWorkspace(
            moment: makeMoment(id: "moment-1", status: "in_progress", updatedAt: 10),
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

    private func makeStoryScene() -> AnimateStoryScene {
        AnimateStoryScene(
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
