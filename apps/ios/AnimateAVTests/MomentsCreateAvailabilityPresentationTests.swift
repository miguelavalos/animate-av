import XCTest
@testable import AnimateAV

@MainActor
final class MomentsCreateAvailabilityPresentationTests: XCTestCase {
    func testWorkflowAvailabilityBuilderCarriesCapabilitiesAndMessages() {
        let availability = MomentsCreateWorkflowAvailability.make(
            canAddMedia: true,
            canPlanStory: false,
            canPrepareFinalRenderPlan: true,
            canGenerateFinalRender: true,
            canRefreshFinalRenderStatus: false,
            mediaMessage: "Media",
            storyMessage: "Story",
            finalRenderMessage: "Final"
        )

        XCTAssertTrue(availability.canAddMedia)
        XCTAssertFalse(availability.canPlanStory)
        XCTAssertTrue(availability.canPrepareFinalRenderPlan)
        XCTAssertTrue(availability.canGenerateFinalRender)
        XCTAssertFalse(availability.canRefreshFinalRenderStatus)
        XCTAssertEqual(availability.mediaMessage, "Media")
        XCTAssertEqual(availability.storyMessage, "Story")
        XCTAssertEqual(availability.finalRenderMessage, "Final")
    }

    func testWorkflowCapabilityFactoryFormatsMediaAndFinalRenderCapabilities() {
        let capability = MomentsCreateWorkflowCapabilityFactory.make(
            activeMomentId: "moment-1",
            isSignedIn: true,
            hasMomentWorkspace: true,
            isImportingMedia: false,
            mediaRemainingSlots: 2,
            storyWorkflow: nil,
            finalRenderWorkflow: nil,
            template: .birthdayMessage,
            selectedMediaCount: 0
        )

        XCTAssertTrue(capability.canAddMedia)
        XCTAssertFalse(capability.canPlanStory)
        XCTAssertFalse(capability.canPrepareFinalRenderPlan)
        XCTAssertFalse(capability.canGenerateFinalRender)
        XCTAssertFalse(capability.canRefreshFinalRenderStatus)
    }

    func testWorkflowCapabilityFactoryBlocksMediaWithoutSlotsOrMoment() {
        let withoutSlots = MomentsCreateWorkflowCapabilityFactory.make(
            activeMomentId: "moment-1",
            isSignedIn: true,
            hasMomentWorkspace: true,
            isImportingMedia: false,
            mediaRemainingSlots: 0,
            storyWorkflow: nil,
            finalRenderWorkflow: nil,
            template: .birthdayMessage,
            selectedMediaCount: 0
        )
        let withoutMoment = MomentsCreateWorkflowCapabilityFactory.make(
            activeMomentId: nil,
            isSignedIn: true,
            hasMomentWorkspace: false,
            isImportingMedia: false,
            mediaRemainingSlots: 2,
            storyWorkflow: nil,
            finalRenderWorkflow: nil,
            template: .birthdayMessage,
            selectedMediaCount: 0
        )

        XCTAssertFalse(withoutSlots.canAddMedia)
        XCTAssertFalse(withoutMoment.canAddMedia)
    }

    func testAvailabilityCopyUsesSingularAndPluralCreditMessages() {
        XCTAssertEqual(MomentsCreateAvailabilityCopy.momentSignInRequired, "Sign in before starting a video.")
        XCTAssertEqual(MomentsCreateAvailabilityCopy.mediaTemplateFull, "Avi has enough media for this video.")
        XCTAssertEqual(MomentsCreateAvailabilityCopy.storyMissingMedia, "Add one source image before preparing the video.")
        XCTAssertEqual(
            MomentsCreateAvailabilityCopy.finalRenderMissingWorkspace,
            "Wait for this video to sync before creating the final video."
        )
        XCTAssertEqual(
            MomentsCreateAvailabilityCopy.finalRenderInsufficientCredits(missingCredits: 2),
            "Add 2 more credits before creating the final video."
        )
    }

    func testAvailabilityMessageFactoryFormatsMediaStates() {
        XCTAssertEqual(
            MomentsCreateAvailabilityMessageFactory.media(
                hasMomentWorkspace: false,
                isImportingMedia: false,
                isMediaUploadConfigured: true,
                mediaRemainingSlots: 2
            ),
            MomentsCreateAvailabilityCopy.mediaMissingMoment
        )
        XCTAssertNil(
            MomentsCreateAvailabilityMessageFactory.media(
                hasMomentWorkspace: true,
                isImportingMedia: true,
                isMediaUploadConfigured: false,
                mediaRemainingSlots: 0
            )
        )
        XCTAssertEqual(
            MomentsCreateAvailabilityMessageFactory.media(
                hasMomentWorkspace: true,
                isImportingMedia: false,
                isMediaUploadConfigured: true,
                mediaRemainingSlots: 0
            ),
            MomentsCreateAvailabilityCopy.mediaTemplateFull
        )
    }

    func testAvailabilityMessageFactoryFormatsStoryStates() {
        XCTAssertEqual(
            MomentsCreateAvailabilityMessageFactory.story(
                isSignedIn: true,
                hasMomentWorkspace: true,
                isStoryPlanning: false,
                isStoryAvailable: true,
                isStoryConfigured: true,
                mediaAssets: [],
                selectedMediaCount: 0,
                template: .birthdayMessage
            ),
            "Add 1 more source image before preparing the video."
        )
        XCTAssertNil(
            MomentsCreateAvailabilityMessageFactory.story(
                isSignedIn: true,
                hasMomentWorkspace: true,
                isStoryPlanning: true,
                isStoryAvailable: true,
                isStoryConfigured: false,
                mediaAssets: [],
                selectedMediaCount: 0,
                template: .birthdayMessage
            )
        )
    }

    func testAvailabilityMessageFactoryFormatsFinalRenderStoryRequirement() {
        XCTAssertEqual(
            MomentsCreateAvailabilityMessageFactory.finalRender(
                activeMomentId: "moment-1",
                isFinalRenderAvailable: true,
                isFinalRenderGenerating: false,
                isFinalRenderConfigured: true,
                moment: MomentsCreateTestFixtures.makeMoment(id: "moment-1"),
                template: .birthdayMessage,
                balance: MomentsCreditBalance(proMonthly: 4, promotional: 0, purchased: 0)
            ),
            "Prepare the video before creating the final video."
        )
    }

    func testFinalRenderCreditsLoadingDoesNotReportInsufficientCredits() {
        XCTAssertEqual(
            MomentsCreateAvailabilityMessageFactory.finalRender(
                activeMomentId: "moment-1",
                isFinalRenderAvailable: true,
                isFinalRenderGenerating: false,
                isFinalRenderConfigured: true,
                moment: MomentsCreateTestFixtures.makeMoment(id: "moment-1", status: "story_ready"),
                template: .birthdayMessage,
                balance: .empty,
                creditBalanceLoadState: .loading
            ),
            "Checking your credits before the final video."
        )
    }

    func testFinalRenderCreditsOfflineDoesNotReportInsufficientCredits() {
        XCTAssertEqual(
            MomentsCreateAvailabilityMessageFactory.finalRender(
                activeMomentId: "moment-1",
                isFinalRenderAvailable: true,
                isFinalRenderGenerating: false,
                isFinalRenderConfigured: true,
                moment: MomentsCreateTestFixtures.makeMoment(id: "moment-1", status: "story_ready"),
                template: .birthdayMessage,
                balance: .empty,
                creditBalanceLoadState: .offline
            ),
            "Connect to the internet before creating the final video."
        )
    }

}
