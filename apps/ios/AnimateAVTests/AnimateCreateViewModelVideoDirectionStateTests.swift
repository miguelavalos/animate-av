import XCTest
import Combine
@testable import AnimateAV

@MainActor
final class AnimateCreateViewModelVideoDirectionStateTests: XCTestCase {
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

    func testFinalVideoCommandFailsWhenConfirmationReturnsWithoutJob() {
        let viewModel = AnimateCreateViewModel()

        viewModel.beginFinalVideoCommand(.confirming("Creating final video."))
        viewModel.applyFinalRenderState(
            AnimateCreateFinalRenderState(
                finalExport: nil,
                latestFinalJob: nil,
                renderPlan: AnimateCreateTestFixtures.makeRenderPlan(videoId: "video-1"),
                statusMessage: L10n.string("workflow.final.tryAgain"),
                isGenerating: false
            )
        )

        XCTAssertEqual(
            viewModel.finalVideoCommandState,
            .failed(L10n.string("workflow.final.tryAgain"))
        )
        XCTAssertEqual(viewModel.workflowErrorAlertMessage, L10n.string("workflow.final.tryAgain"))
    }

    func testFinalVideoCommandShowsSavingOnlyWhileFinalVideoSaveIsActive() {
        let viewModel = AnimateCreateViewModel()
        let finalExport = AnimateCreateTestFixtures.makeArtifact(id: "artifact-1", kind: "final_export")

        viewModel.applyFinalRenderState(
            AnimateCreateFinalRenderState(
                finalExport: finalExport,
                latestFinalJob: nil,
                renderPlan: nil,
                isSavingFinalVideo: true,
                statusMessage: L10n.string("workflow.final.savingToGallery"),
                isGenerating: false
            )
        )

        XCTAssertEqual(
            viewModel.finalVideoCommandState,
            .confirming(L10n.string("workflow.final.savingToGallery"))
        )
    }

    func testFinalVideoCommandDoesNotStaySavingWhenFinalVideoSaveIsNotActive() {
        let viewModel = AnimateCreateViewModel()
        let finalExport = AnimateCreateTestFixtures.makeArtifact(id: "artifact-1", kind: "final_export")

        viewModel.applyFinalRenderState(
            AnimateCreateFinalRenderState(
                finalExport: finalExport,
                latestFinalJob: nil,
                renderPlan: nil,
                statusMessage: nil,
                isGenerating: false
            )
        )

        XCTAssertEqual(
            viewModel.finalVideoCommandState,
            .failed(L10n.string("workflow.final.saveLocalFailed"))
        )
        XCTAssertEqual(viewModel.workflowErrorAlertMessage, L10n.string("workflow.final.saveLocalFailed"))
    }

    func testClearingFinalSessionAfterGalleryMoveRemovesDownloadState() {
        let viewModel = AnimateCreateViewModel()
        let finalExport = AnimateCreateTestFixtures.makeArtifact(id: "artifact-1", kind: "final_export")
        let galleryVideo = AnimateGalleryVideoRecord(
            id: "artifact-1",
            videoId: "video-1",
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
        XCTAssertTrue(viewModel.workflowPresentation.showsMediaFirstWorkspace)
        XCTAssertTrue(viewModel.hasLocalAnimateWorkspace)
        XCTAssertEqual(viewModel.workflowPresentation.mediaSummary.selectedCount, 0)
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
            r2Key: "animateav/user/video/final-exports/workflow-artifact-1.mp4",
            status: "available",
            hasWatermark: false,
            expiresAt: 0
        )

        XCTAssertEqual(workflow.finalDownloadArtifactId(for: artifact), "workflow-artifact-1")
    }

