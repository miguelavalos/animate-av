import XCTest
@testable import AnimateAV

@MainActor
final class AnimateCreateWorkflowPresentationTests: XCTestCase {
    func testPrimaryActionDoesNotRequestCreditsWhenPreparedPlanCostIsCovered() {
        let presentation = AnimateCreatePrimaryActionPresentation(
            workflow: AnimateCreateWorkflowPresentation(
                activeMomentId: "moment-1",
                isSignedIn: true,
                hasMomentWorkspace: true,
                template: .birthdayMessage,
                balance: AnimateCreditBalance(proMonthly: 0, promotional: 1, purchased: 0),
                mediaSummary: AnimateCreateMediaSummary(
                    selectedMedia: [AnimateCreateTestFixtures.makeSelectedMedia(id: "00000000-0000-0000-0000-000000000001")]
                ),
                storySummary: AnimateCreateStorySummary(),
                finalRenderSummary: AnimateCreateFinalRenderSummary(
                    creditCost: 1,
                    renderPlan: AnimateCreateTestFixtures.makeRenderPlan(totalCreditCost: 1)
                ),
                canPrepareFinalRenderPlan: true,
                canGenerateFinalRender: true
            )
        )

        XCTAssertFalse(presentation.needsCreditsForPreparedPlan)
        XCTAssertEqual(presentation.buttonTitle, "Confirm credits · 1 credit")
        XCTAssertEqual(presentation.statusMessage, "Credits are only charged for completed final videos. This video costs 1 credit.")
    }

    func testPrimaryActionShowsFinalVideoCommandStatus() {
        let presentation = AnimateCreatePrimaryActionPresentation(
            workflow: AnimateCreateWorkflowPresentation(
                activeMomentId: "moment-1",
                isSignedIn: true,
                hasMomentWorkspace: true,
                template: .birthdayMessage,
                balance: AnimateCreditBalance(proMonthly: 0, promotional: 1, purchased: 0),
                mediaSummary: AnimateCreateMediaSummary(
                    selectedMedia: [AnimateCreateTestFixtures.makeSelectedMedia(id: "00000000-0000-0000-0000-000000000001")]
                ),
                storySummary: AnimateCreateStorySummary(),
                finalRenderSummary: AnimateCreateFinalRenderSummary(
                    creditCost: 1,
                    statusMessage: "Creating final video."
                ),
                canPrepareFinalRenderPlan: true,
                canGenerateFinalRender: true
            )
        )

        XCTAssertEqual(presentation.statusMessage, "Creating final video.")
    }

    func testWorkflowPresentationHidesWorkflowCardsWithoutVideo() {
        let presentation = AnimateCreateWorkflowPresentation(
            activeMomentId: nil,
            template: .birthdayMessage,
            balance: .empty,
            mediaSummary: AnimateCreateMediaSummary(),
            storySummary: AnimateCreateStorySummary(),
            finalRenderSummary: AnimateCreateFinalRenderSummary()
        )

        XCTAssertFalse(presentation.showsWorkflowCards)
    }

    func testWorkflowPresentationLocksEditingDuringActiveFinalRender() {
        let activeFinalJob = AnimateCreateTestFixtures.makeRenderJob(
            id: "final-job",
            kind: "final",
            status: "running",
            canEditSetup: false
        )
        let presentation = AnimateCreateWorkflowPresentation(
            activeMomentId: "moment-1",
            hasMomentWorkspace: true,
            template: .birthdayMessage,
            balance: .empty,
            mediaSummary: AnimateCreateMediaSummary(),
            storySummary: AnimateCreateStorySummary(),
            finalRenderSummary: AnimateCreateFinalRenderSummary(latestFinalJob: activeFinalJob)
        )

        XCTAssertTrue(presentation.isFinalRenderEditingLocked)
    }

    func testLockedFinalRenderMediaCountUsesJobCountAfterLocalSelectionReloadsEmpty() {
        let activeFinalJob = AnimateCreateTestFixtures.makeRenderJob(
            id: "final-job",
            kind: "final",
            status: "running",
            canEditSetup: false,
            totalCreditCost: 1,
            plannedAssetCount: 6,
            usedAssetCount: 6
        )
        let presentation = AnimateCreateWorkflowPresentation(
            activeMomentId: "moment-1",
            hasMomentWorkspace: true,
            template: .birthdayMessage,
            balance: .empty,
            mediaSummary: AnimateCreateMediaSummary(),
            storySummary: AnimateCreateStorySummary(),
            finalRenderSummary: AnimateCreateFinalRenderSummary(latestFinalJob: activeFinalJob)
        )

        XCTAssertTrue(presentation.isFinalRenderEditingLocked)
        XCTAssertEqual(presentation.lockedFinalRenderMediaCountTitle, "6 items")
    }

