import XCTest
import Combine
@testable import AnimateAV

@MainActor
final class AnimateCreateViewModelStoryStateTests: XCTestCase {
    func testSubmittingFinalVideoWithoutWorkflowFailsVisibly() {
        let viewModel = AnimateCreateViewModel()

        viewModel.submitFinalVideoConfirmation()

        XCTAssertEqual(
            viewModel.finalVideoCommandState,
            .failed("Video creation is not configured for this build.")
        )
        XCTAssertEqual(viewModel.workflowErrorAlertMessage, "Video creation is not configured for this build.")
    }

    func testFinalVideoCommandTracksQueuedBackendJob() {
        let viewModel = AnimateCreateViewModel()
        let job = AnimateCreateTestFixtures.makeRenderJob(
            id: "render-job-1",
            kind: "final",
            status: "queued",
            userMessage: "Avi is creating your video."
        )

        viewModel.beginFinalVideoCommand(.confirming("Creating final video."))
        viewModel.applyFinalRenderState(
            AnimateCreateFinalRenderState(
                finalExport: nil,
                latestFinalJob: job,
                renderPlan: nil,
                statusMessage: "Creating final video.",
                isGenerating: false
            )
        )

        XCTAssertEqual(
            viewModel.finalVideoCommandState,
            .queued("Avi is creating your video.")
        )
        XCTAssertFalse(viewModel.finalVideoCommandState.isRunning)
        XCTAssertNil(viewModel.workflowErrorAlertMessage)
    }

    func testClearingFinalSessionAfterGalleryMoveRemovesDownloadState() {
        let viewModel = AnimateCreateViewModel()
        let finalExport = AnimateCreateTestFixtures.makeArtifact(id: "artifact-1", kind: "final_export")
        let galleryVideo = AnimateGalleryVideoRecord(
            id: "artifact-1",
            momentId: "moment-1",
            artifactId: "artifact-1",
            title: "Travel",
            r2Key: "animateav/artifact-1.mp4",
            localRelativePath: "artifact-1.mp4",
            createdAt: 1_780_000_000_000
        )

        viewModel.applyFinalRenderState(
            AnimateCreateFinalRenderState(
                finalExport: finalExport,
                latestFinalJob: nil,
                renderPlan: nil,
                pendingGalleryVideo: galleryVideo,
                statusMessage: "Saved locally.",
                isGenerating: false
            )
        )

        viewModel.clearFinalSessionAfterGalleryMove()

        XCTAssertNil(viewModel.finalExport)
        XCTAssertNil(viewModel.pendingGalleryVideo)
        XCTAssertNil(viewModel.latestFinalJob)
        XCTAssertNil(viewModel.workflowPresentation.finalRenderSummary.finalExport)
        XCTAssertNil(viewModel.workflowPresentation.finalRenderSummary.pendingGalleryVideo)
        XCTAssertFalse(viewModel.workflowPresentation.showsMediaFirstWorkspace)
    }

    func testBeginNewVideoWithoutPickerRequestShowsMediaChoice() {
        let viewModel = AnimateCreateViewModel()
        viewModel.beginNewVideoCreation()

        XCTAssertTrue(viewModel.hasLocalAnimateWorkspace)
        XCTAssertEqual(viewModel.mediaPickerOpenRequest, 0)
        XCTAssertTrue(viewModel.workflowPresentation.showsMediaFirstWorkspace)
    }

    func testBeginNewVideoCanExplicitlyOpenPhotoPicker() {
        let viewModel = AnimateCreateViewModel()
        viewModel.beginNewVideoCreation(openMediaPicker: true)

        XCTAssertTrue(viewModel.hasLocalAnimateWorkspace)
        XCTAssertEqual(viewModel.mediaPickerOpenRequest, 1)
    }

