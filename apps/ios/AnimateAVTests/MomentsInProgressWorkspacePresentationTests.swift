import XCTest
@testable import AnimateAV

final class MomentsInProgressWorkspacePresentationTests: XCTestCase {
    func testWorkspaceDetailPresentationFormatsTitleActionAndContinuationRequest() {
        let workspace = makeWorkspace(
            moment: makeMoment(title: "Family Weekend"),
            mediaAssets: [
                makeMediaAsset(id: "media-1", kind: "image", sortOrder: 0, selected: true, moderationStatus: "approved")
            ]
        )

        let presentation = MomentsInProgressWorkspaceDetailPresentation(workspace: workspace)

        XCTAssertEqual(presentation.title, "Moment detail")
        XCTAssertEqual(presentation.nextAction.title, "Prepare story")
        XCTAssertEqual(presentation.continuationRequest.moment, workspace.moment)
        XCTAssertEqual(presentation.continuationRequest.focus, .story)
    }

    func testWorkspaceDetailPresentationUsesFailedRenderContinuationFocus() {
        let workspace = makeWorkspace(
            moment: makeMoment(title: "Family Weekend"),
            renderJobs: [
                makeRenderJob(id: "job-1", kind: "final", status: "failed", updatedAt: 20)
            ]
        )

        let presentation = MomentsInProgressWorkspaceDetailPresentation(workspace: workspace)

        XCTAssertEqual(presentation.nextAction.title, "Video needs attention")
        XCTAssertEqual(presentation.continuationRequest.focus, .finalRender)
    }

    func testWorkspaceHeaderPresentationFormatsTitleUpdateAndCounts() {
        let presentation = MomentsInProgressWorkspaceHeaderPresentation(
            workspace: makeWorkspace(
                moment: makeMoment(title: "Family Weekend", updatedAt: 1_781_592_000_000),
                mediaAssets: [
                    makeMediaAsset(id: "media-1", kind: "image", sortOrder: 0, selected: true, moderationStatus: "approved")
                ],
                storyScenes: [
                    makeScene(id: "scene-1", sceneIndex: 0, caption: "Opening")
                ],
                renderJobs: [
                    makeRenderJob(id: "job-1", kind: "final", status: "running", updatedAt: 20)
                ]
            )
        )

        XCTAssertEqual(presentation.title, "Family Weekend")
        XCTAssertEqual(presentation.updatedAtTitle, "Updated \(MomentsDateFormatting.formattedDate(milliseconds: 1_781_592_000_000))")
        XCTAssertEqual(presentation.countsTitle, "1 media item · 1 scene · 1 job")
    }

    func testWorkspaceHeaderPresentationFormatsPluralCounts() {
        let presentation = MomentsInProgressWorkspaceHeaderPresentation(
            workspace: makeWorkspace(
                moment: makeMoment(title: "Family Weekend"),
                mediaAssets: [
                    makeMediaAsset(id: "media-1", kind: "image", sortOrder: 0, selected: true, moderationStatus: "approved"),
                    makeMediaAsset(id: "media-2", kind: "video", sortOrder: 1, selected: false, moderationStatus: "pending")
                ],
                storyScenes: [
                    makeScene(id: "scene-1", sceneIndex: 0, caption: "Opening"),
                    makeScene(id: "scene-2", sceneIndex: 1, caption: "Middle")
                ],
                renderJobs: [
                    makeRenderJob(id: "job-1", kind: "final", status: "running", updatedAt: 20),
                    makeRenderJob(id: "job-2", kind: "final", status: "queued", updatedAt: 30)
                ]
            )
        )

        XCTAssertEqual(presentation.countsTitle, "2 media items · 2 scenes · 2 jobs")
    }

    func testWorkspaceSummaryPresentationFormatsStatusArtifactsAndLatestJob() {
        let presentation = MomentsInProgressWorkspaceSummaryPresentation(
            workspace: makeWorkspace(
                moment: makeMoment(status: "story_ready"),
                renderJobs: [
                    makeRenderJob(id: "old", kind: "final", status: "queued", updatedAt: 10),
                    makeRenderJob(id: "new", kind: "final", status: "failed", updatedAt: 20)
                ],
                artifacts: [
                    makeArtifact(id: "thumbnail-1", kind: "thumbnail", status: "expired"),
                    makeArtifact(id: "final-1", kind: "final_export", status: "available"),
                    makeArtifact(id: "thumb-2", kind: "thumbnail", status: "available")
                ]
            )
        )

        XCTAssertEqual(presentation.tiles.map(\.title), ["Status", "Final", "Latest job"])
        XCTAssertEqual(presentation.tiles.map(\.value), ["Story ready", "Available", "Final · Failed"])
        XCTAssertEqual(presentation.tiles.map(\.systemImage), ["circle.dashed", "video.fill", "gearshape.2"])
    }

