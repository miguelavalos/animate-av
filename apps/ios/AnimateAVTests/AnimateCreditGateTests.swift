import XCTest
@testable import AnimateAV

final class AnimateCreditGateTests: XCTestCase {
    func testPurchaseCatalogRequiresAllPaywallProducts() {
        XCTAssertFalse(AnimatePurchaseCatalog.empty.hasRequiredPaywallProducts)

        let partialCatalog = AnimatePurchaseCatalog(entriesByProductId: [
            AnimateCreditProductID.proMonthlyProduct: purchaseCatalogEntry(productId: AnimateCreditProductID.proMonthlyProduct),
            AnimateCreditProductID.starterPackProduct: purchaseCatalogEntry(productId: AnimateCreditProductID.starterPackProduct)
        ])

        XCTAssertFalse(partialCatalog.hasRequiredPaywallProducts)

        let completeCatalog = AnimatePurchaseCatalog(entriesByProductId: Dictionary(
            uniqueKeysWithValues: AnimateCreditPaywallProduct.all.map {
                ($0.id, purchaseCatalogEntry(productId: $0.id))
            }
        ))

        XCTAssertTrue(completeCatalog.hasRequiredPaywallProducts)
    }

    func testEmptyBalanceCannotAffordAnyLaunchTemplate() {
        XCTAssertFalse(
            AnimateCreditGate.canAffordAny(AnimateVideoTemplate.launchTemplates, balance: .empty)
        )
    }

    func testPurchasedCreditsAllowCreationWithoutProMonthlyCredits() {
        let balance = AnimateCreditBalance(proMonthly: 0, promotional: 0, purchased: 2)

        XCTAssertTrue(
            AnimateCreditGate.canAfford(AnimateVideoTemplate.birthdayMessage, balance: balance)
        )
    }

    func testSpendableUsesBackendAvailableCreditsWhenProvided() {
        let balance = AnimateCreditBalance(
            proMonthly: 0,
            promotional: 5,
            purchased: 0,
            availableCredits: 0
        )

        XCTAssertEqual(balance.spendable, 0)
        XCTAssertFalse(AnimateCreditGate.canAfford(AnimateVideoTemplate.birthdayMessage, balance: balance))
    }

    func testPartyRecapRequiresTwoSpendableCredits() {
        XCTAssertTrue(
            AnimateCreditGate.canAfford(
                AnimateVideoTemplate.partyRecap,
                balance: AnimateCreditBalance(proMonthly: 0, promotional: 0, purchased: 2)
            )
        )
    }

    func testSpendPlanUsesProThenPromotionalThenPurchasedCredits() {
        let plan = AnimateCreditGate.spendPlan(
            for: 5,
            balance: AnimateCreditBalance(proMonthly: 2, promotional: 2, purchased: 4)
        )

        XCTAssertEqual(
            plan,
            AnimateCreditSpendPlan(proMonthly: 2, promotional: 2, purchased: 1)
        )
    }

    func testSpendPlanIsNilWhenBalanceCannotCoverCost() {
        XCTAssertNil(
            AnimateCreditGate.spendPlan(
                for: 3,
                balance: AnimateCreditBalance(proMonthly: 0, promotional: 1, purchased: 1)
            )
        )
    }

    func testLaunchTemplateDurationsCreditsAndAssetRanges() {
        XCTAssertEqual(AnimateVideoTemplate.birthdayMessage.durationSeconds, 5)
        XCTAssertEqual(AnimateVideoTemplate.birthdayMessage.creditCost, 1)
        XCTAssertEqual(AnimateVideoTemplate.birthdayMessage.minimumAssets, 1)
        XCTAssertEqual(AnimateVideoTemplate.birthdayMessage.maximumAssets, 1)

        XCTAssertEqual(AnimateVideoTemplate.partyRecap.durationSeconds, 10)
        XCTAssertEqual(AnimateVideoTemplate.partyRecap.creditCost, 1)
        XCTAssertEqual(AnimateVideoTemplate.partyRecap.minimumAssets, 1)
        XCTAssertEqual(AnimateVideoTemplate.partyRecap.maximumAssets, 1)

        XCTAssertEqual(AnimateVideoTemplate.softRoast.durationSeconds, 15)
        XCTAssertEqual(AnimateVideoTemplate.softRoast.creditCost, 1)
        XCTAssertEqual(AnimateVideoTemplate.softRoast.minimumAssets, 1)
        XCTAssertEqual(AnimateVideoTemplate.softRoast.maximumAssets, 1)
    }