    func testFinalRenderUsesWorkspaceMediaIdentifiersAfterReload() {
        let harness = AnimateVideoCreationFailureHarness(error: NSError(domain: "test", code: 1))
        let workflow = harness.finalRenderWorkflow
        let workspaceMedia = [
            AnimateCreateTestFixtures.makeMediaAsset(
                id: "backend-media-2",
                sortOrder: 2,
                sourceLocalIdentifier: "platform-2"
            ),
            AnimateCreateTestFixtures.makeMediaAsset(
                id: "backend-media-1",
                sortOrder: 1,
                sourceLocalIdentifier: "platform-1"
            )
        ]

        XCTAssertEqual(
            workflow.selectedSourceLocalIdentifiersForFinalRender(from: [], workspaceMedia: workspaceMedia),
            ["platform-1", "platform-2"]
        )
    }

    func testFinalRenderDownloadUsesBackendWorkflowArtifactIdWhenAvailable() {
        let harness = AnimateVideoCreationFailureHarness(error: NSError(domain: "test", code: 1))
        let workflow = harness.finalRenderWorkflow
        let artifact = AnimateArtifact(
            id: "convex-artifact-doc",
            workflowArtifactId: "workflow-artifact-1",
            kind: "final_export",
            r2Key: "animateav/user/moment/final-exports/workflow-artifact-1.mp4",
            status: "available",
            hasWatermark: false,
            expiresAt: 0
        )

        XCTAssertEqual(workflow.finalDownloadArtifactId(for: artifact), "workflow-artifact-1")
    }

    func testFinalRenderPlanBlocksRecoveredWorkspaceWhenSourceMediaIsMissing() async {
        let harness = AnimateVideoCreationFailureHarness(error: NSError(domain: "test", code: 1))
        let workflow = harness.finalRenderWorkflow
        harness.publishWorkspace(
            AnimateWorkspace(
                video: AnimateCreateTestFixtures.makeVideo(id: "moment-1"),
                mediaAssets: [
                    AnimateCreateTestFixtures.makeMediaAsset(
                        id: "backend-media-1",
                        sourceLocalIdentifier: "missing-photos-asset"
                    )
                ],
                storyScenes: [],
                renderJobs: [],
                artifacts: []
            )
        )
        await Task.yield()

        await workflow.prepareFinalRenderPlan(
            momentId: "moment-1",
            template: .birthdayMessage,
            creationStyle: nil,
            form: AnimateVideoSetupForm(template: .birthdayMessage),
            selectedMedia: []
        )

        XCTAssertEqual(workflow.statusMessage, L10n.string("workflow.final.sourceMediaMissing"))
        XCTAssertFalse(workflow.isGenerating)
        XCTAssertNil(workflow.renderPlan)
    }

    func testFinalRenderPlanWithoutWatermarkIsCurrentForWatermarkedRender() {
        let plan = AnimateCreateTestFixtures.makeRenderPlan(momentId: "moment-1")

        XCTAssertFalse(
            FinalRenderWorkflow.needsRenderPlanForFinalRender(
                renderPlan: plan,
                momentId: "moment-1",
                removesWatermark: false
            )
        )
        XCTAssertTrue(
            FinalRenderWorkflow.needsRenderPlanForFinalRender(
                renderPlan: plan,
                momentId: "moment-1",
                removesWatermark: true
            )
        )
    }

    func testVisibleFinalRenderPlanCanBeConfirmedEvenWhenLocalSignatureChanged() {
        let viewModel = AnimateCreateViewModel()
        let plan = AnimateCreateTestFixtures.makeRenderPlan(momentId: "moment-1")

        viewModel.applyFinalRenderState(
            AnimateCreateFinalRenderState(
                finalExport: nil,
                latestFinalJob: nil,
                renderPlan: plan,
                statusMessage: nil,
                isGenerating: false
            )
        )

        XCTAssertTrue(viewModel.hasConfirmableRenderPlan(momentId: "moment-1"))
        XCTAssertEqual(viewModel.confirmableRenderPlan(momentId: "moment-1")?.planId, plan.planId)
        XCTAssertFalse(viewModel.hasConfirmableRenderPlan(momentId: "other-moment"))
    }

