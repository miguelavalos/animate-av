import Foundation

enum MomentsCreateAvailabilityMessageFactory {
    static func setup(
        isSetupLocked: Bool,
        isSignedIn: Bool,
        isMomentCreationConfigured: Bool,
        setupFormAvailability: MomentSetupRules.Availability
    ) -> String? {
        if isSetupLocked { return nil }
        if !isSignedIn { return MomentsCreateAvailabilityCopy.momentSignInRequired }
        if !isMomentCreationConfigured { return MomentsCreateAvailabilityCopy.momentSyncNotConfigured }
        return MomentSetupRules.availabilityMessage(setupFormAvailability)
    }

    static func media(
        hasMomentWorkspace: Bool,
        isImportingMedia: Bool,
        isMediaUploadConfigured: Bool,
        mediaRemainingSlots: Int
    ) -> String? {
        if !hasMomentWorkspace { return MomentsCreateAvailabilityCopy.mediaMissingMoment }
        if isImportingMedia { return nil }
        if !isMediaUploadConfigured { return MomentsCreateAvailabilityCopy.mediaUploadNotConfigured }
        if mediaRemainingSlots == 0 { return MomentsCreateAvailabilityCopy.mediaTemplateFull }
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
        guard isSignedIn else { return MomentsCreateAvailabilityCopy.storySignInRequired }
        guard hasMomentWorkspace else { return MomentsCreateAvailabilityCopy.storyMissingMoment }
        guard isStoryAvailable else { return MomentsCreateAvailabilityCopy.storyUnavailable }
        if isStoryPlanning { return nil }
        if !isStoryConfigured { return MomentsCreateAvailabilityCopy.storyNotConfigured }

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
            missingMediaMessage: MomentsCreateAvailabilityCopy.storyMissingMedia
        )
    }

    static func finalRender(
        activeMomentId: String?,
        isFinalRenderAvailable: Bool,
        isFinalRenderGenerating: Bool,
        isFinalRenderConfigured: Bool,
        moment: InProgressMoment?,
        template: MomentTemplate,
        balance: MomentsCreditBalance,
        creditBalanceLoadState: MomentsCreditBalanceLoadState = .loaded
    ) -> String? {
        guard activeMomentId != nil else { return MomentsCreateAvailabilityCopy.finalRenderMissingMoment }
        guard isFinalRenderAvailable else { return MomentsCreateAvailabilityCopy.finalRenderUnavailable }
        if isFinalRenderGenerating { return nil }
        if !isFinalRenderConfigured { return MomentsCreateAvailabilityCopy.finalRenderNotConfigured }
        let availability = MomentsFinalRenderRules.availability(
            moment: moment,
            template: template,
            balance: balance
        )
        if availability.blockReason == .insufficientCredits, !creditBalanceLoadState.hasLoadedBalance {
            return MomentsCreateAvailabilityCopy.finalRenderCreditBalanceUnavailable(creditBalanceLoadState)
        }
        return MomentsFinalRenderRules.availabilityMessage(
            availability,
            missingMomentMessage: MomentsCreateAvailabilityCopy.finalRenderMissingWorkspace,
            insufficientCreditsMessage: MomentsCreateAvailabilityCopy.finalRenderInsufficientCredits(
                missingCredits: missingCredits(template: template, balance: balance)
            )
        )
    }

    private static func missingCredits(template: MomentTemplate, balance: MomentsCreditBalance) -> Int {
        max(template.creditCost - balance.spendable, 0)
    }
}