    func testLockedFinalRenderCostUsesConfirmedPlanCost() {
        let activeFinalJob = AnimateCreateTestFixtures.makeRenderJob(
            id: "final-job",
            kind: "final",
            status: "running",
            canEditSetup: false,
            plannedAssetCount: 6,
            usedAssetCount: 6
        )
        let oneCreditPlan = AnimateCreateTestFixtures.makeRenderPlan(
            totalCreditCost: 1,
            minimumDurationMs: 8_000,
            targetDurationMs: 15_000,
            plannedAssetCount: 6,
            usedAssetCount: 6
        )
        let presentation = AnimateCreateWorkflowPresentation(
            activeMomentId: "moment-1",
            hasMomentWorkspace: true,
            template: .birthdayMessage,
            balance: .empty,
            mediaSummary: AnimateCreateMediaSummary(),
            storySummary: AnimateCreateStorySummary(),
            finalRenderSummary: AnimateCreateFinalRenderSummary(
                creditCost: 2,
                renderPlan: oneCreditPlan,
                latestFinalJob: activeFinalJob
            )
        )

        XCTAssertTrue(presentation.isFinalRenderEditingLocked)
        XCTAssertEqual(presentation.finalRenderSummary.effectiveCreditCost, 1)
        XCTAssertEqual(presentation.lockedFinalRenderCreditCost, 1)
    }

    func testWorkflowPresentationAllowsEditingWhenFinalRenderAllowsSetupChanges() {
        let editableFinalJob = AnimateCreateTestFixtures.makeRenderJob(
            id: "final-job",
            kind: "final",
            status: "running",
            canEditSetup: true
        )
        let presentation = AnimateCreateWorkflowPresentation(
            activeMomentId: "moment-1",
            hasMomentWorkspace: true,
            template: .birthdayMessage,
            balance: .empty,
            mediaSummary: AnimateCreateMediaSummary(),
            storySummary: AnimateCreateStorySummary(),
            finalRenderSummary: AnimateCreateFinalRenderSummary(latestFinalJob: editableFinalJob)
        )

        XCTAssertFalse(presentation.isFinalRenderEditingLocked)
    }

    func testWorkflowPresentationCarriesWorkflowStateForActiveVideo() {
        let finalExport = AnimateCreateTestFixtures.makeArtifact(id: "final-1", kind: "final_export")
        let latestFinalJob = AnimateCreateTestFixtures.makeRenderJob(id: "final-job", kind: "final", status: "queued")
        let mediaSummary = AnimateCreateMediaSummary(
            selectedMedia: [],
            syncedMediaAssets: [AnimateCreateTestFixtures.makeMediaAsset(id: "media-1")],
            isImporting: true,
            statusMessage: "Importing media."
        )
        let storySummary = AnimateCreateStorySummary(
            savedScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")],
            generatedScenes: [],
            isPlanning: true,
            statusMessage: "Planning story."
        )
        let finalRenderSummary = AnimateCreateFinalRenderSummary(
            creditCost: 2,
            finalExport: finalExport,
            latestFinalJob: latestFinalJob,
            isGenerating: false,
            statusMessage: "Final render is queued."
        )

        let presentation = AnimateCreateWorkflowPresentation(
            activeMomentId: "moment-1",
            hasMomentWorkspace: true,
            template: .birthdayMessage,
            balance: AnimateCreditBalance(proMonthly: 0, promotional: 2, purchased: 0),
            mediaSummary: mediaSummary,
            storySummary: storySummary,
            finalRenderSummary: finalRenderSummary,
            canAddMedia: true,
            canPlanStory: true,
            canPrepareFinalRenderPlan: true,
            canGenerateFinalRender: true,
            canRefreshFinalRenderStatus: true,
            mediaAvailabilityMessage: "Add media.",
            storyAvailabilityMessage: "Prepare story.",
            finalRenderAvailabilityMessage: "Generate final."
        )

        XCTAssertTrue(presentation.showsWorkflowCards)
        XCTAssertEqual(presentation.activeMomentId, "moment-1")
        XCTAssertEqual(presentation.template, .birthdayMessage)
        XCTAssertEqual(presentation.mediaSummary, mediaSummary)
        XCTAssertEqual(presentation.storySummary, storySummary)
        XCTAssertEqual(presentation.finalRenderSummary, finalRenderSummary)
        XCTAssertTrue(presentation.canAddMedia)
        XCTAssertTrue(presentation.canPlanStory)
        XCTAssertTrue(presentation.canPrepareFinalRenderPlan)
        XCTAssertTrue(presentation.canGenerateFinalRender)
        XCTAssertTrue(presentation.canRefreshFinalRenderStatus)
        XCTAssertEqual(presentation.mediaAvailabilityMessage, "Add media.")
        XCTAssertEqual(presentation.storyAvailabilityMessage, "Prepare story.")
        XCTAssertEqual(presentation.finalRenderAvailabilityMessage, "Generate final.")
    }

    func testWorkflowPresentationBuilderAppliesAvailabilityState() {
        let presentation = AnimateCreateWorkflowPresentation.make(
            activeMomentId: "moment-1",
            isSignedIn: true,
            isCreatingMoment: false,
            hasMomentWorkspace: true,
            hasUnsavedLocalMoment: false,
            template: .birthdayMessage,
            creationStyleTitle: "Birthday Story",
            toneTitle: "Warm",
            tempoTitle: "Balanced",
            occasionTitle: "Birthday for Ava",
            balance: AnimateCreditBalance(proMonthly: 0, promotional: 1, purchased: 0),
            mediaSummary: AnimateCreateMediaSummary(),
            storySummary: AnimateCreateStorySummary(),
            finalRenderSummary: AnimateCreateFinalRenderSummary(),
            availability: AnimateCreateWorkflowAvailability(
                canAddMedia: true,
                canPlanStory: false,
                canPrepareFinalRenderPlan: true,
                canGenerateFinalRender: true,
                canRefreshFinalRenderStatus: false,
                mediaMessage: nil,
                storyMessage: "Prepare story.",
                finalRenderMessage: nil
            )
        )

        XCTAssertTrue(presentation.canAddMedia)
        XCTAssertFalse(presentation.canPlanStory)
        XCTAssertTrue(presentation.canPrepareFinalRenderPlan)
        XCTAssertEqual(presentation.creationStyleTitle, "Birthday Story")
        XCTAssertEqual(presentation.toneTitle, "Warm")
        XCTAssertEqual(presentation.tempoTitle, "Balanced")
        XCTAssertEqual(presentation.occasionTitle, "Birthday for Ava")
        XCTAssertEqual(presentation.storyAvailabilityMessage, "Prepare story.")
    }

