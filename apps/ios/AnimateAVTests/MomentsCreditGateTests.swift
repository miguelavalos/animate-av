import XCTest
@testable import AnimateAV

final class MomentsCreditGateTests: XCTestCase {
    func testPurchaseCatalogRequiresAllPaywallProducts() {
        XCTAssertFalse(MomentsPurchaseCatalog.empty.hasRequiredPaywallProducts)

        let partialCatalog = MomentsPurchaseCatalog(entriesByProductId: [
            MomentsCreditProductID.proMonthlyProduct: purchaseCatalogEntry(productId: MomentsCreditProductID.proMonthlyProduct),
            MomentsCreditProductID.starterPackProduct: purchaseCatalogEntry(productId: MomentsCreditProductID.starterPackProduct)
        ])

        XCTAssertFalse(partialCatalog.hasRequiredPaywallProducts)

        let completeCatalog = MomentsPurchaseCatalog(entriesByProductId: Dictionary(
            uniqueKeysWithValues: MomentsCreditPaywallProduct.all.map {
                ($0.id, purchaseCatalogEntry(productId: $0.id))
            }
        ))

        XCTAssertTrue(completeCatalog.hasRequiredPaywallProducts)
    }

    func testEmptyBalanceCannotAffordAnyLaunchTemplate() {
        XCTAssertFalse(
            MomentsCreditGate.canAffordAny(MomentTemplate.launchTemplates, balance: .empty)
        )
    }

    func testPurchasedCreditsAllowCreationWithoutProMonthlyCredits() {
        let balance = MomentsCreditBalance(proMonthly: 0, promotional: 0, purchased: 2)

        XCTAssertTrue(
            MomentsCreditGate.canAfford(MomentTemplate.birthdayMessage, balance: balance)
        )
    }

    func testSpendableUsesBackendAvailableCreditsWhenProvided() {
        let balance = MomentsCreditBalance(
            proMonthly: 0,
            promotional: 5,
            purchased: 0,
            availableCredits: 0
        )

        XCTAssertEqual(balance.spendable, 0)
        XCTAssertFalse(MomentsCreditGate.canAfford(MomentTemplate.birthdayMessage, balance: balance))
    }

    func testPartyRecapRequiresTwoSpendableCredits() {
        XCTAssertTrue(
            MomentsCreditGate.canAfford(
                MomentTemplate.partyRecap,
                balance: MomentsCreditBalance(proMonthly: 0, promotional: 0, purchased: 2)
            )
        )
    }

    func testSpendPlanUsesProThenPromotionalThenPurchasedCredits() {
        let plan = MomentsCreditGate.spendPlan(
            for: 5,
            balance: MomentsCreditBalance(proMonthly: 2, promotional: 2, purchased: 4)
        )

        XCTAssertEqual(
            plan,
            MomentsCreditSpendPlan(proMonthly: 2, promotional: 2, purchased: 1)
        )
    }

    func testSpendPlanIsNilWhenBalanceCannotCoverCost() {
        XCTAssertNil(
            MomentsCreditGate.spendPlan(
                for: 3,
                balance: MomentsCreditBalance(proMonthly: 0, promotional: 1, purchased: 1)
            )
        )
    }

    func testLaunchTemplateDurationsCreditsAndAssetRanges() {
        XCTAssertEqual(MomentTemplate.birthdayMessage.durationSeconds, 30)
        XCTAssertEqual(MomentTemplate.birthdayMessage.creditCost, 2)
        XCTAssertEqual(MomentTemplate.birthdayMessage.minimumAssets, 1)
        XCTAssertEqual(MomentTemplate.birthdayMessage.maximumAssets, 80)

        XCTAssertEqual(MomentTemplate.partyRecap.durationSeconds, 30)
        XCTAssertEqual(MomentTemplate.partyRecap.creditCost, 2)
        XCTAssertEqual(MomentTemplate.partyRecap.minimumAssets, 1)
        XCTAssertEqual(MomentTemplate.partyRecap.maximumAssets, 80)

        XCTAssertEqual(MomentTemplate.softRoast.durationSeconds, 30)
        XCTAssertEqual(MomentTemplate.softRoast.creditCost, 2)
        XCTAssertEqual(MomentTemplate.softRoast.minimumAssets, 1)
        XCTAssertEqual(MomentTemplate.softRoast.maximumAssets, 80)
    }

    func testSetupFormRequiresOccasionBeforeCreate() {
        var form = MomentSetupForm(template: .birthdayMessage)

        XCTAssertTrue(form.canCreateMoment)

        form.occasion = "  "

        XCTAssertFalse(form.canCreateMoment)
    }

    func testSetupAvailabilityAllowsSetupWithoutCredits() {
        var form = MomentSetupForm(template: .birthdayMessage)
        form.occasion = "Birthday"

        let availability = MomentSetupRules.availability(
            form: form,
            balance: .empty
        )

        XCTAssertTrue(availability.canCreateMoment)
        XCTAssertNil(MomentSetupRules.availabilityMessage(availability))
    }