    func testSetupFormRequiresOccasionBeforeCreate() {
        var form = AnimateVideoSetupForm(template: .birthdayMessage)

        XCTAssertTrue(form.canCreateVideo)

        form.occasion = "  "

        XCTAssertFalse(form.canCreateVideo)
    }

    func testSetupAvailabilityAllowsSetupWithoutCredits() {
        var form = AnimateVideoSetupForm(template: .birthdayMessage)
        form.occasion = "Birthday"

        let availability = AnimateVideoSetupRules.availability(
            form: form,
            balance: .empty
        )

        XCTAssertTrue(availability.canCreateVideo)
        XCTAssertNil(AnimateVideoSetupRules.availabilityMessage(availability))
    }

    func testContinuingSetupFormUsesVideoFieldsAndFallbacks() {
        let video = AnimateVideo(
            id: "video-1",
            template: .birthdayMessage,
            status: "in_progress",
            title: "Birthday",
            tone: "cinematic",
            tempo: "not-a-tempo",
            occasion: "Anniversary",
            details: "Use the beach clips.",
            durationSeconds: 30,
            creditCost: 2,
            updatedAt: 0
        )

        let form = AnimateVideoSetupForm.continuing(
            video: video,
            templates: AnimateVideoTemplate.launchTemplates
        )

        XCTAssertEqual(form?.template.id, .birthdayMessage)
        XCTAssertEqual(form?.occasion, "Anniversary")
        XCTAssertEqual(form?.recipient, "")
        XCTAssertEqual(form?.tone, .cinematic)
        XCTAssertEqual(form?.tempo, .balanced)
        XCTAssertEqual(form?.details, "Use the beach clips.")
    }

    func testMediaRulesEnforceTemplateMinimumsAndMaximums() {
        XCTAssertFalse(AnimateMediaRules.canUseSelection(template: .birthdayMessage, selectedCount: 0))
        XCTAssertTrue(AnimateMediaRules.canUseSelection(template: .birthdayMessage, selectedCount: 1))
        XCTAssertFalse(AnimateMediaRules.canUseSelection(template: .birthdayMessage, selectedCount: 2))

        XCTAssertFalse(AnimateMediaRules.canUseSelection(template: .partyRecap, selectedCount: 0))
        XCTAssertTrue(AnimateMediaRules.canUseSelection(template: .partyRecap, selectedCount: 1))
        XCTAssertFalse(AnimateMediaRules.canUseSelection(template: .partyRecap, selectedCount: 2))
    }

    func testVideoDirectionRulesUseSelectedConvexMediaCount() {
        let assets = (0..<3).map {
            AnimateMediaAsset(
                id: "media-\($0)",
                platformMediaAssetId: "platform-media-\($0)",
                uploadId: "upload-\($0)",
                kind: "photo",
                sortOrder: Double($0),
                selected: true,
                moderationStatus: "pending",
                uploadedAt: 1_779_000_000_000,
                sourceExpiresAt: 1_781_592_000_000
            )
        }

        XCTAssertFalse(AnimateVideoDirectionRules.canPlan(mediaAssets: assets, template: .birthdayMessage))
        XCTAssertFalse(AnimateVideoDirectionRules.canPlan(mediaAssets: assets, template: .partyRecap))
    }