    func testBlockedFinalRenderPlanCannotBeConfirmed() {
        let viewModel = AnimateCreateViewModel()
        let plan = AnimateCreateTestFixtures.makeRenderPlan(
            momentId: "moment-1",
            canCreateVideo: false
        )

        viewModel.applyFinalRenderState(
            AnimateCreateFinalRenderState(
                finalExport: nil,
                latestFinalJob: nil,
                renderPlan: plan,
                statusMessage: nil,
                isGenerating: false
            )
        )

        XCTAssertFalse(viewModel.hasConfirmableRenderPlan(momentId: "moment-1"))
    }

    func testFinalVideoActionUsesBackendVideoQuoteCostWhenAvailable() {
        let summary = AnimateCreateFinalRenderSummary(
            creditCost: 1,
            renderPlan: AnimateCreateTestFixtures.makeRenderPlan(totalCreditCost: 2),
            videoQuote: AnimateVideoQuoteResponse(
                appId: "animateav",
                outputKind: "video",
                duration: .upTo15s,
                baseCreditCost: 3,
                brandingRemovalCreditCost: 1,
                totalCreditCost: 4,
                proIncludesBrandingFreeVideo: false,
                branding: AnimateVideoQuoteBranding(
                    enabled: true,
                    included: false,
                    removalAvailable: true,
                    removalRequested: true,
                    removalIncluded: false,
                    assetId: nil,
                    placement: nil,
                    reason: "branding_removal_purchased"
                )
            )
        )
        let action = AnimateCreateFinalVideoActionPresentation(
            summary: summary,
            template: .birthdayMessage,
            balance: AnimateCreditBalance(proMonthly: 0, promotional: 3, purchased: 0)
        )

        XCTAssertEqual(action.totalCreditCost, 4)
        XCTAssertFalse(action.canAffordSelectedCost)
    }

    func testInsufficientCreditRenderPlanClearsWhenBalanceCanCoverCost() {
        let viewModel = AnimateCreateViewModel()
        let plan = AnimateCreateTestFixtures.makeRenderPlan(
            momentId: "moment-1",
            canCreateVideo: false,
            totalCreditCost: 2,
            createVideoBlockers: ["insufficient_credits"]
        )

        viewModel.applyFinalRenderState(
            AnimateCreateFinalRenderState(
                finalExport: nil,
                latestFinalJob: nil,
                renderPlan: plan,
                statusMessage: nil,
                isGenerating: false
            )
        )
        XCTAssertEqual(viewModel.currentRenderPlan?.planId, plan.planId)

        viewModel.applyAccountState(
            AnimateCreateAccountState(
                isSignedIn: true,
                balance: AnimateCreditBalance(proMonthly: 0, promotional: 5, purchased: 0),
                creditBalanceLoadState: .loaded
            )
        )

        XCTAssertNil(viewModel.currentRenderPlan)
    }

    func testStoryScenesClearStaleErrorAndMarkCurrentInputPrepared() {
        let viewModel = AnimateCreateViewModel()
        let media = AnimateCreateTestFixtures.makeSelectedMedia(
            id: "00000000-0000-0000-0000-000000000001"
        )

        viewModel.applyVideoCreationState(
            AnimateCreateVideoCreationState(
                isCreatingVideo: false,
                activeVideoId: "moment-1",
                setupErrorMessage: nil
            )
        )
        viewModel.applyMediaUploadState(
            AnimateCreateMediaUploadState(
                selectedMedia: [media],
                statusMessage: nil,
                isImporting: false,
                importProgress: nil
            )
        )
        viewModel.applyStoryState(
            AnimateCreateStoryState(
                activeWorkspace: nil,
                savedScenes: [],
                generatedScenes: [],
                statusMessage: AnimateRecoveryCopy.storyFailure(),
                isPlanning: false
            )
        )

        XCTAssertEqual(viewModel.videoDirectionSummary.statusMessage, AnimateRecoveryCopy.storyFailure())
        XCTAssertFalse(viewModel.isStoryPreparedForCurrentInput)

        viewModel.applyStoryState(
            AnimateCreateStoryState(
                activeWorkspace: nil,
                savedScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
                generatedScenes: [],
                statusMessage: AnimateRecoveryCopy.storyFailure(),
                isPlanning: false
            )
        )

        XCTAssertNil(viewModel.videoDirectionSummary.statusMessage)
        XCTAssertTrue(viewModel.isStoryPreparedForCurrentInput)
    }