    func testWorkflowPresentationCarriesUnsavedLocalVideoContainmentState() {
        let presentation = AnimateCreateWorkflowPresentation.make(
            activeMomentId: nil,
            isSignedIn: true,
            isCreatingMoment: false,
            hasMomentWorkspace: true,
            hasUnsavedLocalMoment: true,
            template: .birthdayMessage,
            creationStyleTitle: "Birthday Story",
            toneTitle: "Warm",
            tempoTitle: "Balanced",
            occasionTitle: "Birthday",
            balance: .empty,
            mediaSummary: AnimateCreateMediaSummary(
                selectedMedia: [AnimateCreateTestFixtures.makeSelectedMedia(id: "00000000-0000-0000-0000-000000000001")]
            ),
            storySummary: AnimateCreateStorySummary(),
            finalRenderSummary: AnimateCreateFinalRenderSummary(),
            availability: AnimateCreateWorkflowAvailability(
                canAddMedia: true,
                canPlanStory: false,
                canPrepareFinalRenderPlan: false,
                canGenerateFinalRender: false,
                canRefreshFinalRenderStatus: false
            )
        )

        XCTAssertTrue(presentation.hasUnsavedLocalMoment)
        XCTAssertTrue(presentation.showsWorkflowCards)
        XCTAssertTrue(presentation.showsMediaFirstWorkspace)
    }

    func testWorkflowPresentationShowsMediaChoiceForEmptyLocalVideo() {
        let presentation = AnimateCreateWorkflowPresentation.make(
            activeMomentId: nil,
            isSignedIn: true,
            isCreatingMoment: false,
            hasMomentWorkspace: false,
            hasUnsavedLocalMoment: true,
            template: .birthdayMessage,
            creationStyleTitle: "Birthday Story",
            toneTitle: "Warm",
            tempoTitle: "Balanced",
            occasionTitle: "Birthday",
            balance: .empty,
            mediaSummary: AnimateCreateMediaSummary(),
            storySummary: AnimateCreateStorySummary(),
            finalRenderSummary: AnimateCreateFinalRenderSummary(),
            availability: AnimateCreateWorkflowAvailability(
                canAddMedia: true,
                canPlanStory: false,
                canPrepareFinalRenderPlan: false,
                canGenerateFinalRender: false,
                canRefreshFinalRenderStatus: false
            )
        )

        XCTAssertFalse(presentation.showsWorkflowCards)
        XCTAssertTrue(presentation.showsMediaFirstWorkspace)
    }

    func testWorkflowPresentationShowsBlockingPreparationForCriticalWork() {
        var presentation = AnimateCreateWorkflowPresentation(
            activeMomentId: "moment-1",
            template: .birthdayMessage,
            balance: .empty,
            mediaSummary: AnimateCreateMediaSummary(isImporting: true),
            storySummary: AnimateCreateStorySummary(),
            finalRenderSummary: AnimateCreateFinalRenderSummary()
        )

        XCTAssertTrue(presentation.showsBlockingPreparation)

        presentation.mediaSummary = AnimateCreateMediaSummary()
        presentation.storySummary = AnimateCreateStorySummary(isPlanning: true)
        XCTAssertTrue(presentation.showsBlockingPreparation)

        presentation.finalRenderSummary = AnimateCreateFinalRenderSummary(isGenerating: true)
        XCTAssertTrue(presentation.showsBlockingPreparation)

        presentation.storySummary = AnimateCreateStorySummary()
        presentation.finalRenderSummary = AnimateCreateFinalRenderSummary()
        XCTAssertFalse(presentation.showsBlockingPreparation)
    }

    func testStorySummaryBuildsPresentedScenesFromSavedScenes() {
        let summary = AnimateCreateStorySummary(
            savedScenes: [
                AnimateCreateTestFixtures.makeScene(id: "scene-2", sceneIndex: 1, caption: "Show the trip highlights."),
                AnimateCreateTestFixtures.makeScene(id: "scene-1", sceneIndex: 0, caption: "Open with the arrival.")
            ]
        )

        XCTAssertTrue(summary.hasScenes)
        XCTAssertEqual(summary.presentedScenes.map(\.title), ["Opening", "Main motion"])
        XCTAssertEqual(summary.presentedScenes.map(\.caption), ["Open with the arrival.", "Show the trip highlights."])
    }