    func testContinuingSetupFormUsesMomentFieldsAndFallbacks() {
        let moment = InProgressMoment(
            id: "moment-1",
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

        let form = MomentSetupForm.continuing(
            moment: moment,
            templates: MomentTemplate.launchTemplates
        )

        XCTAssertEqual(form?.template.id, .birthdayMessage)
        XCTAssertEqual(form?.occasion, "Anniversary")
        XCTAssertEqual(form?.recipient, "")
        XCTAssertEqual(form?.tone, .cinematic)
        XCTAssertEqual(form?.tempo, .balanced)
        XCTAssertEqual(form?.details, "Use the beach clips.")
    }

    func testMediaRulesEnforceTemplateMinimumsAndMaximums() {
        XCTAssertFalse(MomentsMediaRules.canUseSelection(template: .birthdayMessage, selectedCount: 0))
        XCTAssertTrue(MomentsMediaRules.canUseSelection(template: .birthdayMessage, selectedCount: 1))
        XCTAssertTrue(MomentsMediaRules.canUseSelection(template: .birthdayMessage, selectedCount: 80))
        XCTAssertFalse(MomentsMediaRules.canUseSelection(template: .birthdayMessage, selectedCount: 81))

        XCTAssertFalse(MomentsMediaRules.canUseSelection(template: .partyRecap, selectedCount: 0))
        XCTAssertTrue(MomentsMediaRules.canUseSelection(template: .partyRecap, selectedCount: 1))
        XCTAssertTrue(MomentsMediaRules.canUseSelection(template: .partyRecap, selectedCount: 80))
        XCTAssertFalse(MomentsMediaRules.canUseSelection(template: .partyRecap, selectedCount: 81))
    }

    func testStoryRulesUseSelectedConvexMediaCount() {
        let assets = (0..<3).map {
            MomentMediaAsset(
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

        XCTAssertTrue(MomentsStoryRules.canPlan(mediaAssets: assets, template: .birthdayMessage))
        XCTAssertTrue(MomentsStoryRules.canPlan(mediaAssets: assets, template: .partyRecap))
    }

    func testStoryInputSignatureTracksMediaOrderAndDirection() {
        func storyMedia(id: String, sortOrder: Int) -> MomentsStoryMedia {
            MomentsStoryMedia(
                mediaAssetId: id,
                mediaKind: "image",
                sortOrder: sortOrder,
                selected: true,
                moderationStatus: "approved"
            )
        }

        var form = MomentSetupForm(template: .birthdayMessage)
        form.occasion = "Trip"
        form.details = "Use the desert photos."
        let media = [
            storyMedia(id: "media-a", sortOrder: 0),
            storyMedia(id: "media-b", sortOrder: 1)
        ]

        let baseSignature = MomentsStoryInputSignature.make(
            momentId: "moment-1",
            form: form,
            selectedMedia: media
        )
        let sameInputSignature = MomentsStoryInputSignature.make(
            momentId: "moment-1",
            form: form,
            selectedMedia: media.reversed()
        )

        XCTAssertEqual(baseSignature, sameInputSignature)

        let reorderedSignature = MomentsStoryInputSignature.make(
            momentId: "moment-1",
            form: form,
            selectedMedia: [
                storyMedia(id: "media-a", sortOrder: 1),
                storyMedia(id: "media-b", sortOrder: 0)
            ]
        )
        XCTAssertNotEqual(baseSignature, reorderedSignature)

        form.details = "Use the desert photos and end on the group shot."
        let changedDirectionSignature = MomentsStoryInputSignature.make(
            momentId: "moment-1",
            form: form,
            selectedMedia: media
        )
        XCTAssertNotEqual(baseSignature, changedDirectionSignature)
    }

    func testFinalRenderRulesRequireReadyStatusAndCredits() {
        let balance = MomentsCreditBalance(proMonthly: 0, promotional: 0, purchased: 2)
        let moment = InProgressMoment(
            id: "moment-1",
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
            MomentsFinalRenderRules.canGenerate(
                moment: moment,
                template: .birthdayMessage,
                balance: balance
            )
        )
        XCTAssertFalse(
            MomentsFinalRenderRules.canGenerate(
                moment: moment,
                template: .birthdayMessage,
                balance: .empty
            )
        )
        XCTAssertTrue(MomentsFinalRenderRules.canPreparePlan(moment: moment))
        XCTAssertTrue(
            MomentsFinalRenderRules.canGenerate(
                moment: moment,
                template: .birthdayMessage,
                balance: balance
            )
        )

        let staleStoryMoment = InProgressMoment(
            id: moment.id,
            template: moment.template,
            status: "in_progress",
            title: moment.title,
            tone: moment.tone,
            tempo: moment.tempo,
            occasion: moment.occasion,
            details: moment.details,
            durationSeconds: moment.durationSeconds,
            creditCost: moment.creditCost,
            updatedAt: moment.updatedAt
        )
        XCTAssertFalse(MomentsFinalRenderRules.canPreparePlan(moment: staleStoryMoment))
        XCTAssertTrue(MomentsFinalRenderRules.canPreparePlan(moment: staleStoryMoment, storySceneCount: 1))
        XCTAssertTrue(
            MomentsFinalRenderRules.canGenerate(
                moment: staleStoryMoment,
                template: .birthdayMessage,
                balance: balance,
                storySceneCount: 1
            )
        )
    }

    private func purchaseCatalogEntry(productId: String) -> MomentsPurchaseCatalog.Entry {
        MomentsPurchaseCatalog.Entry(
            productId: productId,
            packageIdentifier: productId,
            localizedTitle: productId,
            localizedPrice: "$1.00"
        )
    }
}