    func testVideoDirectionInputSignatureTracksMediaOrderAndDirection() {
        func videoDirectionMedia(id: String, sortOrder: Int) -> AnimateVideoDirectionMedia {
            AnimateVideoDirectionMedia(
                mediaAssetId: id,
                mediaKind: "image",
                sortOrder: sortOrder,
                selected: true,
                moderationStatus: "approved"
            )
        }

        var form = AnimateVideoSetupForm(template: .birthdayMessage)
        form.occasion = "Trip"
        form.hasMessage = true
        form.details = "Use the desert photos."
        let media = [
            videoDirectionMedia(id: "media-a", sortOrder: 0),
            videoDirectionMedia(id: "media-b", sortOrder: 1)
        ]

        let baseSignature = AnimateVideoDirectionInputSignature.make(
            videoId: "video-1",
            form: form,
            selectedMedia: media
        )
        let sameInputSignature = AnimateVideoDirectionInputSignature.make(
            videoId: "video-1",
            form: form,
            selectedMedia: media.reversed()
        )

        XCTAssertEqual(baseSignature, sameInputSignature)

        let reorderedSignature = AnimateVideoDirectionInputSignature.make(
            videoId: "video-1",
            form: form,
            selectedMedia: [
                videoDirectionMedia(id: "media-a", sortOrder: 1),
                videoDirectionMedia(id: "media-b", sortOrder: 0)
            ]
        )
        XCTAssertNotEqual(baseSignature, reorderedSignature)

        form.details = "Use the desert photos and end on the group shot."
        let changedDirectionSignature = AnimateVideoDirectionInputSignature.make(
            videoId: "video-1",
            form: form,
            selectedMedia: media
        )
        XCTAssertNotEqual(baseSignature, changedDirectionSignature)
    }

    func testFinalRenderRulesRequireReadyStatusAndCredits() {
        let balance = AnimateCreditBalance(proMonthly: 0, promotional: 0, purchased: 2)
        let video = AnimateVideo(
            id: "video-1",
            template: .birthdayMessage,
            status: "story_ready",
            title: "Birthday",
            tone: nil,
            tempo: nil,
            occasion: nil,
            details: nil,
            durationSeconds: 30,
            creditCost: 2,
            updatedAt: 0
        )
        XCTAssertTrue(
            AnimateFinalRenderRules.canGenerate(
                video: video,
                template: .birthdayMessage,
                balance: balance
            )
        )
        XCTAssertFalse(
            AnimateFinalRenderRules.canGenerate(
                video: video,
                template: .birthdayMessage,
                balance: .empty
            )
        )
        XCTAssertTrue(AnimateFinalRenderRules.canPreparePlan(video: video))
        XCTAssertTrue(
            AnimateFinalRenderRules.canGenerate(
                video: video,
                template: .birthdayMessage,
                balance: balance
            )
        )

        let staleDirectionVideo = AnimateVideo(
            id: video.id,
            template: video.template,
            status: "in_progress",
            title: video.title,
            tone: video.tone,
            tempo: video.tempo,
            occasion: video.occasion,
            details: video.details,
            durationSeconds: video.durationSeconds,
            creditCost: video.creditCost,
            updatedAt: video.updatedAt
        )
        XCTAssertFalse(AnimateFinalRenderRules.canPreparePlan(video: staleDirectionVideo))
        XCTAssertTrue(AnimateFinalRenderRules.canPreparePlan(video: staleDirectionVideo, storySceneCount: 1))
        XCTAssertTrue(
            AnimateFinalRenderRules.canGenerate(
                video: staleDirectionVideo,
                template: .birthdayMessage,
                balance: balance,
                storySceneCount: 1
            )
        )
    }

    private func purchaseCatalogEntry(productId: String) -> AnimatePurchaseCatalog.Entry {
        AnimatePurchaseCatalog.Entry(
            productId: productId,
            packageIdentifier: productId,
            localizedTitle: productId,
            localizedPrice: "$1.00"
        )
    }
}