    func testVideoDirectionPresentationFormatsReadyDirectionState() {
        let presentation = AnimateCreateVideoDirectionPresentation(
            mediaSummary: AnimateCreateMediaSummary(
                selectedMedia: [
                    AnimateCreateTestFixtures.makeSelectedMedia(id: "00000000-0000-0000-0000-000000000001"),
                    AnimateCreateTestFixtures.makeSelectedMedia(id: "00000000-0000-0000-0000-000000000002")
                ]
            ),
            storySummary: AnimateCreateStorySummary(
                savedScenes: [
                    AnimateCreateTestFixtures.makeScene(id: "scene-1", sceneIndex: 0),
                    AnimateCreateTestFixtures.makeScene(id: "scene-2", sceneIndex: 1),
                    AnimateCreateTestFixtures.makeScene(id: "scene-3", sceneIndex: 2),
                    AnimateCreateTestFixtures.makeScene(id: "scene-4", sceneIndex: 3)
                ]
            ),
            selectedDuration: .auto,
            canRefreshStory: true
        )

        XCTAssertEqual(
            presentation.statusMessage,
            "Video direction is ready. Create the final video or adjust it first."
        )
        XCTAssertEqual(presentation.modeTitle, "Direction")
        XCTAssertEqual(presentation.mediaCountTitle, "2 items")
        XCTAssertEqual(presentation.primaryActionTitle, "Refresh direction")
        XCTAssertEqual(presentation.editActionTitle, "Edit direction")
        XCTAssertTrue(presentation.canRunPrimaryAction)
        XCTAssertTrue(presentation.canShowRefreshAction)
        XCTAssertEqual(presentation.visibleScenes.count, 2)
        XCTAssertEqual(presentation.remainingSceneTitle, "2 more direction details")
    }

    func testVideoDirectionPresentationKeepsFinalPathNonBlockingWhenImproveIsUnavailable() {
        let presentation = AnimateCreateVideoDirectionPresentation(
            mediaSummary: AnimateCreateMediaSummary(
                selectedMedia: [AnimateCreateTestFixtures.makeSelectedMedia(id: "00000000-0000-0000-0000-000000000001")]
            ),
            storySummary: AnimateCreateStorySummary(
                savedScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")]
            ),
            selectedDuration: .auto,
            canRefreshStory: false,
            availabilityMessage: "Improve with Avi is cooling down."
        )

        XCTAssertEqual(
            presentation.statusMessage,
            "Video direction is ready. Create the final video or adjust it first."
        )
        XCTAssertEqual(presentation.primaryActionTitle, "Refresh direction")
        XCTAssertFalse(presentation.canRunPrimaryAction)
        XCTAssertFalse(presentation.canShowRefreshAction)
    }

    func testVideoDirectionPresentationFormatsPendingAndUnavailableStates() {
        var presentation = AnimateCreateVideoDirectionPresentation(
            mediaSummary: AnimateCreateMediaSummary(
                selectedMedia: [AnimateCreateTestFixtures.makeSelectedMedia(id: "00000000-0000-0000-0000-000000000001")]
            ),
            storySummary: AnimateCreateStorySummary(),
            selectedDuration: .auto,
            canRefreshStory: true
        )

        XCTAssertEqual(presentation.statusMessage, "Ready for Avi to prepare the video direction.")
        XCTAssertEqual(presentation.modeTitle, "Ready")
        XCTAssertEqual(presentation.mediaCountTitle, "1 item")
        XCTAssertEqual(presentation.primaryActionTitle, "Prepare video")
        XCTAssertTrue(presentation.canRunPrimaryAction)
        XCTAssertFalse(presentation.canShowRefreshAction)

        presentation.canRefreshStory = false
        presentation.availabilityMessage = "Sign in before preparing the story."
        XCTAssertEqual(presentation.statusMessage, "Sign in before preparing the story.")
        XCTAssertFalse(presentation.canRunPrimaryAction)
    }

    func testMediaPresentationFormatsSelectionAndSortsSyncedMedia() {
        let presentation = AnimateCreateMediaPresentation(
            activeMomentId: "moment-1",
            template: .birthdayMessage,
            summary: AnimateCreateMediaSummary(
                selectedMedia: [AnimateCreateTestFixtures.makeSelectedMedia(id: "00000000-0000-0000-0000-000000000001")],
                syncedMediaAssets: [
                    AnimateCreateTestFixtures.makeMediaAsset(id: "second", sortOrder: 1),
                    AnimateCreateTestFixtures.makeMediaAsset(id: "first", sortOrder: 0)
                ],
                isImporting: true,
                statusMessage: "Importing."
            ),
            canAddMedia: true,
            availabilityMessage: "Add media."
        )

        XCTAssertEqual(presentation.activeMomentId, "moment-1")
        XCTAssertEqual(presentation.pickerTitle, "Adding media...")
        XCTAssertEqual(presentation.remainingSlots, 0)
        XCTAssertEqual(presentation.selectedCountTitle, "1 selected")
        XCTAssertEqual(presentation.selectionMessage, "")
        XCTAssertEqual(presentation.syncedMediaAssets.map(\.id), ["first", "second"])
        XCTAssertTrue(presentation.canAddMedia)
        XCTAssertEqual(presentation.availabilityMessage, "Add media.")
    }