    func testWorkspaceSummaryPresentationUsesFallbacksWhenNoArtifactsOrJobsExist() {
        let presentation = MomentsInProgressWorkspaceSummaryPresentation(
            workspace: makeWorkspace(moment: makeMoment(status: "in_progress"))
        )

        XCTAssertEqual(presentation.tiles.map(\.value), ["In Progress", "Not ready", "Not started"])
    }

    func testMediaSectionPresentationFormatsTitleEmptyStateAndRows() {
        let presentation = MomentsInProgressMediaSectionPresentation(mediaAssets: [
            makeMediaAsset(id: "second", kind: "video", sortOrder: 1, selected: false, moderationStatus: "pending"),
            makeMediaAsset(id: "first", kind: "image", sortOrder: 0, selected: true, moderationStatus: "approved")
        ])

        XCTAssertEqual(presentation.title, "Media")
        XCTAssertEqual(presentation.emptySystemImage, "photo.badge.plus")
        XCTAssertEqual(presentation.emptyMessage, "No media is attached to this Moment yet. Add photos or clips from Create to prepare the story.")
        XCTAssertEqual(presentation.mediaAssets.map(\.id), ["first", "second"])
    }

    func testSharedMediaItemsPreferLocalSelectionAndSortSyncedMedia() {
        let localMedia = [
            MomentsCreateTestFixtures.makeSelectedMedia(id: "00000000-0000-0000-0000-000000000001")
        ]
        let syncedMedia = [
            makeMediaAsset(id: "second", kind: "video", sortOrder: 1, selected: false, moderationStatus: "pending"),
            makeMediaAsset(id: "first", kind: "image", sortOrder: 0, selected: true, moderationStatus: "approved")
        ]

        let localItems = MomentsSharedMediaItem.preferred(localMedia: localMedia, syncedMedia: syncedMedia)
        let syncedItems = MomentsSharedMediaItem.preferred(localMedia: [], syncedMedia: syncedMedia)

        XCTAssertEqual(localItems.map(\.id), ["00000000-0000-0000-0000-000000000001"])
        XCTAssertEqual(syncedItems.map(\.id), ["first", "second"])
        XCTAssertEqual(syncedItems.map(\.displayKind), ["Image", "Video"])
    }

    func testStorySectionPresentationFormatsTitleEmptyStateAndRows() {
        let presentation = MomentsInProgressStorySectionPresentation(storyScenes: [
            makeScene(id: "scene-2", sceneIndex: 1, caption: "Second beat"),
            makeScene(id: "scene-1", sceneIndex: 0, caption: "Opening beat")
        ])

        XCTAssertEqual(presentation.title, "Story")
        XCTAssertEqual(presentation.emptySystemImage, "text.bubble")
        XCTAssertEqual(presentation.emptyMessage, "Prepare the story after this Moment has enough media.")
        XCTAssertEqual(presentation.storyScenes.map(\.id), ["scene-1", "scene-2"])
    }

    func testMediaAssetPresentationSortsBySortOrderAndFormatsRows() {
        let presentations = MomentsInProgressMediaAssetPresentation.sorted([
            makeMediaAsset(id: "second", kind: "video", sortOrder: 1, selected: false, moderationStatus: "pending"),
            makeMediaAsset(id: "first", kind: "image", sortOrder: 0, selected: true, moderationStatus: "approved")
        ])

        XCTAssertEqual(presentations.map(\.id), ["first", "second"])
        XCTAssertEqual(presentations[0].systemImage, "photo")
        XCTAssertEqual(presentations[0].title, "Image 1")
        XCTAssertEqual(presentations[0].detail, "Selected · Approved")
        XCTAssertEqual(presentations[1].systemImage, "video")
        XCTAssertEqual(presentations[1].title, "Video 2")
        XCTAssertEqual(presentations[1].detail, "Not selected · Pending")
    }