    func testCurrentStorySignaturePrefersLocalMediaWhenWorkspaceHasUploadedMedia() {
        let viewModel = AnimateCreateViewModel()
        let localMedia = AnimateCreateTestFixtures.makeSelectedMedia(
            id: "00000000-0000-0000-0000-000000000001",
            sourceLocalIdentifier: "local-asset-1"
        )

        viewModel.applyVideoCreationState(
            AnimateCreateVideoCreationState(
                isCreatingVideo: false,
                activeVideoId: "moment-1",
                setupErrorMessage: nil
            )
        )
        viewModel.applyMediaUploadState(
            AnimateCreateMediaUploadState(
                selectedMedia: [localMedia],
                statusMessage: nil,
                isImporting: false,
                importProgress: nil
            )
        )

        viewModel.applyStoryState(
            AnimateCreateStoryState(
                activeWorkspace: AnimateWorkspace(
                    video: AnimateCreateTestFixtures.makeVideo(id: "moment-1"),
                    mediaAssets: [
                        AnimateCreateTestFixtures.makeMediaAsset(
                            id: "backend-media-1",
                            sortOrder: 0
                        )
                    ],
                    storyScenes: [],
                    renderJobs: [],
                    artifacts: []
                ),
                savedScenes: [],
                generatedScenes: [],
                statusMessage: nil,
                isPlanning: false
            )
        )

        let expectedLocalSignature = viewModel.currentVideoDirectionInputSignature(
            momentId: "moment-1",
            persistedMedia: [
                AnimateVideoDirectionMedia(
                    mediaAssetId: localMedia.id.uuidString,
                    mediaKind: localMedia.kind,
                    sortOrder: localMedia.sortOrder,
                    selected: localMedia.selected,
                    moderationStatus: "pending"
                )
            ]
        )
        let backendMediaSignature = viewModel.currentVideoDirectionInputSignature(
            momentId: "moment-1",
            persistedMedia: [
                AnimateVideoDirectionMedia(
                    mediaAssetId: "backend-media-1",
                    mediaKind: "image",
                    sortOrder: 0,
                    selected: true,
                    moderationStatus: "approved"
                )
            ]
        )

        XCTAssertEqual(viewModel.currentVideoDirectionInputSignature(momentId: "moment-1"), expectedLocalSignature)
        XCTAssertNotEqual(viewModel.currentVideoDirectionInputSignature(momentId: "moment-1"), backendMediaSignature)
    }

    func testWorkspaceSignatureReconcilesAfterStoryScenesArriveFirst() {
        let viewModel = AnimateCreateViewModel()
        let localMedia = AnimateCreateTestFixtures.makeSelectedMedia(
            id: "00000000-0000-0000-0000-000000000001",
            sourceLocalIdentifier: "local-asset-1"
        )
        let backendMedia = makeBackendMedia()
        let backendSignature = viewModel.currentVideoDirectionInputSignature(
            momentId: "moment-1",
            persistedMedia: [makeStoryMedia(from: backendMedia)]
        )

        viewModel.applyVideoCreationState(
            AnimateCreateVideoCreationState(
                isCreatingVideo: false,
                activeVideoId: "moment-1",
                setupErrorMessage: nil
            )
        )
        viewModel.applyMediaUploadState(
            AnimateCreateMediaUploadState(
                selectedMedia: [localMedia],
                statusMessage: nil,
                isImporting: false,
                importProgress: nil
            )
        )

        viewModel.applyStoryState(
            AnimateCreateStoryState(
                activeWorkspace: nil,
                savedScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
                generatedScenes: [],
                statusMessage: nil,
                isPlanning: false
            )
        )
        XCTAssertTrue(viewModel.isStoryPreparedForCurrentInput)

        viewModel.applyStoryState(
            AnimateCreateStoryState(
                activeWorkspace: AnimateWorkspace(
                    video: AnimateCreateTestFixtures.makeVideo(
                        id: "moment-1",
                        occasion: "Birthday",
                        storyInputSignature: backendSignature
                    ),
                    mediaAssets: [backendMedia],
                    storyScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
                    renderJobs: [],
                    artifacts: []
                ),
                savedScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
                generatedScenes: [],
                statusMessage: nil,
                isPlanning: false
            )
        )

        XCTAssertEqual(viewModel.lastPreparedVideoDirectionInputSignature, backendSignature)
        XCTAssertTrue(viewModel.isStoryPreparedForCurrentInput)
    }