    func testMediaPresentationBlocksMultipleSourceImages() {
        let presentation = AnimateCreateMediaPresentation(
            activeMomentId: "moment-1",
            template: .birthdayMessage,
            summary: AnimateCreateMediaSummary(
                selectedMedia: [
                    AnimateCreateTestFixtures.makeSelectedMedia(id: "00000000-0000-0000-0000-000000000001"),
                    AnimateCreateTestFixtures.makeSelectedMedia(id: "00000000-0000-0000-0000-000000000002")
                ]
            )
        )

        XCTAssertEqual(presentation.selectionMessage, "Use one photo for Animate AV videos.")
    }

    func testStoryPresentationFormatsPreparationStateAndSortsSavedScenes() {
        let presentation = AnimateCreateStoryPresentation(
            summary: AnimateCreateStorySummary(
                savedScenes: [
                    AnimateCreateTestFixtures.makeScene(id: "scene-2", sceneIndex: 1),
                    AnimateCreateTestFixtures.makeScene(id: "scene-1", sceneIndex: 0)
                ],
                generatedScenes: [],
                isPlanning: true,
                statusMessage: "Planning."
            ),
            canPlanStory: true,
            availabilityMessage: "Ready."
        )

        XCTAssertEqual(presentation.planButtonTitle, "Preparing video...")
        XCTAssertEqual(presentation.emptyMessage, "Avi can prepare the animation plan from your photo.")
        XCTAssertEqual(presentation.savedScenes.map(\.id), ["scene-1", "scene-2"])
        XCTAssertTrue(presentation.canPlanStory)
        XCTAssertEqual(presentation.availabilityMessage, "Ready.")
    }

    func testFinalVideoActionPresentationSeparatesPlanAndCreditConfirmation() {
        let planning = AnimateCreateFinalVideoActionPresentation(
            summary: AnimateCreateFinalRenderSummary(creditCost: 2),
            template: .birthdayMessage,
            balance: AnimateCreditBalance(proMonthly: 0, promotional: 3, purchased: 0)
        )

        XCTAssertFalse(planning.hasRenderPlan)
        XCTAssertEqual(planning.primaryTitle, "Check credits")
        XCTAssertEqual(planning.primaryIconName, "creditcard.fill")
        XCTAssertEqual(planning.creditPolicyMessage, "Avi checks the photo and credits before animating.")
        XCTAssertTrue(planning.canAffordSelectedCost)

        let ready = AnimateCreateFinalVideoActionPresentation(
            summary: AnimateCreateFinalRenderSummary(
                creditCost: 2,
                renderPlan: AnimateCreateTestFixtures.makeRenderPlan()
            ),
            template: .birthdayMessage,
            balance: AnimateCreditBalance(proMonthly: 0, promotional: 3, purchased: 0),
            removesWatermark: true
        )

        XCTAssertTrue(ready.hasRenderPlan)
        XCTAssertEqual(ready.totalCreditCostTitle, "2 credits")
        XCTAssertEqual(ready.primaryTitle, "Confirm credits · 2 credits")
        XCTAssertEqual(ready.primaryIconName, "video.fill")
        XCTAssertEqual(
            ready.creditPolicyMessage,
            "Credits are only charged for completed final videos. This video costs 2 credits."
        )
        XCTAssertEqual(
            ready.confirmationMessage,
            "Credits are only charged for completed final videos. This video costs 2 credits."
        )
    }

    func testPrimaryActionPresentationAllowsRetryForUnavailableFinalProviderPlan() {
        let unavailablePlan = MomentsRenderPlanResponse(
            appId: "animateav",
            momentId: "moment-1",
            planId: "plan-1",
            plan: AnimateCreateTestFixtures.makeRenderPlan().plan,
            canCreateVideo: false,
            createVideoBlockers: ["provider_adapter_unavailable"],
            generatedAt: "2026-06-02T00:00:00Z"
        )
        let workflow = AnimateCreateWorkflowPresentation(
            activeMomentId: "moment-1",
            isSignedIn: true,
            hasMomentWorkspace: true,
            template: .birthdayMessage,
            balance: AnimateCreditBalance(proMonthly: 0, promotional: 3, purchased: 0),
            mediaSummary: AnimateCreateMediaSummary(
                selectedMedia: [AnimateCreateTestFixtures.makeSelectedMedia(id: "00000000-0000-0000-0000-000000000001")]
            ),
            storySummary: AnimateCreateStorySummary(),
            finalRenderSummary: AnimateCreateFinalRenderSummary(
                creditCost: 2,
                renderPlan: unavailablePlan
            ),
            canPrepareFinalRenderPlan: true,
            canGenerateFinalRender: true
        )
        let presentation = AnimateCreatePrimaryActionPresentation(workflow: workflow)

        XCTAssertTrue(presentation.canRunPrimaryAction)
        XCTAssertEqual(presentation.buttonTitle, "Try again")
        XCTAssertEqual(presentation.buttonIconName, "arrow.clockwise")
        XCTAssertEqual(
            presentation.statusMessage,
            "Avi could not prep the cartoon. Try again, or adjust the photo and options."
        )
    }

