import XCTest
@testable import AnimateAV

final class MomentStatusRulesTests: XCTestCase {
    func testGroupsCompletedMomentsAsFinished() {
        let plan = makeMoment(id: "in_progress", status: "in_progress", updatedAt: 10)
        let story = makeMoment(id: "story", status: "story_ready", updatedAt: 20)
        let completed = makeMoment(id: "completed", status: "gallery_ready", updatedAt: 30)

        let groups = MomentStatusRules.group([plan, story, completed])

        XCTAssertEqual(groups.inProgress.map(\.id), ["story", "in_progress"])
        XCTAssertEqual(groups.finished.map(\.id), ["completed"])
    }

    func testGroupsSortMomentsByLatestUpdateWithinEachSection() {
        let olderInProgress = makeMoment(id: "older-plan", status: "in_progress", updatedAt: 10)
        let newerInProgress = makeMoment(id: "newer-plan", status: "story_ready", updatedAt: 30)
        let olderFinished = makeMoment(id: "older-finished", status: "gallery_ready", updatedAt: 20)
        let newerFinished = makeMoment(id: "newer-finished", status: "gallery_ready", updatedAt: 40)

        let groups = MomentStatusRules.group([
            olderInProgress,
            olderFinished,
            newerInProgress,
            newerFinished
        ])

        XCTAssertEqual(groups.inProgress.map(\.id), ["newer-plan", "older-plan"])
        XCTAssertEqual(groups.finished.map(\.id), ["newer-finished", "older-finished"])
    }

    func testListSummaryCountsAndLatestMomentUseMomentRules() {
        let oldest = makeMoment(id: "oldest", status: "gallery_ready", updatedAt: 10)
        let newest = makeMoment(id: "newest", status: "story_ready", updatedAt: 30)
        let middle = makeMoment(id: "middle", status: "gallery_ready", updatedAt: 20)

        let summary = InProgressMomentsSummary.make(from: [oldest, newest, middle])

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

        let summary = InProgressMomentsSummary.make(from: [video, image, completedImage])

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

        let summary = InProgressMomentsSummary.make(from: [olderInProgress, newestFinished, latestInProgress])

        XCTAssertEqual(summary.latestMoment?.id, "newest-finished")
        XCTAssertEqual(summary.latestInProgressMoment?.id, "latest-plan")
        XCTAssertEqual(summary.latestInProgressContinuationRequest?.moment.id, "latest-plan")
        XCTAssertEqual(summary.latestInProgressContinuationRequest?.focus, .moment)
    }

    func testEmptyListSummaryHasNoMoments() {
        let summary = InProgressMomentsSummary.make(from: [])

        XCTAssertEqual(summary.momentCount, 0)
        XCTAssertEqual(summary.inProgressCount, 0)
        XCTAssertEqual(summary.finishedCount, 0)
        XCTAssertNil(summary.latestMoment)
        XCTAssertNil(summary.latestInProgressMoment)
        XCTAssertNil(summary.latestInProgressContinuationRequest)
        XCTAssertFalse(summary.hasMoments)
    }

    func testDisplayHelpersFormatBackendValuesForUI() {
        XCTAssertEqual(MomentStatusRules.displayTitle(for: "story_ready"), "Direction ready")
        XCTAssertEqual(MomentStatusRules.displayKind("final"), "Final")
        XCTAssertEqual(MomentStatusRules.displayKind("final_export"), "Final Export")
    }

    func testNextActionAsksForMediaWhenWorkspaceHasNoMedia() {
        let action = MomentStatusRules.nextAction(for: makeWorkspace())

        XCTAssertEqual(action.title, "Add photo")
        XCTAssertEqual(action.systemImage, "photo.badge.plus")
        XCTAssertEqual(action.primaryButtonTitle, "Add Photo in Create")
        XCTAssertEqual(action.continuationFocus, .media)
    }

    func testNextActionAsksForStoryWhenMediaExistsWithoutScenes() {
        let action = MomentStatusRules.nextAction(for: makeWorkspace(mediaAssets: [makeMediaAsset()]))

        XCTAssertEqual(action.title, "Prepare video")
        XCTAssertEqual(action.systemImage, "text.bubble")
        XCTAssertEqual(action.primaryButtonTitle, "Prepare Video in Create")
        XCTAssertEqual(action.continuationFocus, .story)
    }

    func testNextActionAsksForFinalWhenStoryExistsWithoutFinalArtifact() {
        let action = MomentStatusRules.nextAction(
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
        let action = MomentStatusRules.nextAction(
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
        let action = MomentStatusRules.nextAction(
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
    ) -> InProgressMoment {
        InProgressMoment(
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
        mediaAssets: [MomentMediaAsset] = [],
        storyScenes: [MomentStoryScene] = [],
        renderJobs: [MomentRenderJob] = [],
        artifacts: [MomentArtifact] = []
    ) -> MomentWorkspace {
        MomentWorkspace(
            moment: makeMoment(id: "moment-1", status: "in_progress", updatedAt: 10),
            mediaAssets: mediaAssets,
            storyScenes: storyScenes,
            renderJobs: renderJobs,
            artifacts: artifacts
        )
    }

    private func makeMediaAsset() -> MomentMediaAsset {
        MomentMediaAsset(
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

    private func makeStoryScene() -> MomentStoryScene {
        MomentStoryScene(
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

    private func makeArtifact(kind: String) -> MomentArtifact {
        MomentArtifact(
            id: "\(kind)-1",
            kind: kind,
            r2Key: "animateav/user/moment/\(kind).mp4",
            status: "available",
            hasWatermark: false,
            expiresAt: 1_781_592_000_000
        )
    }

    private func makeRenderJob(kind: String, status: String) -> MomentRenderJob {
        MomentRenderJob(
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