    func testRestoredLocalMediaDoesNotInvalidatePreparedBackendStory() {
        let viewModel = AnimateCreateViewModel()
        let syncedLocalMedia = AnimateCreateTestFixtures.makeSelectedMedia(
            id: "00000000-0000-0000-0000-000000000001",
            sourceLocalIdentifier: "local-asset-1"
        )
        let preparedStory = applyPreparedBackendStory(to: viewModel)
        viewModel.applyMediaUploadState(
            AnimateCreateMediaUploadState(
                selectedMedia: [syncedLocalMedia],
                statusMessage: nil,
                isImporting: false,
                importProgress: nil
            )
        )

        XCTAssertEqual(viewModel.currentVideoDirectionInputSignature(momentId: "moment-1"), preparedStory.signature)
        XCTAssertTrue(viewModel.isStoryPreparedForCurrentInput)
    }

    func testDirectionChangeInvalidatesPreparedBackendStoryWithRestoredLocalMedia() {
        let viewModel = AnimateCreateViewModel()
        applyPreparedBackendStory(to: viewModel)

        XCTAssertTrue(viewModel.isStoryPreparedForCurrentInput)

        viewModel.form.details = "Make this more cinematic."

        XCTAssertFalse(viewModel.isStoryPreparedForCurrentInput)
    }

    func testExplicitMediaEditInvalidatesPreparedBackendStory() {
        let viewModel = AnimateCreateViewModel()
        let preparedStory = applyPreparedBackendStory(to: viewModel)

        XCTAssertTrue(viewModel.isStoryPreparedForCurrentInput)

        viewModel.markPreparedVideoDirectionMediaEdited()
        viewModel.applyMediaUploadState(
            AnimateCreateMediaUploadState(
                selectedMedia: [
                    AnimateCreateTestFixtures.makeSelectedMedia(
                        id: "00000000-0000-0000-0000-000000000002",
                        sourceLocalIdentifier: "local-asset-extra"
                    )
                ],
                statusMessage: nil,
                isImporting: false,
                importProgress: nil
            )
        )

        XCTAssertFalse(viewModel.isStoryPreparedForCurrentInput)

        viewModel.applyStoryState(
            AnimateCreateStoryState(
                activeWorkspace: AnimateWorkspace(
                    video: AnimateCreateTestFixtures.makeVideo(
                        id: "moment-1",
                        occasion: "Birthday",
                        storyInputSignature: preparedStory.signature
                    ),
                    mediaAssets: [preparedStory.media],
                    storyScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
                    renderJobs: [],
                    artifacts: []
                ),
                savedScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
                generatedScenes: [],
                statusMessage: nil,
                isPlanning: false
            )
        )

        XCTAssertFalse(viewModel.isStoryPreparedForCurrentInput)
    }

    func testExplicitMediaEditInvalidatesPreparedFinalRenderPlan() {
        let viewModel = AnimateCreateViewModel()
        applyPreparedBackendStory(to: viewModel)
        viewModel.applyFinalRenderState(
            AnimateCreateFinalRenderState(
                finalExport: nil,
                latestFinalJob: nil,
                renderPlan: AnimateCreateTestFixtures.makeRenderPlan(),
                statusMessage: nil,
                isGenerating: false
            )
        )

        XCTAssertNotNil(viewModel.currentRenderPlan)

        viewModel.markPreparedVideoDirectionMediaEdited()

        XCTAssertNil(viewModel.currentRenderPlan)
        XCTAssertNil(viewModel.finalRenderSummary.renderPlan)
    }