    func testPrimaryActionPresentationShowsRetryForRecoverableFinalRenderFailure() {
        let failedJob = AnimateCreateTestFixtures.makeRenderJob(
            id: "final-job",
            kind: "final",
            status: "failed",
            userMessage: "Avi could not collect the finished video. You can try again.",
            canRetry: true
        )
        let workflow = AnimateCreateWorkflowPresentation(
            activeMomentId: "moment-1",
            isSignedIn: true,
            hasMomentWorkspace: true,
            template: .birthdayMessage,
            balance: AnimateCreditBalance(proMonthly: 0, promotional: 3, purchased: 0),
            mediaSummary: AnimateCreateMediaSummary(
                selectedMedia: [AnimateCreateTestFixtures.makeSelectedMedia(id: "00000000-0000-0000-0000-000000000001")]
            ),
            storySummary: AnimateCreateStorySummary(),
            finalRenderSummary: AnimateCreateFinalRenderSummary(latestFinalJob: failedJob),
            canPrepareFinalRenderPlan: true,
            canGenerateFinalRender: true
        )
        let presentation = AnimateCreatePrimaryActionPresentation(workflow: workflow)

        XCTAssertTrue(presentation.showsPrimaryActionButton)
        XCTAssertTrue(presentation.canRunPrimaryAction)
        XCTAssertEqual(presentation.buttonTitle, "Try again")
        XCTAssertEqual(presentation.buttonIconName, "arrow.clockwise")
    }

    func testPrimaryActionPresentationKeepsCreateVideoIntentWhileUploadingMedia() {
        let presentation = AnimateCreatePrimaryActionPresentation(
            workflow: AnimateCreateWorkflowPresentation(
                activeMomentId: "moment-1",
                isSignedIn: true,
                hasMomentWorkspace: true,
                template: .birthdayMessage,
                balance: AnimateCreditBalance(proMonthly: 0, promotional: 2, purchased: 0),
                mediaSummary: AnimateCreateMediaSummary(
                    selectedMedia: [AnimateCreateTestFixtures.makeSelectedMedia(id: "00000000-0000-0000-0000-000000000001")],
                    isImporting: true,
                    statusMessage: "Uploading media for video creation."
                ),
                storySummary: AnimateCreateStorySummary(),
                finalRenderSummary: AnimateCreateFinalRenderSummary(creditCost: 2),
                canPlanStory: false,
                canPrepareFinalRenderPlan: false,
                canGenerateFinalRender: false
            )
        )

        XCTAssertTrue(presentation.hasFinalVideoIntent)
        XCTAssertFalse(presentation.canRunPrimaryAction)
        XCTAssertEqual(presentation.title, "Continue")
        XCTAssertEqual(presentation.buttonTitle, "Continue")
        XCTAssertEqual(presentation.buttonIconName, "creditcard.fill")
        XCTAssertEqual(presentation.statusMessage, "Uploading media for video creation.")
    }

    func testPrimaryActionPresentationUsesCreateVideoForInternalStoryPreflight() {
        let presentation = AnimateCreatePrimaryActionPresentation(
            workflow: AnimateCreateWorkflowPresentation(
                activeMomentId: "moment-1",
                isSignedIn: true,
                hasMomentWorkspace: true,
                template: .birthdayMessage,
                balance: AnimateCreditBalance(proMonthly: 0, promotional: 2, purchased: 0),
                mediaSummary: AnimateCreateMediaSummary(
                    selectedMedia: [AnimateCreateTestFixtures.makeSelectedMedia(id: "00000000-0000-0000-0000-000000000001")]
                ),
                storySummary: AnimateCreateStorySummary(),
                finalRenderSummary: AnimateCreateFinalRenderSummary(creditCost: 2),
                canPlanStory: true,
                canPrepareFinalRenderPlan: false,
                canGenerateFinalRender: false
            )
        )

        XCTAssertTrue(presentation.canRunPrimaryAction)
        XCTAssertEqual(presentation.title, "Continue")
        XCTAssertEqual(presentation.buttonTitle, "Continue")
        XCTAssertEqual(presentation.statusMessage, "You will see the cost before creating the video.")
    }

    func testPrimaryActionPresentationShowsBackendPlanCostBeforeConfirmation() {
        let presentation = AnimateCreatePrimaryActionPresentation(
            workflow: AnimateCreateWorkflowPresentation(
                activeMomentId: "moment-1",
                isSignedIn: true,
                hasMomentWorkspace: true,
                template: .birthdayMessage,
                balance: AnimateCreditBalance(proMonthly: 0, promotional: 3, purchased: 0),
                mediaSummary: AnimateCreateMediaSummary(
                    syncedMediaAssets: [AnimateCreateTestFixtures.makeMediaAsset(id: "media-1")]
                ),
                storySummary: AnimateCreateStorySummary(
                    savedScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")]
                ),
                finalRenderSummary: AnimateCreateFinalRenderSummary(
                    creditCost: 2,
                    renderPlan: AnimateCreateTestFixtures.makeRenderPlan()
                ),
                canPlanStory: false,
                canPrepareFinalRenderPlan: false,
                canGenerateFinalRender: true
            )
        )

        XCTAssertTrue(presentation.canRunPrimaryAction)
        XCTAssertEqual(presentation.title, "Ready to create")
        XCTAssertEqual(presentation.buttonTitle, "Confirm credits · 2 credits")
        XCTAssertEqual(
            presentation.statusMessage,
            "Credits are only charged for completed final videos. This video costs 2 credits."
        )
    }