    private func makeWorkspace(
        moment: InProgressMoment,
        mediaAssets: [MomentMediaAsset] = [],
        storyScenes: [MomentStoryScene] = [],
        renderJobs: [MomentRenderJob] = [],
        artifacts: [MomentArtifact] = []
    ) -> MomentWorkspace {
        MomentWorkspace(
            moment: moment,
            mediaAssets: mediaAssets,
            storyScenes: storyScenes,
            renderJobs: renderJobs,
            artifacts: artifacts
        )
    }

    private func makeMoment(
        status: String = "in_progress",
        title: String = "moment-1",
        updatedAt: Double = 10
    ) -> InProgressMoment {
        InProgressMoment(
            id: "moment-1",
            template: .birthdayMessage,
            status: status,
            title: title,
            tone: nil,
            tempo: nil,
            occasion: nil,
            details: nil,
            durationSeconds: 30,
            creditCost: 2,
            updatedAt: updatedAt
        )
    }

    func testStoryScenePresentationSortsBySceneIndexAndFormatsRows() {
        let presentations = MomentsInProgressStoryScenePresentation.sorted([
            makeScene(id: "scene-2", sceneIndex: 1, caption: "Second beat"),
            makeScene(id: "scene-1", sceneIndex: 0, caption: "Opening beat")
        ])

        XCTAssertEqual(presentations.map(\.id), ["scene-1", "scene-2"])
        XCTAssertEqual(presentations[0].title, "Scene 1")
        XCTAssertEqual(presentations[0].caption, "Opening beat")
        XCTAssertEqual(presentations[1].title, "Scene 2")
    }

    func testWorkspaceLookupsFindLatestArtifactAndRenderJob() {
        let workspace = makeWorkspace(
            moment: makeMoment(),
            renderJobs: [
                makeRenderJob(id: "final", kind: "final", status: "queued", updatedAt: 30),
                makeRenderJob(id: "final-old", kind: "final", status: "queued", updatedAt: 10),
                makeRenderJob(id: "final-new", kind: "final", status: "running", updatedAt: 20)
            ],
            artifacts: [
                makeArtifact(id: "thumb-expired", kind: "thumbnail", status: "expired"),
                makeArtifact(id: "final-export", kind: "final_export", status: "available"),
                makeArtifact(id: "thumb-ready", kind: "thumbnail", status: "expired")
            ]
        )

        XCTAssertEqual(workspace.latestArtifact(kind: "final_export")?.id, "final-export")
        XCTAssertEqual(workspace.latestRenderJob(kind: "final")?.id, "final")
        XCTAssertEqual(workspace.latestRenderJob()?.id, "final")
        XCTAssertTrue(workspace.hasAvailableArtifact(kind: "final_export"))
        XCTAssertFalse(workspace.hasAvailableArtifact(kind: "thumbnail"))
    }

    private func makeMediaAsset(
        id: String,
        kind: String,
        sortOrder: Double,
        selected: Bool,
        moderationStatus: String
    ) -> MomentMediaAsset {
        MomentMediaAsset(
            id: id,
            platformMediaAssetId: "platform-\(id)",
            uploadId: "upload-\(id)",
            kind: kind,
            sortOrder: sortOrder,
            selected: selected,
            moderationStatus: moderationStatus,
            uploadedAt: nil,
            sourceExpiresAt: nil
        )
    }

    private func makeScene(id: String, sceneIndex: Double, caption: String) -> MomentStoryScene {
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

    private func makeArtifact(id: String, kind: String, status: String) -> MomentArtifact {
        MomentArtifact(
            id: id,
            kind: kind,
            r2Key: "animateav/\(id).mp4",
            status: status,
            hasWatermark: false,
            expiresAt: 1_781_592_000_000
        )
    }

    private func makeRenderJob(id: String, kind: String, status: String, updatedAt: Double) -> MomentRenderJob {
        MomentRenderJob(
            id: id,
            kind: kind,
            status: status,
            workflowRunId: "workflow-\(id)",
            provider: "mock-provider",
            model: "mock-model",
            providerRequestId: "request-\(id)",
            errorCode: status == "failed" ? "provider_failed" : nil,
            errorMessage: status == "failed" ? "Render failed." : nil,
            createdAt: updatedAt - 1,
            updatedAt: updatedAt
        )
    }
}