    func testRestoredFinalExportWithoutBearerTokenBecomesRetryableSaveFailure() async {
        let harness = AnimateVideoCreationFailureHarness(error: NSError(domain: "test", code: 1))
        harness.bearerToken = nil
        let workflow = harness.finalRenderWorkflow
        let workspace = AnimateWorkspace(
            video: AnimateCreateTestFixtures.makeVideo(id: "video-1", status: "completed"),
            mediaAssets: [],
            videoDirectionScenes: [],
            renderJobs: [],
            artifacts: [
                AnimateCreateTestFixtures.makeArtifact(id: "artifact-1", kind: "final_export")
            ]
        )

        harness.publishWorkspace(workspace)
        for _ in 0..<20 where workflow.isSavingFinalVideo || !workflow.canRetryFinalVideoDownload {
            await Task.yield()
            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        XCTAssertFalse(workflow.isSavingFinalVideo)
        XCTAssertTrue(workflow.canRetryFinalVideoDownload)
        XCTAssertEqual(workflow.statusMessage, L10n.string("workflow.final.signInAgainSaveLocal"))
    }

    func testFinalRenderSummaryUsesExistingGeneratedImagePreviewDuringVideoLoading() async {
        let generatedImage = AnimateGalleryImageRecord(
            id: "generated-image-1",
            artifactId: "generated-image-1",
            title: "Generated image",
            look: "cinematic",
            r2Key: "animateav/generated-image-1.jpg",
            localRelativePath: "Images/generated-image-1.jpg",
            createdAt: 1_780_000_000_000
        )
        let harness = AnimateVideoCreationFailureHarness(
            error: NSError(domain: "test", code: 1),
            galleryStore: TestGalleryStore(
                imageRecords: [generatedImage],
                localImageRelativePaths: ["Images/generated-image-1.jpg"]
            )
        )
        let finalRenderWorkflow = harness.finalRenderWorkflow
        let viewModel = AnimateCreateViewModel()
        viewModel.bind(
            accountStateProvider: harness,
            videoCreationWorkflow: harness.videoCreationWorkflow,
            mediaUploadWorkflow: harness.mediaUploadWorkflow,
            videoDirectionWorkflow: harness.videoDirectionWorkflow,
            finalRenderWorkflow: finalRenderWorkflow,
            authTokenProvider: harness,
            imageGenerationAccountingClient: AnimateImageGenerationAccountingClient(baseURLString: "https://api.example.test")
        )

        harness.publishWorkspace(
            AnimateWorkspace(
                video: AnimateCreateTestFixtures.makeVideo(id: "video-1", status: "rendering"),
                mediaAssets: [],
                videoDirectionScenes: [],
                renderJobs: [
                    AnimateCreateTestFixtures.makeRenderJob(
                        id: "final-render-1",
                        kind: "final",
                        status: "running",
                        phase: "animating_video"
                    )
                ],
                artifacts: [
                    AnimateArtifact(
                        id: "generated-image-1",
                        kind: "generated_image",
                        r2Key: "animateav/generated-image-1.jpg",
                        title: nil,
                        look: "cinematic",
                        status: "available",
                        hasWatermark: false,
                        expiresAt: 1_781_592_000_000,
                        createdAt: 1_780_000_000_000
                    )
                ]
            )
        )
        await waitForGeneratedImagePreview(in: viewModel)

        XCTAssertEqual(finalRenderWorkflow.pendingGalleryImage?.localRelativePath, "Images/generated-image-1.jpg")
        XCTAssertEqual(
            viewModel.workflowPresentation.finalRenderSummary.generatedImagePreviewLocalRelativePath,
            "Images/generated-image-1.jpg"
        )
        XCTAssertEqual(
            viewModel.workflowPresentation.finalRenderSummary.realtimeStatus?.visualStage,
            .animatingVideo
        )
    }

    func testFinalRenderPlanBlocksRecoveredWorkspaceWhenSourceMediaIsMissing() async {
        let harness = AnimateVideoCreationFailureHarness(error: NSError(domain: "test", code: 1))
        let workflow = harness.finalRenderWorkflow
        harness.publishWorkspace(
            AnimateWorkspace(
                video: AnimateCreateTestFixtures.makeVideo(id: "video-1"),
                mediaAssets: [
                    AnimateCreateTestFixtures.makeMediaAsset(
                        id: "backend-media-1",
                        sourceLocalIdentifier: "missing-photos-asset",
                        hasUploadId: false
                    )
                ],
                videoDirectionScenes: [],
                renderJobs: [],
                artifacts: []
            )
        )
        await Task.yield()

        await workflow.prepareFinalRenderPlan(
            videoId: "video-1",
            template: .birthdayMessage,
            creationStyle: nil,
            form: AnimateVideoSetupForm(template: .birthdayMessage),
            selectedMedia: []
        )

        XCTAssertEqual(workflow.statusMessage, L10n.string("workflow.final.sourceMediaMissing"))
        XCTAssertFalse(workflow.isGenerating)
        XCTAssertNil(workflow.renderPlan)
    }

    func testFinalRenderPlanAllowsRecoveredWorkspaceWhenSourceMediaIsSynced() async {
        let harness = AnimateVideoCreationFailureHarness(error: NSError(domain: "test", code: 1))
        let workflow = harness.finalRenderWorkflow
        harness.publishWorkspace(
            AnimateWorkspace(
                video: AnimateCreateTestFixtures.makeVideo(id: "video-1"),
                mediaAssets: [
                    AnimateCreateTestFixtures.makeMediaAsset(
                        id: "backend-media-1",
                        sourceLocalIdentifier: "backend-source-1"
                    )
                ],
                videoDirectionScenes: [],
                renderJobs: [],
                artifacts: []
            )
        )
        await Task.yield()

        await workflow.prepareFinalRenderPlan(
            videoId: "video-1",
            template: .birthdayMessage,
            creationStyle: nil,
            form: AnimateVideoSetupForm(template: .birthdayMessage),
            selectedMedia: []
        )

        XCTAssertNotEqual(workflow.statusMessage, L10n.string("workflow.final.sourceMediaMissing"))
    }

    func testClearingFinalRenderPlanInvalidatesPendingCostPreparation() async {
        AnimateFinalRenderURLProtocolMock.reset()
        AnimateFinalRenderURLProtocolMock.responseData = Data(Self.renderPlanWithoutBrandingJSON.utf8)
        AnimateFinalRenderURLProtocolMock.responseDelayNanoseconds = 200_000_000
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AnimateFinalRenderURLProtocolMock.self]
        let harness = AnimateVideoCreationFailureHarness(
            error: NSError(domain: "test", code: 1),
            finalRenderSession: URLSession(configuration: configuration)
        )
        let workflow = harness.finalRenderWorkflow
        harness.publishWorkspace(
            AnimateWorkspace(
                video: AnimateCreateTestFixtures.makeVideo(id: "video-1", status: "video_direction_ready"),
                mediaAssets: [
                    AnimateCreateTestFixtures.makeMediaAsset(
                        id: "backend-media-1",
                        sourceLocalIdentifier: "local-asset-1",
                        hasUploadId: true
                    )
                ],
                videoDirectionScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
                renderJobs: [],
                artifacts: []
            )
        )
        await Task.yield()

        let selectedMedia = [
            AnimateCreateTestFixtures.makeSelectedMedia(
                id: "00000000-0000-0000-0000-000000000001",
                sourceLocalIdentifier: "local-asset-1"
            )
        ]
        let preparationTask = Task {
            await workflow.prepareFinalRenderPlan(
                videoId: "video-1",
                template: .birthdayMessage,
                creationStyle: nil,
                form: AnimateVideoSetupForm(template: .birthdayMessage),
                selectedMedia: selectedMedia
            )
        }

        for _ in 0..<40 where AnimateFinalRenderURLProtocolMock.requestCount == 0 {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTAssertEqual(AnimateFinalRenderURLProtocolMock.requestCount, 1)
        XCTAssertTrue(workflow.isGenerating)
        XCTAssertEqual(workflow.statusMessage, L10n.string("workflow.final.checkingPlan"))

        workflow.clearRenderPlan(invalidateActiveGeneration: true)

        XCTAssertFalse(workflow.isGenerating)
        XCTAssertNil(workflow.statusMessage)
        XCTAssertNil(workflow.renderPlan)

        await preparationTask.value

        XCTAssertFalse(workflow.isGenerating)
        XCTAssertNil(workflow.statusMessage)
        XCTAssertNil(workflow.renderPlan)
    }

    func testFinalRenderPlanWithoutWatermarkIsCurrentForWatermarkedRender() {
        let plan = AnimateCreateTestFixtures.makeRenderPlan(videoId: "video-1")

        XCTAssertFalse(
            FinalRenderWorkflow.needsRenderPlanForFinalRender(
                renderPlan: plan,
                videoId: "video-1",
                removesWatermark: false
            )
        )
        XCTAssertTrue(
            FinalRenderWorkflow.needsRenderPlanForFinalRender(
                renderPlan: plan,
                videoId: "video-1",
                removesWatermark: true
            )
        )
    }

    func testConfirmPreparedFinalRenderPublishesQueuedJobFromMockedBackendResponse() async {
        AnimateFinalRenderURLProtocolMock.reset()
        AnimateFinalRenderURLProtocolMock.responseData = Data(Self.confirmFinalRenderJSON.utf8)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AnimateFinalRenderURLProtocolMock.self]
        let harness = AnimateVideoCreationFailureHarness(
            error: NSError(domain: "test", code: 1),
            finalRenderSession: URLSession(configuration: configuration)
        )
        let workflow = harness.finalRenderWorkflow
        let plan = AnimateCreateTestFixtures.makeRenderPlan(videoId: "video-1")
        harness.publishWorkspace(
            AnimateWorkspace(
                video: AnimateCreateTestFixtures.makeVideo(id: "video-1"),
                mediaAssets: [
                    AnimateCreateTestFixtures.makeMediaAsset(id: "backend-media-1", hasUploadId: true)
                ],
                videoDirectionScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
                renderJobs: [],
                artifacts: []
            )
        )
        await Task.yield()
        workflow.usePreparedRenderPlan(plan)

        await workflow.confirmPreparedFinalRender(
            videoId: "video-1",
            template: .birthdayMessage,
            creationStyle: nil,
            form: AnimateVideoSetupForm(template: .birthdayMessage),
            selectedMedia: [],
            removesWatermark: false
        )

        XCTAssertEqual(AnimateFinalRenderURLProtocolMock.requestCount, 1)
        XCTAssertEqual(
            AnimateFinalRenderURLProtocolMock.lastRequest?.url?.absoluteString,
            "https://api.example.com/v1/apps/animateav/renders/final/confirm"
        )
        XCTAssertEqual(workflow.latestFinalJob?.id, "render-1")
        XCTAssertEqual(workflow.latestFinalJob?.status, "running")
        XCTAssertFalse(workflow.isGenerating)
    }