    func testPrimaryActionPresentationOpensCreditsForBackendInsufficientCreditPlan() {
        let presentation = AnimateCreatePrimaryActionPresentation(
            workflow: AnimateCreateWorkflowPresentation(
                activeMomentId: "moment-1",
                isSignedIn: true,
                hasMomentWorkspace: true,
                template: .birthdayMessage,
                balance: AnimateCreditBalance(proMonthly: 0, promotional: 0, purchased: 0),
                mediaSummary: AnimateCreateMediaSummary(
                    syncedMediaAssets: [AnimateCreateTestFixtures.makeMediaAsset(id: "media-1")]
                ),
                storySummary: AnimateCreateStorySummary(
                    savedScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")]
                ),
                finalRenderSummary: AnimateCreateFinalRenderSummary(
                    creditCost: 2,
                    renderPlan: AnimateCreateTestFixtures.makeRenderPlan(
                        canCreateVideo: false,
                        createVideoBlockers: ["insufficient_credits"]
                    )
                ),
                canPlanStory: false,
                canPrepareFinalRenderPlan: false,
                canGenerateFinalRender: false
            )
        )

        XCTAssertTrue(presentation.canRunPrimaryAction)
        XCTAssertTrue(presentation.needsCreditsForPreparedPlan)
        XCTAssertEqual(presentation.buttonTitle, "Get credits")
        XCTAssertEqual(presentation.buttonIconName, "plus.circle.fill")
        XCTAssertEqual(presentation.statusMessage, "Add 2 more credits before creating the final video.")
    }

    func testPrimaryActionPresentationTrustsBackendInsufficientCreditBlockerWhenLocalBalanceIsStale() {
        let presentation = AnimateCreatePrimaryActionPresentation(
            workflow: AnimateCreateWorkflowPresentation(
                activeMomentId: "moment-1",
                isSignedIn: true,
                hasMomentWorkspace: true,
                template: .birthdayMessage,
                balance: AnimateCreditBalance(proMonthly: 0, promotional: 5, purchased: 0),
                mediaSummary: AnimateCreateMediaSummary(
                    syncedMediaAssets: [AnimateCreateTestFixtures.makeMediaAsset(id: "media-1")]
                ),
                storySummary: AnimateCreateStorySummary(
                    savedScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")]
                ),
                finalRenderSummary: AnimateCreateFinalRenderSummary(
                    creditCost: 1,
                    renderPlan: AnimateCreateTestFixtures.makeRenderPlan(
                        canCreateVideo: false,
                        totalCreditCost: 1,
                        createVideoBlockers: ["provider_adapter_unavailable", "insufficient_credits"]
                    )
                ),
                canPlanStory: false,
                canPrepareFinalRenderPlan: true,
                canGenerateFinalRender: false
            )
        )

        XCTAssertTrue(presentation.canRunPrimaryAction)
        XCTAssertTrue(presentation.needsCreditsForPreparedPlan)
        XCTAssertEqual(presentation.buttonTitle, "Get credits")
        XCTAssertEqual(presentation.buttonIconName, "plus.circle.fill")
        XCTAssertEqual(presentation.statusMessage, "Add credits before creating the final video.")
    }

    func testPrimaryActionPresentationShowsFinalRenderErrorOverPreparedPlanCopy() {
        let presentation = AnimateCreatePrimaryActionPresentation(
            workflow: AnimateCreateWorkflowPresentation(
                activeMomentId: "moment-1",
                isSignedIn: true,
                hasMomentWorkspace: true,
                template: .birthdayMessage,
                balance: AnimateCreditBalance(proMonthly: 0, promotional: 3, purchased: 0),
                mediaSummary: AnimateCreateMediaSummary(
                    syncedMediaAssets: [AnimateCreateTestFixtures.makeMediaAsset(id: "media-1")]
                ),
                storySummary: AnimateCreateStorySummary(
                    savedScenes: [AnimateCreateTestFixtures.makeScene(id: "scene-1")]
                ),
                finalRenderSummary: AnimateCreateFinalRenderSummary(
                    creditCost: 2,
                    renderPlan: AnimateCreateTestFixtures.makeRenderPlan(),
                    statusMessage: "The video plan changed. Review the latest plan before creating the video."
                ),
                canPlanStory: false,
                canPrepareFinalRenderPlan: false,
                canGenerateFinalRender: true
            )
        )

        XCTAssertTrue(presentation.canRunPrimaryAction)
        XCTAssertEqual(presentation.title, "Ready to create")
        XCTAssertEqual(presentation.buttonTitle, "Confirm credits · 2 credits")
        XCTAssertEqual(
            presentation.statusMessage,
            "The video plan changed. Review the latest plan before creating the video."
        )
    }

    func testRealtimeRenderPresentationFormatsActivePhaseAndProgress() {
        let job = AnimateCreateTestFixtures.makeRenderJob(
            id: "final-job",
            kind: "final",
            status: "running",
            phase: "rendering",
            progressPercent: 42,
            userMessage: "Rendering your video.",
            canEditSetup: false
        )

        let presentation = MomentsRenderRealtimePresentation(renderJob: job)

        XCTAssertEqual(presentation.title, "Rendering")
        XCTAssertEqual(presentation.detail, "Rendering your video.")
        XCTAssertEqual(presentation.progressFraction ?? -1, 0.42, accuracy: 0.001)
        XCTAssertEqual(presentation.systemImage, "gearshape.2.fill")
        XCTAssertTrue(presentation.isActive)
        XCTAssertFalse(presentation.canEditSetup)
    }

