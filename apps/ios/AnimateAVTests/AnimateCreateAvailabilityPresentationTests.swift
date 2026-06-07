import XCTest
@testable import AnimateAV

@MainActor
final class AnimateCreateAvailabilityPresentationTests: XCTestCase {
    func testWorkflowAvailabilityBuilderCarriesCapabilitiesAndMessages() {
        let availability = AnimateCreateWorkflowAvailability.make(
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
        let capability = AnimateCreateWorkflowCapabilityFactory.make(
            activeVideoId: "moment-1",
            isSignedIn: true,
            hasAnimateWorkspace: true,
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

    func testWorkflowCapabilityFactoryBlocksMediaWithoutSlotsOrVideo() {
        let withoutSlots = AnimateCreateWorkflowCapabilityFactory.make(
            activeVideoId: "moment-1",
            isSignedIn: true,
            hasAnimateWorkspace: true,
            isImportingMedia: false,
            mediaRemainingSlots: 0,
            storyWorkflow: nil,
            finalRenderWorkflow: nil,
            template: .birthdayMessage,
            selectedMediaCount: 0
        )
        let withoutMoment = AnimateCreateWorkflowCapabilityFactory.make(
            activeVideoId: nil,
            isSignedIn: true,
            hasAnimateWorkspace: false,
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
        XCTAssertEqual(AnimateCreateAvailabilityCopy.momentSignInRequired, "Sign in before starting a video.")
        XCTAssertEqual(AnimateCreateAvailabilityCopy.mediaTemplateFull, "Avi has the photo for this video.")
        XCTAssertEqual(AnimateCreateAvailabilityCopy.storyMissingMedia, "Add one photo before preparing the video.")
        XCTAssertEqual(
            AnimateCreateAvailabilityCopy.finalRenderMissingWorkspace,
            "Wait for this video to sync before creating the final video."
        )
        XCTAssertEqual(
            AnimateCreateAvailabilityCopy.finalRenderInsufficientCredits(missingCredits: 2),
            "Add 2 more credits before creating the final video."
        )
    }

    func testAvailabilityMessageFactoryFormatsMediaStates() {
        XCTAssertEqual(
            AnimateCreateAvailabilityMessageFactory.media(
                hasAnimateWorkspace: false,
                isImportingMedia: false,
                isMediaUploadConfigured: true,
                mediaRemainingSlots: 2
            ),
            AnimateCreateAvailabilityCopy.mediaMissingMoment
        )
        XCTAssertNil(
            AnimateCreateAvailabilityMessageFactory.media(
                hasAnimateWorkspace: true,
                isImportingMedia: true,
                isMediaUploadConfigured: false,
                mediaRemainingSlots: 0
            )
        )
        XCTAssertEqual(
            AnimateCreateAvailabilityMessageFactory.media(
                hasAnimateWorkspace: true,
                isImportingMedia: false,
                isMediaUploadConfigured: true,
                mediaRemainingSlots: 0
            ),
            AnimateCreateAvailabilityCopy.mediaTemplateFull
        )
    }

    func testAvailabilityMessageFactoryFormatsStoryStates() {
        XCTAssertEqual(
            AnimateCreateAvailabilityMessageFactory.story(
                isSignedIn: true,
                hasAnimateWorkspace: true,
                isStoryPlanning: false,
                isStoryAvailable: true,
                isStoryConfigured: true,
                mediaAssets: [],
                selectedMediaCount: 0,
                template: .birthdayMessage
            ),
            "Add 1 more photo before preparing the video."
        )
        XCTAssertNil(
            AnimateCreateAvailabilityMessageFactory.story(
                isSignedIn: true,
                hasAnimateWorkspace: true,
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
            AnimateCreateAvailabilityMessageFactory.finalRender(
                activeVideoId: "moment-1",
                isFinalRenderAvailable: true,
                isFinalRenderGenerating: false,
                isFinalRenderConfigured: true,
                video: AnimateCreateTestFixtures.makeMoment(id: "moment-1"),
                template: .birthdayMessage,
                balance: AnimateCreditBalance(proMonthly: 4, promotional: 0, purchased: 0)
            ),
            "Prepare the video before creating the final video."
        )
    }

    func testFinalRenderCreditsLoadingDoesNotReportInsufficientCredits() {
        XCTAssertEqual(
            AnimateCreateAvailabilityMessageFactory.finalRender(
                activeVideoId: "moment-1",
                isFinalRenderAvailable: true,
                isFinalRenderGenerating: false,
                isFinalRenderConfigured: true,
                video: AnimateCreateTestFixtures.makeMoment(id: "moment-1", status: "story_ready"),
                template: .birthdayMessage,
                balance: .empty,
                creditBalanceLoadState: .loading
            ),
            "Checking your credits before the final video."
        )
    }

    func testFinalRenderCreditsOfflineDoesNotReportInsufficientCredits() {
        XCTAssertEqual(
            AnimateCreateAvailabilityMessageFactory.finalRender(
                activeVideoId: "moment-1",
                isFinalRenderAvailable: true,
                isFinalRenderGenerating: false,
                isFinalRenderConfigured: true,
                video: AnimateCreateTestFixtures.makeMoment(id: "moment-1", status: "story_ready"),
                template: .birthdayMessage,
                balance: .empty,
                creditBalanceLoadState: .offline
            ),
            "Connect to the internet before creating the final video."
        )
    }

}