    func testConfirmPreparedFinalRenderReusesWorkspaceUploadIdForSelectedSourceImage() async throws {
        AnimateFinalRenderURLProtocolMock.reset()
        AnimateFinalRenderURLProtocolMock.responseData = Data(Self.confirmFinalRenderJSON.utf8)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AnimateFinalRenderURLProtocolMock.self]
        let session = URLSession(configuration: configuration)
        let harness = AnimateVideoCreationFailureHarness(
            error: NSError(domain: "test", code: 1),
            finalRenderSession: session,
            uploadSession: session
        )
        let workflow = harness.finalRenderWorkflow
        workflow.usePreparedRenderPlan(AnimateCreateTestFixtures.makeRenderPlan(videoId: "video-1"))
        harness.publishWorkspace(
            AnimateWorkspace(
                video: AnimateCreateTestFixtures.makeVideo(id: "video-1"),
                mediaAssets: [
                    AnimateCreateTestFixtures.makeMediaAsset(
                        id: "backend-media-1",
                        sourceLocalIdentifier: "local-asset-1",
                        hasUploadId: true
                    )
                ],
                videoDirectionScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
                renderJobs: [],
                artifacts: []
            )
        )
        await Task.yield()

        await workflow.confirmPreparedFinalRender(
            videoId: "video-1",
            template: .birthdayMessage,
            creationStyle: nil,
            form: AnimateVideoSetupForm(template: .birthdayMessage),
            selectedMedia: [
                AnimateCreateTestFixtures.makeSelectedMedia(
                    id: "00000000-0000-0000-0000-000000000001",
                    sourceLocalIdentifier: "local-asset-1"
                )
            ],
            removesWatermark: false
        )