    func testSyncedBackendMediaIdsDoNotInvalidatePreparedFinalRenderPlan() {
        let viewModel = AnimateCreateViewModel()
        let localMedia = AnimateCreateTestFixtures.makeSelectedMedia(
            id: "00000000-0000-0000-0000-000000000001",
            sourceLocalIdentifier: "local-asset-1"
        )
        viewModel.applyVideoCreationState(
            AnimateCreateVideoCreationState(
                isCreatingVideo: false,
                activeVideoId: "moment-1",
                setupErrorMessage: nil
            )
        )
        viewModel.applyMediaUploadState(
            AnimateCreateMediaUploadState(
                selectedMedia: [localMedia],
                statusMessage: nil,
                isImporting: false,
                importProgress: nil
            )
        )
        viewModel.applyFinalRenderState(
            AnimateCreateFinalRenderState(
                finalExport: nil,
                latestFinalJob: nil,
                renderPlan: AnimateCreateTestFixtures.makeRenderPlan(),
                statusMessage: nil,
                isGenerating: false
            )
        )

        let signatureBeforeSync = viewModel.currentFinalRenderInputSignatureSource(momentId: "moment-1")
        XCTAssertNotNil(viewModel.currentRenderPlan)

        viewModel.applyStoryState(
            AnimateCreateStoryState(
                activeWorkspace: AnimateWorkspace(
                    video: AnimateCreateTestFixtures.makeVideo(
                        id: "moment-1",
                        template: .partyRecap,
                        theme: "eventRecap",
                        mood: "warm",
                        duration: "auto",
                        mediaUse: "aviPick",
                        occasion: "Event Recap",
                        details: ""
                    ),
                    mediaAssets: [
                        AnimateCreateTestFixtures.makeMediaAsset(
                            id: "backend-media-1",
                            sourceLocalIdentifier: "local-asset-1"
                        )
                    ],
                    storyScenes: [],
                    renderJobs: [],
                    artifacts: []
                ),
                savedScenes: [],
                generatedScenes: [],
                statusMessage: nil,
                isPlanning: false
            )
        )

        let signatureAfterSync = viewModel.currentFinalRenderInputSignatureSource(momentId: "moment-1")
        XCTAssertEqual(signatureBeforeSync, signatureAfterSync, "\(viewModel.form)")
        XCTAssertNotNil(viewModel.currentRenderPlan)
        XCTAssertNotNil(viewModel.finalRenderSummary.renderPlan)
    }

    func testGenerateStoryShowsImmediateVideoCreationError() async {
        let harness = AnimateVideoCreationFailureHarness(error: AnimateSyncError.notConfigured)
        let viewModel = AnimateCreateViewModel()
        viewModel.bind(
            accountStateProvider: harness,
            videoCreationWorkflow: harness.videoCreationWorkflow,
            mediaUploadWorkflow: harness.mediaUploadWorkflow,
            videoDirectionWorkflow: harness.videoDirectionWorkflow,
            finalRenderWorkflow: harness.finalRenderWorkflow,
            authTokenProvider: harness,
            imageGenerationAccountingClient: AnimateImageGenerationAccountingClient(baseURLString: "https://api.example.test")
        )
        await Task.yield()
        await Task.yield()
        viewModel.applyAccountState(
            AnimateCreateAccountState(
                isSignedIn: true,
                balance: AnimateCreditBalance(proMonthly: 0, promotional: 15, purchased: 0),
                creditBalanceLoadState: .loaded
            )
        )
        viewModel.beginNewVideoCreation(openMediaPicker: false)
        viewModel.applyMediaUploadState(
            AnimateCreateMediaUploadState(
                selectedMedia: [
                    AnimateCreateTestFixtures.makeSelectedMedia(
                        id: "00000000-0000-0000-0000-000000000001"
                    )
                ],
                statusMessage: nil,
                isImporting: false,
                importProgress: nil
            )
        )

        viewModel.prepareVideoDirection()
        await fulfillment(of: [harness.createAttemptExpectation], timeout: 1)
        await waitForStoryStatusMessage(in: viewModel)

        XCTAssertEqual(viewModel.videoDirectionSummary.statusMessage, AnimateSyncError.notConfigured.localizedDescription)
    }