    func testRealtimeRenderPresentationFormatsFailedStatus() {
        let job = AnimateCreateTestFixtures.makeRenderJob(
            id: "final-job",
            kind: "final",
            status: "failed",
            canEditSetup: true,
            errorMessage: "fal provider request failed with upstream trace id abc123"
        )

        let presentation = MomentsRenderRealtimePresentation(renderJob: job)

        XCTAssertEqual(presentation.title, "Needs attention")
        XCTAssertEqual(
            presentation.detail,
            "Video creation hit a problem. If the final video was not completed, credits will not be charged. Please try again or contact support."
        )
        XCTAssertEqual(presentation.systemImage, "exclamationmark.triangle.fill")
        XCTAssertFalse(presentation.isActive)
        XCTAssertTrue(presentation.canEditSetup)
    }

    func testRealtimeRenderPresentationUsesSafeFailedUserMessage() {
        let job = AnimateCreateTestFixtures.makeRenderJob(
            id: "final-job",
            kind: "final",
            status: "failed",
            userMessage: "We couldn’t finish this video. No credits were charged.",
            canEditSetup: true,
            errorMessage: "provider stack trace"
        )

        let presentation = MomentsRenderRealtimePresentation(renderJob: job)

        XCTAssertEqual(presentation.detail, "We couldn’t finish this video. No credits were charged.")
    }

    func testRecoveryCopyCoversMediaAndStoryFailurePaths() {
        XCTAssertEqual(
            MomentsRecoveryCopy.mediaImportFailure(),
            "Couldn’t add that photo. It is still on this device; try again or choose a different image."
        )
        XCTAssertEqual(
            MomentsRecoveryCopy.mediaUploadUnavailable(),
            "Photo upload is not ready yet. Your photo is still on this device; please try again in a moment."
        )
        XCTAssertEqual(
            MomentsRecoveryCopy.mediaStorySaveFailure(),
            "Couldn’t save the photo for the video. Your photo is still on this device; try again or choose a different image."
        )
        XCTAssertEqual(
            MomentsRecoveryCopy.storyStartFailure(),
            "Couldn’t start this video. No Credits were used. Please try again."
        )
        XCTAssertEqual(
            MomentsRecoveryCopy.storyFailure(),
            "Avi couldn’t prepare the video right now. No Credits were used. Please try again."
        )
    }

    func testWorkspaceSummaryFormatsProgressDetails() {
        let summary = AnimateCreateWorkspaceSummary(
            mediaCount: 2,
            sceneCount: 1,
            renderJobCount: 1,
            hasFinalExport: false
        )

        XCTAssertEqual(summary.mediaDetail, "2 added")
        XCTAssertEqual(summary.storyDetail, "1 scene")
    }

    func testCreateUITestFixturesExposePreRenderStates() {
        let storyReadyWorkspace = AnimateCreateUITestFixtures.workspace(for: .storyReady)
        let videoPlanWorkspace = AnimateCreateUITestFixtures.workspace(for: .videoPlanReady)
        let lowCreditsPlan = AnimateCreateUITestFixtures.renderPlan(for: .videoPlanInsufficientCredits)
        let queuedWorkspace = AnimateCreateUITestFixtures.workspace(for: .finalQueued)
        let runningWorkspace = AnimateCreateUITestFixtures.workspace(for: .finalRunning)
        let fullWorkspace = AnimateCreateUITestFixtures.workspace(for: .full)

        XCTAssertEqual(storyReadyWorkspace.moment.status, "story_ready")
        XCTAssertEqual(videoPlanWorkspace.moment.status, "story_ready")
        XCTAssertEqual(queuedWorkspace.moment.status, "rendering")
        XCTAssertEqual(runningWorkspace.moment.status, "rendering")
        XCTAssertEqual(fullWorkspace.moment.status, "gallery_ready")
        XCTAssertFalse(storyReadyWorkspace.storyScenes.isEmpty)
        XCTAssertFalse(videoPlanWorkspace.storyScenes.isEmpty)
        XCTAssertTrue(storyReadyWorkspace.renderJobs.isEmpty)
        XCTAssertTrue(videoPlanWorkspace.renderJobs.isEmpty)
        XCTAssertEqual(queuedWorkspace.latestRenderJob(kind: "final")?.status, "queued")
        XCTAssertEqual(runningWorkspace.latestRenderJob(kind: "final")?.status, "running")
        XCTAssertEqual(AnimateCreateUITestFixtures.balance(for: .videoPlanInsufficientCredits).spendable, 0)
        XCTAssertFalse(lowCreditsPlan.canCreateVideo)
        XCTAssertEqual(lowCreditsPlan.createVideoBlockers, ["insufficient_credits"])
        XCTAssertNil(storyReadyWorkspace.latestArtifact(kind: "final_export"))
        XCTAssertNil(videoPlanWorkspace.latestArtifact(kind: "final_export"))
        XCTAssertNil(queuedWorkspace.latestArtifact(kind: "final_export"))
        XCTAssertNil(runningWorkspace.latestArtifact(kind: "final_export"))
        XCTAssertEqual(fullWorkspace.latestArtifact(kind: "final_export")?.id, "final-artifact-1")
        XCTAssertEqual(AnimateCreateUITestFixtures.renderPlan.momentId, AnimateCreateUITestFixtures.momentId)
    }

}