        XCTAssertEqual(AnimateFinalRenderURLProtocolMock.requestPaths, [
            "/v1/apps/animateav/renders/final/confirm",
        ])
        let body = try XCTUnwrap(AnimateFinalRenderURLProtocolMock.lastRequestBody)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: body) as? [String: Any])
        XCTAssertEqual(json["sourceImageUploadId"] as? String, "upload-backend-media-1")
        XCTAssertEqual(workflow.latestFinalJob?.id, "render-1")
        XCTAssertFalse(workflow.isGenerating)
    }

    func testSubmitFinalVideoConfirmationReplansAndConfirmsWhenBrandingRemovalChanges() async {
        AnimateFinalRenderURLProtocolMock.reset()
        AnimateFinalRenderURLProtocolMock.responseDataForRequest = { request in
            switch request.url?.path {
            case "/v1/apps/animateav/video/quotes":
                return Data(Self.videoQuoteJSON.utf8)
            case "/v1/apps/animateav/renders/plan":
                return Data(Self.renderPlanWithoutBrandingJSON.utf8)
            case "/v1/apps/animateav/renders/final/confirm":
                return Data(Self.confirmFinalRenderWithoutBrandingJSON.utf8)
            default:
                return Data("{}".utf8)
            }
        }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AnimateFinalRenderURLProtocolMock.self]
        let harness = AnimateVideoCreationFailureHarness(
            error: NSError(domain: "test", code: 1),
            finalRenderSession: URLSession(configuration: configuration)
        )
        let finalRenderWorkflow = harness.finalRenderWorkflow
        let media = AnimateCreateTestFixtures.makeSelectedMedia(
            id: "00000000-0000-0000-0000-000000000001",
            sourceLocalIdentifier: "local-asset-1"
        )
        let viewModel = AnimateCreateViewModel()
        viewModel.bind(
            accountStateProvider: harness,
            videoCreationWorkflow: harness.videoCreationWorkflow,
            mediaUploadWorkflow: harness.mediaUploadWorkflow,
            videoDirectionWorkflow: harness.videoDirectionWorkflow,
            finalRenderWorkflow: finalRenderWorkflow,
            authTokenProvider: harness,
            imageGenerationAccountingClient: AnimateImageGenerationAccountingClient(baseURLString: "https://api.example.test")
        )
        viewModel.continueVideo(
            AnimateCreateTestFixtures.makeVideo(id: "video-1", status: "video_direction_ready"),
            focus: .video
        )
        let workspace = AnimateWorkspace(
            video: AnimateCreateTestFixtures.makeVideo(id: "video-1", status: "video_direction_ready"),
            mediaAssets: [
                AnimateCreateTestFixtures.makeMediaAsset(
                    id: "backend-media-1",
                    sourceLocalIdentifier: "local-asset-1",
                    hasUploadId: true
                )
            ],
            videoDirectionScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
            renderJobs: [],
            artifacts: []
        )
        harness.publishWorkspace(workspace)
        await Task.yield()
        await Task.yield()
        viewModel.applyAccountState(
            AnimateCreateAccountState(
                isSignedIn: true,
                balance: AnimateCreditBalance(proMonthly: 0, promotional: 15, purchased: 0),
                creditBalanceLoadState: .loaded
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
        viewModel.applyVideoDirectionState(
            AnimateCreateVideoDirectionState(
                activeWorkspace: workspace,
                savedScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
                generatedScenes: [],
                statusMessage: nil,
                isPlanning: false
            )
        )
        let existingRenderPlan = AnimateCreateTestFixtures.makeRenderPlan(
            videoId: "video-1",
            totalCreditCost: 1,
            plannedAssetCount: 1,
            usedAssetCount: 1
        )
        finalRenderWorkflow.usePreparedRenderPlan(existingRenderPlan)
        viewModel.applyFinalRenderState(
            AnimateCreateFinalRenderState(
                finalExport: nil,
                latestFinalJob: nil,
                renderPlan: existingRenderPlan,
                statusMessage: nil,
                isGenerating: false
            )
        )
        await Task.yield()

        viewModel.submitFinalVideoConfirmation(removesWatermark: true)
        await waitForFinalRenderJob(in: viewModel)

        XCTAssertEqual(AnimateFinalRenderURLProtocolMock.requestPaths, [
            "/v1/apps/animateav/renders/plan",
            "/v1/apps/animateav/renders/final/confirm",
        ])
        XCTAssertEqual(viewModel.latestFinalJob?.id, "render-without-branding-1")
        XCTAssertEqual(viewModel.latestFinalJob?.status, "running")
        XCTAssertEqual(viewModel.finalVideoCommandState, .queued(L10n.string("workflow.final.creatingVideo")))
        XCTAssertNil(viewModel.workflowErrorAlertMessage)
    }

    func testSubmitFinalVideoSyncsVisibleRenderPlanBeforeConfirming() async {
        AnimateFinalRenderURLProtocolMock.reset()
        AnimateFinalRenderURLProtocolMock.responseData = Data(Self.confirmFinalRenderJSON.utf8)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AnimateFinalRenderURLProtocolMock.self]
        let harness = AnimateVideoCreationFailureHarness(
            error: NSError(domain: "test", code: 1),
            finalRenderSession: URLSession(configuration: configuration)
        )
        let finalRenderWorkflow = harness.finalRenderWorkflow
        let viewModel = AnimateCreateViewModel()
        viewModel.bind(
            accountStateProvider: harness,
            videoCreationWorkflow: harness.videoCreationWorkflow,
            mediaUploadWorkflow: harness.mediaUploadWorkflow,
            videoDirectionWorkflow: harness.videoDirectionWorkflow,
            finalRenderWorkflow: finalRenderWorkflow,
            authTokenProvider: harness,
            imageGenerationAccountingClient: AnimateImageGenerationAccountingClient(baseURLString: "https://api.example.test")
        )
        viewModel.continueVideo(
            AnimateCreateTestFixtures.makeVideo(id: "video-1", status: "video_direction_ready"),
            focus: .video
        )
        let workspace = AnimateWorkspace(
            video: AnimateCreateTestFixtures.makeVideo(id: "video-1", status: "video_direction_ready"),
            mediaAssets: [
                AnimateCreateTestFixtures.makeMediaAsset(id: "backend-media-1", hasUploadId: true)
            ],
            videoDirectionScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
            renderJobs: [],
            artifacts: []
        )
        harness.publishWorkspace(workspace)
        await Task.yield()
        await Task.yield()
        viewModel.applyAccountState(
            AnimateCreateAccountState(
                isSignedIn: true,
                balance: AnimateCreditBalance(proMonthly: 0, promotional: 15, purchased: 0),
                creditBalanceLoadState: .loaded
            )
        )
        viewModel.applyVideoDirectionState(
            AnimateCreateVideoDirectionState(
                activeWorkspace: workspace,
                savedScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
                generatedScenes: [],
                statusMessage: nil,
                isPlanning: false
            )
        )
        let visibleRenderPlan = AnimateCreateTestFixtures.makeRenderPlan(
            videoId: "video-1",
            totalCreditCost: 1,
            plannedAssetCount: 1,
            usedAssetCount: 1
        )
        viewModel.applyFinalRenderState(
            AnimateCreateFinalRenderState(
                finalExport: nil,
                latestFinalJob: nil,
                renderPlan: visibleRenderPlan,
                statusMessage: nil,
                isGenerating: false
            )
        )

        viewModel.submitFinalVideoConfirmation()
        await waitForFinalRenderJob(in: viewModel)

        XCTAssertEqual(AnimateFinalRenderURLProtocolMock.requestPaths, [
            "/v1/apps/animateav/renders/final/confirm",
        ])
        XCTAssertEqual(viewModel.latestFinalJob?.id, "render-1")
        XCTAssertEqual(viewModel.finalVideoCommandState, .queued(L10n.string("workflow.final.creatingVideo")))
        XCTAssertNil(viewModel.workflowErrorAlertMessage)
    }

    func testConfirmFinalRenderShowsSpecificMessageWhenBackendPlanIsNotCreatable() async {
        AnimateFinalRenderURLProtocolMock.reset()
        AnimateFinalRenderURLProtocolMock.statusCode = 409
        AnimateFinalRenderURLProtocolMock.responseData = Data(Self.notCreatableRenderPlanErrorJSON.utf8)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AnimateFinalRenderURLProtocolMock.self]
        let harness = AnimateVideoCreationFailureHarness(
            error: NSError(domain: "test", code: 1),
            finalRenderSession: URLSession(configuration: configuration)
        )
        let workflow = harness.finalRenderWorkflow
        workflow.usePreparedRenderPlan(AnimateCreateTestFixtures.makeRenderPlan(videoId: "video-1"))
        harness.publishWorkspace(
            AnimateWorkspace(
                video: AnimateCreateTestFixtures.makeVideo(id: "video-1"),
                mediaAssets: [
                    AnimateCreateTestFixtures.makeMediaAsset(id: "backend-media-1", hasUploadId: true)
                ],
                videoDirectionScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
                renderJobs: [],
                artifacts: []
            )
        )
        await Task.yield()

        await workflow.confirmPreparedFinalRender(
            videoId: "video-1",
            template: .birthdayMessage,
            creationStyle: nil,
            form: AnimateVideoSetupForm(template: .birthdayMessage),
            selectedMedia: [],
            removesWatermark: false
        )

        XCTAssertEqual(AnimateFinalRenderURLProtocolMock.requestPaths, [
            "/v1/apps/animateav/renders/final/confirm",
        ])
        XCTAssertEqual(workflow.statusMessage, L10n.string("workflow.final.notCreatable"))
        XCTAssertNil(workflow.latestFinalJob)
        XCTAssertFalse(workflow.isGenerating)
    }

    func testConfirmFinalRenderShowsSpecificMessageWhenBackendPlanIsStale() async {
        AnimateFinalRenderURLProtocolMock.reset()
        AnimateFinalRenderURLProtocolMock.statusCode = 409
        AnimateFinalRenderURLProtocolMock.responseData = Data(Self.staleRenderPlanErrorJSON.utf8)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AnimateFinalRenderURLProtocolMock.self]
        let harness = AnimateVideoCreationFailureHarness(
            error: NSError(domain: "test", code: 1),
            finalRenderSession: URLSession(configuration: configuration)
        )
        let workflow = harness.finalRenderWorkflow
        workflow.usePreparedRenderPlan(AnimateCreateTestFixtures.makeRenderPlan(videoId: "video-1"))
        harness.publishWorkspace(
            AnimateWorkspace(
                video: AnimateCreateTestFixtures.makeVideo(id: "video-1"),
                mediaAssets: [
                    AnimateCreateTestFixtures.makeMediaAsset(id: "backend-media-1", hasUploadId: true)
                ],
                videoDirectionScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
                renderJobs: [],
                artifacts: []
            )
        )
        await Task.yield()

        await workflow.confirmPreparedFinalRender(
            videoId: "video-1",
            template: .birthdayMessage,
            creationStyle: nil,
            form: AnimateVideoSetupForm(template: .birthdayMessage),
            selectedMedia: [],
            removesWatermark: false
        )

        XCTAssertEqual(workflow.statusMessage, L10n.string("workflow.final.planChanged"))
        XCTAssertNil(workflow.renderPlan)
        XCTAssertNil(workflow.latestFinalJob)
        XCTAssertFalse(workflow.isGenerating)
    }

    func testVisibleFinalRenderPlanCanBeConfirmedEvenWhenLocalSignatureChanged() {
        let viewModel = AnimateCreateViewModel()
        let plan = AnimateCreateTestFixtures.makeRenderPlan(videoId: "video-1")

        viewModel.applyFinalRenderState(
            AnimateCreateFinalRenderState(
                finalExport: nil,
                latestFinalJob: nil,
                renderPlan: plan,
                statusMessage: nil,
                isGenerating: false
            )
        )

        XCTAssertTrue(viewModel.hasConfirmableRenderPlan(videoId: "video-1"))
        XCTAssertEqual(viewModel.confirmableRenderPlan(videoId: "video-1")?.planId, plan.planId)
        XCTAssertFalse(viewModel.hasConfirmableRenderPlan(videoId: "other-video"))
    }

    func testBlockedFinalRenderPlanCannotBeConfirmed() {
        let viewModel = AnimateCreateViewModel()
        let plan = AnimateCreateTestFixtures.makeRenderPlan(
            videoId: "video-1",
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

        XCTAssertFalse(viewModel.hasConfirmableRenderPlan(videoId: "video-1"))
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
            videoId: "video-1",
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

    func testVideoDirectionScenesClearStaleErrorAndMarkCurrentInputPrepared() {
        let viewModel = AnimateCreateViewModel()
        let media = AnimateCreateTestFixtures.makeSelectedMedia(
            id: "00000000-0000-0000-0000-000000000001"
        )

        viewModel.applyVideoCreationState(
            AnimateCreateVideoCreationState(
                isCreatingVideo: false,
                activeVideoId: "video-1",
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
        viewModel.applyVideoDirectionState(
            AnimateCreateVideoDirectionState(
                activeWorkspace: nil,
                savedScenes: [],
                generatedScenes: [],
                statusMessage: AnimateRecoveryCopy.videoDirectionFailure(),
                isPlanning: false
            )
        )

        XCTAssertEqual(viewModel.videoDirectionSummary.statusMessage, AnimateRecoveryCopy.videoDirectionFailure())
        XCTAssertFalse(viewModel.isVideoDirectionPreparedForCurrentInput)

        viewModel.applyVideoDirectionState(
            AnimateCreateVideoDirectionState(
                activeWorkspace: nil,
                savedScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
                generatedScenes: [],
                statusMessage: AnimateRecoveryCopy.videoDirectionFailure(),
                isPlanning: false
            )
        )

        XCTAssertNil(viewModel.videoDirectionSummary.statusMessage)
        XCTAssertTrue(viewModel.isVideoDirectionPreparedForCurrentInput)
    }

    func testCurrentVideoDirectionSignaturePrefersLocalMediaWhenWorkspaceHasUploadedMedia() {
        let viewModel = AnimateCreateViewModel()
        let localMedia = AnimateCreateTestFixtures.makeSelectedMedia(
            id: "00000000-0000-0000-0000-000000000001",
            sourceLocalIdentifier: "local-asset-1"
        )

        viewModel.applyVideoCreationState(
            AnimateCreateVideoCreationState(
                isCreatingVideo: false,
                activeVideoId: "video-1",
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

        viewModel.applyVideoDirectionState(
            AnimateCreateVideoDirectionState(
                activeWorkspace: AnimateWorkspace(
                    video: AnimateCreateTestFixtures.makeVideo(id: "video-1"),
                    mediaAssets: [
                        AnimateCreateTestFixtures.makeMediaAsset(
                            id: "backend-media-1",
                            sortOrder: 0
                        )
                    ],
                    videoDirectionScenes: [],
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
            videoId: "video-1",
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
            videoId: "video-1",
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

        XCTAssertEqual(viewModel.currentVideoDirectionInputSignature(videoId: "video-1"), expectedLocalSignature)
        XCTAssertNotEqual(viewModel.currentVideoDirectionInputSignature(videoId: "video-1"), backendMediaSignature)
    }

    func testWorkspaceSignatureReconcilesAfterVideoDirectionScenesArriveFirst() {
        let viewModel = AnimateCreateViewModel()
        let localMedia = AnimateCreateTestFixtures.makeSelectedMedia(
            id: "00000000-0000-0000-0000-000000000001",
            sourceLocalIdentifier: "local-asset-1"
        )
        let backendMedia = makeBackendMedia()
        let video = AnimateCreateTestFixtures.makeVideo(
            id: "video-1",
            occasion: "Birthday"
        )
        viewModel.form = AnimateVideoSetupForm.continuing(video: video, templates: viewModel.templates)
            ?? viewModel.form
        let backendSignature = viewModel.currentVideoDirectionInputSignature(
            videoId: "video-1",
            persistedMedia: [makeVideoDirectionMedia(from: backendMedia)]
        )

        viewModel.applyVideoCreationState(
            AnimateCreateVideoCreationState(
                isCreatingVideo: false,
                activeVideoId: "video-1",
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

        viewModel.applyVideoDirectionState(
            AnimateCreateVideoDirectionState(
                activeWorkspace: nil,
                savedScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
                generatedScenes: [],
                statusMessage: nil,
                isPlanning: false
            )
        )
        XCTAssertTrue(viewModel.isVideoDirectionPreparedForCurrentInput)

        viewModel.applyVideoDirectionState(
            AnimateCreateVideoDirectionState(
                activeWorkspace: AnimateWorkspace(
                    video: video.withStoryInputSignature(backendSignature),
                    mediaAssets: [backendMedia],
                    videoDirectionScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
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
        XCTAssertTrue(viewModel.isVideoDirectionPreparedForCurrentInput)
    }

    func testRestoredLocalMediaDoesNotInvalidatePreparedBackendVideoDirection() {
        let viewModel = AnimateCreateViewModel()
        let syncedLocalMedia = AnimateCreateTestFixtures.makeSelectedMedia(
            id: "00000000-0000-0000-0000-000000000001",
            sourceLocalIdentifier: "local-asset-1"
        )
        let preparedVideoDirection = applyPreparedBackendVideoDirection(to: viewModel)
        viewModel.applyMediaUploadState(
            AnimateCreateMediaUploadState(
                selectedMedia: [syncedLocalMedia],
                statusMessage: nil,
                isImporting: false,
                importProgress: nil
            )
        )

        XCTAssertEqual(viewModel.currentVideoDirectionInputSignature(videoId: "video-1"), preparedVideoDirection.signature)
        XCTAssertTrue(viewModel.isVideoDirectionPreparedForCurrentInput)
    }

    func testDirectionChangeInvalidatesPreparedBackendVideoDirectionWithRestoredLocalMedia() {
        let viewModel = AnimateCreateViewModel()
        applyPreparedBackendVideoDirection(to: viewModel)

        XCTAssertTrue(viewModel.isVideoDirectionPreparedForCurrentInput)

        viewModel.form.occasion = "Make this more cinematic."

        XCTAssertFalse(viewModel.isVideoDirectionPreparedForCurrentInput)
    }

    func testExplicitMediaEditInvalidatesPreparedBackendVideoDirection() {
        let viewModel = AnimateCreateViewModel()
        let preparedVideoDirection = applyPreparedBackendVideoDirection(to: viewModel)

        XCTAssertTrue(viewModel.isVideoDirectionPreparedForCurrentInput)

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

        XCTAssertFalse(viewModel.isVideoDirectionPreparedForCurrentInput)

        viewModel.applyVideoDirectionState(
            AnimateCreateVideoDirectionState(
                activeWorkspace: AnimateWorkspace(
                    video: AnimateCreateTestFixtures.makeVideo(
                        id: "video-1",
                        occasion: "Birthday",
                        storyInputSignature: preparedVideoDirection.signature
                    ),
                    mediaAssets: [preparedVideoDirection.media],
                    videoDirectionScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
                    renderJobs: [],
                    artifacts: []
                ),
                savedScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
                generatedScenes: [],
                statusMessage: nil,
                isPlanning: false
            )
        )

        XCTAssertFalse(viewModel.isVideoDirectionPreparedForCurrentInput)
    }

    func testExplicitMediaEditInvalidatesPreparedFinalRenderPlan() {
        let viewModel = AnimateCreateViewModel()
        applyPreparedBackendVideoDirection(to: viewModel)
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
                activeVideoId: "video-1",
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
        let video = AnimateCreateTestFixtures.makeVideo(
            id: "video-1",
            template: .partyRecap,
            theme: "eventRecap",
            mood: "warm",
            duration: "auto",
            mediaUse: "aviPick",
            occasion: "Event Recap",
            details: ""
        )
        viewModel.applyVideoDirectionState(
            AnimateCreateVideoDirectionState(
                activeWorkspace: AnimateWorkspace(
                    video: video,
                    mediaAssets: [
                        AnimateCreateTestFixtures.makeMediaAsset(
                            id: "backend-media-1",
                            sourceLocalIdentifier: "local-asset-1"
                        )
                    ],
                    videoDirectionScenes: [],
                    renderJobs: [],
                    artifacts: []
                ),
                savedScenes: [],
                generatedScenes: [],
                statusMessage: nil,
                isPlanning: false
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

        let signatureBeforeSync = viewModel.currentFinalRenderInputSignatureSource(videoId: "video-1")
        XCTAssertNotNil(viewModel.currentRenderPlan)

        viewModel.applyVideoDirectionState(
            AnimateCreateVideoDirectionState(
                activeWorkspace: AnimateWorkspace(
                    video: video,
                    mediaAssets: [
                        AnimateCreateTestFixtures.makeMediaAsset(
                            id: "backend-media-1",
                            sourceLocalIdentifier: "local-asset-1"
                        )
                    ],
                    videoDirectionScenes: [],
                    renderJobs: [],
                    artifacts: []
                ),
                savedScenes: [],
                generatedScenes: [],
                statusMessage: nil,
                isPlanning: false
            )
        )

        let signatureAfterSync = viewModel.currentFinalRenderInputSignatureSource(videoId: "video-1")
        XCTAssertEqual(signatureBeforeSync, signatureAfterSync, "\(viewModel.form)")
        XCTAssertNotNil(viewModel.currentRenderPlan)
        XCTAssertNotNil(viewModel.finalRenderSummary.renderPlan)
    }

    func testPrepareVideoDirectionShowsImmediateVideoCreationError() async {
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
        await waitForVideoDirectionStatusMessage(in: viewModel)

        XCTAssertEqual(viewModel.videoDirectionSummary.statusMessage, L10n.string("workflow.video.tryAgain"))
    }

    private static let confirmFinalRenderJSON = """
    {
      "appId": "animateav",
      "videoId": "video-1",
      "planId": "plan-1",
      "reservation": {
        "id": "reservation-1",
        "appId": "animateav",
        "userId": "user-1",
        "videoId": "video-1",
        "workflowRunId": null,
        "amount": 2,
        "status": "reserved",
        "idempotencyKey": "final-confirm:video-1:plan-1:birthdayMessage:watermarked",
        "expiresAt": "2026-06-16T16:00:00Z",
        "createdAt": "2026-05-16T16:00:00Z",
        "updatedAt": "2026-05-16T16:00:00Z"
      },
      "workflow": {
        "appId": "animateav",
        "videoId": "video-1",
        "renderJobId": "render-1",
        "workflowRunId": "workflow-1",
        "status": "running",
        "startedAt": "2026-05-16T16:00:00Z"
      },
      "renderPlan": {
        "appId": "animateav",
        "videoId": "video-1",
        "planId": "plan-1",
        "canCreateVideo": true,
        "createVideoBlockers": [],
        "generatedAt": "2026-05-16T16:00:00Z",
        "plan": {
          "schemaVersion": 1,
          "secondsPerCredit": 15,
          "renderOptionId": "standard_video",
          "renderOptionTitle": "Standard Video",
          "creditCost": 2,
          "totalCreditCost": 2,
          "targetDurationMs": 30000,
          "rendererMode": "image_to_video",
          "plannedAssetCount": 4,
          "usedAssetCount": 4,
          "rejectedAssetCount": 0,
          "qualityWarnings": [],
          "userMessage": "Ready."
        }
      },
      "confirmedAt": "2026-05-16T16:00:00Z"
    }
    """

    private static let notCreatableRenderPlanErrorJSON = """
    {
      "error": {
        "code": "animate_render_plan_not_creatable",
        "message": "The render plan cannot create a video."
      }
    }
    """

    private static let staleRenderPlanErrorJSON = """
    {
      "error": {
        "code": "animate_render_plan_stale",
        "message": "The render plan changed."
      }
    }
    """

    private static let videoQuoteJSON = """
    {
      "appId": "animateav",
      "outputKind": "video",
      "duration": "upTo5s",
      "baseCreditCost": 1,
      "brandingRemovalCreditCost": 1,
      "totalCreditCost": 2,
      "proIncludesBrandingFreeVideo": false,
      "branding": {
        "enabled": true,
        "included": false,
        "removalAvailable": true,
        "removalRequested": true,
        "removalIncluded": false,
        "assetId": null,
        "placement": null,
        "reason": "branding_removal_purchased"
      }
    }
    """

    private static let renderPlanWithoutBrandingJSON = """
    {
      "appId": "animateav",
      "videoId": "video-1",
      "planId": "plan-without-branding-1",
      "watermark": {
        "includedForPro": true,
        "userHasWatermarkFree": false,
        "nonProRemovalCreditCost": 1,
        "selectedRemoveWatermark": true,
        "watermarkCreditCost": 1
      },
      "canCreateVideo": true,
      "createVideoBlockers": [],
      "generatedAt": "2026-05-16T16:00:00Z",
      "plan": {
        "schemaVersion": 1,
        "secondsPerCredit": 5,
        "renderOptionId": "animate_short",
        "renderOptionTitle": "Short animation",
        "creditCost": 1,
        "totalCreditCost": 2,
        "targetDurationMs": 5000,
        "minimumDurationMs": 5000,
        "rendererMode": "image_to_video",
        "plannedAssetCount": 1,
        "usedAssetCount": 1,
        "rejectedAssetCount": 0,
        "qualityWarnings": [],
        "userMessage": "Ready."
      }
    }
    """

    private static let confirmFinalRenderWithoutBrandingJSON = """
    {
      "appId": "animateav",
      "videoId": "video-1",
      "planId": "plan-without-branding-1",
      "reservation": {
        "id": "reservation-without-branding-1",
        "appId": "animateav",
        "userId": "user-1",
        "videoId": "video-1",
        "workflowRunId": null,
        "amount": 2,
        "status": "reserved",
        "idempotencyKey": "final-confirm:video-1:plan-without-branding-1:birthdayMessage:without-branding",
        "expiresAt": "2026-06-16T16:00:00Z",
        "createdAt": "2026-05-16T16:00:00Z",
        "updatedAt": "2026-05-16T16:00:00Z"
      },
      "workflow": {
        "appId": "animateav",
        "videoId": "video-1",
        "renderJobId": "render-without-branding-1",
        "workflowRunId": "workflow-without-branding-1",
        "status": "running",
        "startedAt": "2026-05-16T16:00:00Z"
      },
      "renderPlan": {
        "appId": "animateav",
        "videoId": "video-1",
        "planId": "plan-without-branding-1",
        "watermark": {
          "includedForPro": true,
          "userHasWatermarkFree": false,
          "nonProRemovalCreditCost": 1,
          "selectedRemoveWatermark": true,
          "watermarkCreditCost": 1
        },
        "canCreateVideo": true,
        "createVideoBlockers": [],
        "generatedAt": "2026-05-16T16:00:00Z",
        "plan": {
          "schemaVersion": 1,
          "secondsPerCredit": 5,
          "renderOptionId": "animate_short",
          "renderOptionTitle": "Short animation",
          "creditCost": 1,
          "totalCreditCost": 2,
          "targetDurationMs": 5000,
          "minimumDurationMs": 5000,
          "rendererMode": "image_to_video",
          "plannedAssetCount": 1,
          "usedAssetCount": 1,
          "rejectedAssetCount": 0,
          "qualityWarnings": [],
          "userMessage": "Ready."
        }
      },
      "confirmedAt": "2026-05-16T16:00:00Z"
    }
    """

    @discardableResult
    private func applyPreparedBackendVideoDirection(
        to viewModel: AnimateCreateViewModel,
        videoId: String = "video-1"
    ) -> (media: AnimateMediaAsset, signature: String) {
        let media = makeBackendMedia()
        let video = AnimateCreateTestFixtures.makeVideo(
            id: videoId,
            occasion: "Birthday"
        )
        viewModel.form = AnimateVideoSetupForm.continuing(video: video, templates: viewModel.templates)
            ?? viewModel.form
        viewModel.applyVideoCreationState(
            AnimateCreateVideoCreationState(
                isCreatingVideo: false,
                activeVideoId: videoId,
                setupErrorMessage: nil
            )
        )
        let signature = viewModel.currentVideoDirectionInputSignature(
            videoId: videoId,
            persistedMedia: [makeVideoDirectionMedia(from: media)]
        )
        viewModel.applyVideoDirectionState(
            AnimateCreateVideoDirectionState(
                activeWorkspace: AnimateWorkspace(
                    video: video.withStoryInputSignature(signature),
                    mediaAssets: [media],
                    videoDirectionScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
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

    private func makeVideoDirectionMedia(from media: AnimateMediaAsset) -> AnimateVideoDirectionMedia {
        AnimateVideoDirectionMedia(
            mediaAssetId: media.id,
            mediaKind: media.kind,
            sortOrder: Int(media.sortOrder),
            selected: media.selected,
            moderationStatus: media.moderationStatus
        )
    }

    private func waitForVideoDirectionStatusMessage(in viewModel: AnimateCreateViewModel) async {
        for _ in 0..<20 where viewModel.videoDirectionSummary.statusMessage == nil {
            try? await Task.sleep(nanoseconds: 25_000_000)
        }
    }

    private func waitForFinalRenderJob(in viewModel: AnimateCreateViewModel) async {
        for _ in 0..<40 where viewModel.latestFinalJob == nil {
            try? await Task.sleep(nanoseconds: 25_000_000)
        }
    }

    private func waitForGeneratedImagePreview(in viewModel: AnimateCreateViewModel) async {
        for _ in 0..<40
            where viewModel.workflowPresentation.finalRenderSummary.generatedImagePreviewLocalRelativePath == nil {
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
    private let finalRenderSession: URLSession
    private let uploadSession: URLSession?
    private let galleryStore: TestGalleryStore
    var bearerToken: String? = "token-1"

    init(
        error: Error,
        finalRenderSession: URLSession = .shared,
        uploadSession: URLSession? = nil,
        galleryStore: TestGalleryStore = TestGalleryStore()
    ) {
        creationError = error
        self.finalRenderSession = finalRenderSession
        self.uploadSession = uploadSession
        self.galleryStore = galleryStore
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
            finalRenderClient: AnimateFinalRenderClient(
                baseURLString: "https://api.example.com",
                session: finalRenderSession
            ),
            uploadClient: uploadSession.map {
                AnimateUploadClient(baseURLString: "https://api.example.com", session: $0)
            },
            galleryStore: galleryStore
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
        bearerToken
    }

    func createVideo(bearerToken: String, form: AnimateVideoSetupForm) async throws -> String {
        createAttemptExpectation.fulfill()
        throw creationError
    }

    func updateVideoSetup(bearerToken: String, videoId: String, form: AnimateVideoSetupForm) async throws {}

    func deleteVideo(bearerToken: String, videoId: String) async throws {}

    func observeWorkspace(ownerUserId: String?, videoId: String?) {}

    func clearWorkspace() {
        workspaceSubject.send(nil)
    }

    func publishWorkspace(_ workspace: AnimateWorkspace) {
        workspaceSubject.send(workspace)
    }

}

private struct TestGalleryStore: AnimateGalleryStoring {
    var imageRecords: [AnimateGalleryImageRecord] = []
    var localImageRelativePaths: Set<String> = []

    func loadRecords() -> [AnimateGalleryVideoRecord] { [] }
    func saveRecords(_ records: [AnimateGalleryVideoRecord]) {}
    func loadImageRecords() -> [AnimateGalleryImageRecord] { imageRecords }
    func saveImageRecords(_ records: [AnimateGalleryImageRecord]) {}
    func localFileExists(for record: AnimateGalleryVideoRecord) -> Bool { false }
    func localFileURL(for record: AnimateGalleryVideoRecord) -> URL { URL(fileURLWithPath: "/tmp/\(record.id).mp4") }
    func localFileExists(for record: AnimateGalleryImageRecord) -> Bool {
        localImageRelativePaths.contains(record.localRelativePath)
    }
    func localFileURL(for record: AnimateGalleryImageRecord) -> URL { URL(fileURLWithPath: "/tmp/\(record.id).png") }
    func localFileExists(relativePath: String) -> Bool { localImageRelativePaths.contains(relativePath) }
    func localFileURL(relativePath: String) -> URL { URL(fileURLWithPath: "/tmp/\(relativePath)") }
    func contains(artifactId: String) -> Bool { false }
    func containsImage(artifactId: String) -> Bool {
        imageRecords.contains { $0.artifactId == artifactId }
    }
    func saveSourceImage(data: Data, videoId: String, artifactId: String) throws -> String {
        "source-\(artifactId).jpg"
    }
    func saveDownloadedVideo(
        temporaryFileURL: URL,
        videoId: String,
        artifactId: String,
        title: String,
        r2Key: String,
        sourceImageLocalRelativePath: String?,
        generatedImageLocalRelativePath: String?,
        createdAt: Date
    ) throws -> AnimateGalleryVideoRecord {
        AnimateGalleryVideoRecord(
            id: artifactId,
            videoId: videoId,
            artifactId: artifactId,
            title: title,
            r2Key: r2Key,
            localRelativePath: "\(artifactId).mp4",
            sourceImageLocalRelativePath: sourceImageLocalRelativePath,
            generatedImageLocalRelativePath: generatedImageLocalRelativePath,
            createdAt: createdAt.timeIntervalSince1970 * 1000
        )
    }
    func saveDownloadedImage(
        temporaryFileURL: URL,
        artifactId: String,
        title: String,
        look: String?,
        r2Key: String,
        createdAt: Date
    ) throws -> AnimateGalleryImageRecord {
        AnimateGalleryImageRecord(
            id: artifactId,
            artifactId: artifactId,
            title: title,
            look: look,
            r2Key: r2Key,
            localRelativePath: "\(artifactId).png",
            createdAt: createdAt.timeIntervalSince1970 * 1000
        )
    }
    func addRecord(_ record: AnimateGalleryVideoRecord) {}
    func addImageRecord(_ record: AnimateGalleryImageRecord) {}
    func renameRecord(_ record: AnimateGalleryVideoRecord, title: String) {}
    func renameImageRecord(_ record: AnimateGalleryImageRecord, title: String) {}
    func deleteRecord(_ record: AnimateGalleryVideoRecord, deleteLocalFile: Bool) {}
    func deleteImageRecord(_ record: AnimateGalleryImageRecord, deleteLocalFile: Bool) {}
}

private final class AnimateFinalRenderURLProtocolMock: URLProtocol {
    nonisolated(unsafe) static var responseData = Data()
    nonisolated(unsafe) static var responseDataForRequest: ((URLRequest) -> Data)?
    nonisolated(unsafe) static var responseDelayNanoseconds: UInt64 = 0
    nonisolated(unsafe) static var statusCode = 200
    nonisolated(unsafe) static var requestCount = 0
    nonisolated(unsafe) static var lastRequest: URLRequest?
    nonisolated(unsafe) static var lastRequestBody: Data?
    nonisolated(unsafe) static var requestPaths: [String] = []

    static func reset() {
        responseData = Data()
        responseDataForRequest = nil
        responseDelayNanoseconds = 0
        statusCode = 200
        requestCount = 0
        lastRequest = nil
        lastRequestBody = nil
        requestPaths = []
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        Self.requestCount += 1
        Self.lastRequest = request
        Self.lastRequestBody = request.httpBody
        if Self.lastRequestBody == nil,
           let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var data = Data()
            let bufferSize = 1_024
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { buffer.deallocate() }
            while stream.hasBytesAvailable {
                let count = stream.read(buffer, maxLength: bufferSize)
                if count <= 0 { break }
                data.append(buffer, count: count)
            }
            Self.lastRequestBody = data
        }
        Self.requestPaths.append(request.url?.path ?? "")
        if Self.responseDelayNanoseconds > 0 {
            Thread.sleep(forTimeInterval: Double(Self.responseDelayNanoseconds) / 1_000_000_000)
        }
        finishLoading()
    }

    private func finishLoading() {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.responseDataForRequest?(request) ?? Self.responseData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
