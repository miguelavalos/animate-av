import Foundation

enum AnimateCreateAvailabilityMessageFactory {
    static func setup(
        isSetupLocked: Bool,
        isSignedIn: Bool,
        isMomentCreationConfigured: Bool,
        setupFormAvailability: MomentSetupRules.Availability
    ) -> String? {
        if isSetupLocked { return nil }
        if !isSignedIn { return AnimateCreateAvailabilityCopy.momentSignInRequired }
        if !isMomentCreationConfigured { return AnimateCreateAvailabilityCopy.momentSyncNotConfigured }
        return MomentSetupRules.availabilityMessage(setupFormAvailability)
    }

    static func media(
        hasMomentWorkspace: Bool,
        isImportingMedia: Bool,
        isMediaUploadConfigured: Bool,
        mediaRemainingSlots: Int
    ) -> String? {
        if !hasMomentWorkspace { return AnimateCreateAvailabilityCopy.mediaMissingMoment }
        if isImportingMedia { return nil }
        if !isMediaUploadConfigured { return AnimateCreateAvailabilityCopy.mediaUploadNotConfigured }
        if mediaRemainingSlots == 0 { return AnimateCreateAvailabilityCopy.mediaTemplateFull }
        return nil
    }

    static func story(
        isSignedIn: Bool,
        hasMomentWorkspace: Bool,
        isStoryPlanning: Bool,
        isStoryAvailable: Bool,
        isStoryConfigured: Bool,
        mediaAssets: [MomentMediaAsset]?,
        selectedMediaCount: Int,
        template: MomentTemplate
    ) -> String? {
        guard isSignedIn else { return AnimateCreateAvailabilityCopy.storySignInRequired }
        guard hasMomentWorkspace else { return AnimateCreateAvailabilityCopy.storyMissingMoment }
        guard isStoryAvailable else { return AnimateCreateAvailabilityCopy.storyUnavailable }
        if isStoryPlanning { return nil }
        if !isStoryConfigured { return AnimateCreateAvailabilityCopy.storyNotConfigured }

        if selectedMediaCount > 0 {
            let availability = MomentsMediaRules.availability(template: template, selectedCount: selectedMediaCount)
            guard !availability.canUseSelection else { return nil }
            return MomentsMediaRules.selectionMessage(
                availability,
                tooFewMessage: { missingCount in
                    missingCount == 1
                        ? L10n.string("create.availability.media.addOne")
                        : L10n.string("create.availability.media.addMany", missingCount)
                },
                tooManyMessage: { extraCount in
                    extraCount == 1
                        ? L10n.string("create.availability.media.removeOne")
                        : L10n.string("create.availability.media.removeMany", extraCount)
                }
            )
        }

        return MomentsStoryRules.availabilityMessage(
            MomentsStoryRules.availability(
                mediaAssets: mediaAssets,
                template: template
            ),
            missingMediaMessage: AnimateCreateAvailabilityCopy.storyMissingMedia
        )
    }

    static func finalRender(
        activeMomentId: String?,
        isFinalRenderAvailable: Bool,
        isFinalRenderGenerating: Bool,
        isFinalRenderConfigured: Bool,
        moment: InProgressMoment?,
        template: MomentTemplate,
        balance: AnimateCreditBalance,
        creditBalanceLoadState: AnimateCreditBalanceLoadState = .loaded
    ) -> String? {
        guard activeMomentId != nil else { return AnimateCreateAvailabilityCopy.finalRenderMissingMoment }
        guard isFinalRenderAvailable else { return AnimateCreateAvailabilityCopy.finalRenderUnavailable }
        if isFinalRenderGenerating { return nil }
        if !isFinalRenderConfigured { return AnimateCreateAvailabilityCopy.finalRenderNotConfigured }
        let availability = MomentsFinalRenderRules.availability(
            moment: moment,
            template: template,
            balance: balance
        )
        if availability.blockReason == .insufficientCredits, !creditBalanceLoadState.hasLoadedBalance {
            return AnimateCreateAvailabilityCopy.finalRenderCreditBalanceUnavailable(creditBalanceLoadState)
        }
        return MomentsFinalRenderRules.availabilityMessage(
            availability,
            missingMomentMessage: AnimateCreateAvailabilityCopy.finalRenderMissingWorkspace,
            insufficientCreditsMessage: AnimateCreateAvailabilityCopy.finalRenderInsufficientCredits(
                missingCredits: missingCredits(template: template, balance: balance)
            )
        )
    }

    private static func missingCredits(template: MomentTemplate, balance: AnimateCreditBalance) -> Int {
        max(template.creditCost - balance.spendable, 0)
    }
}