    @discardableResult
    private func applyPreparedBackendStory(
        to viewModel: AnimateCreateViewModel,
        momentId: String = "moment-1"
    ) -> (media: AnimateMediaAsset, signature: String) {
        let media = makeBackendMedia()
        viewModel.applyVideoCreationState(
            AnimateCreateVideoCreationState(
                isCreatingVideo: false,
                activeVideoId: momentId,
                setupErrorMessage: nil
            )
        )
        let signature = viewModel.currentVideoDirectionInputSignature(
            momentId: momentId,
            persistedMedia: [makeStoryMedia(from: media)]
        )
        viewModel.applyStoryState(
            AnimateCreateStoryState(
                activeWorkspace: AnimateWorkspace(
                    video: AnimateCreateTestFixtures.makeVideo(
                        id: momentId,
                        occasion: "Birthday",
                        storyInputSignature: signature
                    ),
                    mediaAssets: [media],
                    storyScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
                    renderJobs: [],
                    artifacts: []
                ),
                savedScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
                generatedScenes: [],
                statusMessage: nil,
                isPlanning: false
            )
        )

        return (media, signature)
    }

    private func makeBackendMedia() -> AnimateMediaAsset {
        AnimateMediaAsset(
            id: "backend-media-1",
            platformMediaAssetId: "local-asset-1",
            uploadId: "upload-backend-media-1",
            kind: "image",
            sortOrder: 0,
            selected: true,
            moderationStatus: "approved",
            uploadedAt: nil,
            sourceExpiresAt: nil
        )
    }

    private func makeStoryMedia(from media: AnimateMediaAsset) -> AnimateVideoDirectionMedia {
        AnimateVideoDirectionMedia(
            mediaAssetId: media.id,
            mediaKind: media.kind,
            sortOrder: Int(media.sortOrder),
            selected: media.selected,
            moderationStatus: media.moderationStatus
        )
    }

    private func waitForStoryStatusMessage(in viewModel: AnimateCreateViewModel) async {
        for _ in 0..<20 where viewModel.videoDirectionSummary.statusMessage == nil {
            try? await Task.sleep(nanoseconds: 25_000_000)
        }
    }
}

@MainActor
private final class AnimateVideoCreationFailureHarness:
    AnimateAccountStateProviding,
    AnimateCurrentUserProviding,
    AnimateAuthTokenProviding,
    AnimateCreditBalanceProviding,
    AnimateVideoCreating,
    AnimateVideoDeleting,
    AnimateActiveWorkspaceObserving
{
    let createAttemptExpectation = XCTestExpectation(description: "Video creation attempted")
    private let creationError: Error
    private let signedInSubject = CurrentValueSubject<Bool, Never>(true)
    private let currentUserSubject = CurrentValueSubject<String?, Never>("user-1")
    private let displayNameSubject = CurrentValueSubject<String?, Never>("Ava")
    private let balanceSubject = CurrentValueSubject<AnimateCreditBalance, Never>(
        AnimateCreditBalance(proMonthly: 0, promotional: 15, purchased: 0)
    )
    private let creditBalanceLoadStateSubject = CurrentValueSubject<AnimateCreditBalanceLoadState, Never>(.loaded)
    private let workspaceSubject = CurrentValueSubject<AnimateWorkspace?, Never>(nil)
    private let workspaceErrorSubject = CurrentValueSubject<String?, Never>(nil)

    init(error: Error) {
        creationError = error
    }

    var videoCreationWorkflow: AnimateVideoCreationWorkflow {
        AnimateVideoCreationWorkflow(
            currentUserProvider: self,
            authTokenProvider: self,
            creditBalanceProvider: self,
            videoCreator: self,
            videoDeleter: self,
            workspaceObserver: self
        )
    }

    var mediaUploadWorkflow: MediaUploadWorkflow {
        MediaUploadWorkflow(
            currentUserProvider: self,
            authTokenProvider: self,
            workspaceObserver: self,
            uploadClient: AnimateUploadClient(baseURLString: "https://api.example.com")
        )
    }

    var videoDirectionWorkflow: VideoDirectionWorkflow {
        VideoDirectionWorkflow(
            currentUserProvider: self,
            authTokenProvider: self,
            workspaceObserver: self,
            videoDirectionClient: AnimateVideoDirectionClient(baseURLString: "https://api.example.com")
        )
    }

    var finalRenderWorkflow: FinalRenderWorkflow {
        FinalRenderWorkflow(
            currentUserProvider: self,
            authTokenProvider: self,
            creditBalanceProvider: self,
            workspaceObserver: self,
            finalRenderClient: AnimateFinalRenderClient(baseURLString: "https://api.example.com"),
            galleryStore: TestGalleryStore()
        )
    }

    var isSignedInPublisher: AnyPublisher<Bool, Never> {
        signedInSubject.eraseToAnyPublisher()
    }

    var currentUserIdPublisher: AnyPublisher<String?, Never> {
        currentUserSubject.eraseToAnyPublisher()
    }

    var displayNamePublisher: AnyPublisher<String?, Never> {
        displayNameSubject.eraseToAnyPublisher()
    }

    var creditBalancePublisher: AnyPublisher<AnimateCreditBalance, Never> {
        balanceSubject.eraseToAnyPublisher()
    }

    var creditBalanceLoadStatePublisher: AnyPublisher<AnimateCreditBalanceLoadState, Never> {
        creditBalanceLoadStateSubject.eraseToAnyPublisher()
    }

    var currentUserId: String? {
        currentUserSubject.value
    }

    var currentCreditBalance: AnimateCreditBalance {
        balanceSubject.value
    }

    func refreshCreditBalance() async {}

    var isConfigured: Bool {
        true
    }

    var activeWorkspacePublisher: AnyPublisher<AnimateWorkspace?, Never> {
        workspaceSubject.eraseToAnyPublisher()
    }

    var workspaceErrorPublisher: AnyPublisher<String?, Never> {
        workspaceErrorSubject.eraseToAnyPublisher()
    }

    func currentBearerToken() async throws -> String? {
        "token-1"
    }

    func createVideo(bearerToken: String, form: AnimateVideoSetupForm) async throws -> String {
        createAttemptExpectation.fulfill()
        throw creationError
    }

    func updateVideoSetup(bearerToken: String, momentId: String, form: AnimateVideoSetupForm) async throws {}

    func deleteVideo(bearerToken: String, momentId: String) async throws {}

    func observeWorkspace(ownerUserId: String?, momentId: String?) {}

    func clearWorkspace() {
        workspaceSubject.send(nil)
    }

    func publishWorkspace(_ workspace: AnimateWorkspace) {
        workspaceSubject.send(workspace)
    }

}

private struct TestGalleryStore: AnimateGalleryStoring {
    func loadRecords() -> [AnimateGalleryVideoRecord] { [] }
    func saveRecords(_ records: [AnimateGalleryVideoRecord]) {}
    func localFileExists(for record: AnimateGalleryVideoRecord) -> Bool { false }
    func localFileURL(for record: AnimateGalleryVideoRecord) -> URL { URL(fileURLWithPath: "/tmp/\(record.id).mp4") }
    func contains(artifactId: String) -> Bool { false }
    func saveDownloadedVideo(
        temporaryFileURL: URL,
        momentId: String,
        artifactId: String,
        title: String,
        r2Key: String,
        createdAt: Date
    ) throws -> AnimateGalleryVideoRecord {
        AnimateGalleryVideoRecord(
            id: artifactId,
            momentId: momentId,
            artifactId: artifactId,
            title: title,
            r2Key: r2Key,
            localRelativePath: "\(artifactId).mp4",
            createdAt: createdAt.timeIntervalSince1970 * 1000
        )
    }
    func addRecord(_ record: AnimateGalleryVideoRecord) {}
    func renameRecord(_ record: AnimateGalleryVideoRecord, title: String) {}
    func deleteRecord(_ record: AnimateGalleryVideoRecord, deleteLocalFile: Bool) {}
}
