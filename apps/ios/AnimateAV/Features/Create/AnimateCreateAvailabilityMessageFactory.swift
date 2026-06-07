import Foundation

enum AnimateCreateAvailabilityMessageFactory {
    static func setup(
        isSetupLocked: Bool,
        isSignedIn: Bool,
        isVideoCreationConfigured: Bool,
        setupFormAvailability: AnimateVideoSetupRules.Availability
    ) -> String? {
        if isSetupLocked { return nil }
        if !isSignedIn { return AnimateCreateAvailabilityCopy.momentSignInRequired }
        if !isVideoCreationConfigured { return AnimateCreateAvailabilityCopy.momentSyncNotConfigured }
        return AnimateVideoSetupRules.availabilityMessage(setupFormAvailability)
    }

    static func media(
        hasAnimateWorkspace: Bool,
        isImportingMedia: Bool,
        isMediaUploadConfigured: Bool,
        mediaRemainingSlots: Int
    ) -> String? {
        if !hasAnimateWorkspace { return AnimateCreateAvailabilityCopy.mediaMissingMoment }
        if isImportingMedia { return nil }
        if !isMediaUploadConfigured { return AnimateCreateAvailabilityCopy.mediaUploadNotConfigured }
        if mediaRemainingSlots == 0 { return AnimateCreateAvailabilityCopy.mediaTemplateFull }
        return nil
    }

    static func story(
        isSignedIn: Bool,
        hasAnimateWorkspace: Bool,
        isStoryPlanning: Bool,
        isStoryAvailable: Bool,
        isStoryConfigured: Bool,
        mediaAssets: [AnimateMediaAsset]?,
        selectedMediaCount: Int,
        template: AnimateVideoTemplate
    ) -> String? {
        guard isSignedIn else { return AnimateCreateAvailabilityCopy.storySignInRequired }
        guard hasAnimateWorkspace else { return AnimateCreateAvailabilityCopy.storyMissingMoment }
        guard isStoryAvailable else { return AnimateCreateAvailabilityCopy.storyUnavailable }
        if isStoryPlanning { return nil }
        if !isStoryConfigured { return AnimateCreateAvailabilityCopy.storyNotConfigured }

        if selectedMediaCount > 0 {
            let availability = AnimateMediaRules.availability(template: template, selectedCount: selectedMediaCount)
            guard !availability.canUseSelection else { return nil }
            return AnimateMediaRules.selectionMessage(
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

        return AnimateStoryRules.availabilityMessage(
            AnimateStoryRules.availability(
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
        moment: AnimateVideo?,
        template: AnimateVideoTemplate,
        balance: AnimateCreditBalance,
        creditBalanceLoadState: AnimateCreditBalanceLoadState = .loaded
    ) -> String? {
        guard activeMomentId != nil else { return AnimateCreateAvailabilityCopy.finalRenderMissingMoment }
        guard isFinalRenderAvailable else { return AnimateCreateAvailabilityCopy.finalRenderUnavailable }
        if isFinalRenderGenerating { return nil }
        if !isFinalRenderConfigured { return AnimateCreateAvailabilityCopy.finalRenderNotConfigured }
        let availability = AnimateFinalRenderRules.availability(
            moment: moment,
            template: template,
            balance: balance
        )
        if availability.blockReason == .insufficientCredits, !creditBalanceLoadState.hasLoadedBalance {
            return AnimateCreateAvailabilityCopy.finalRenderCreditBalanceUnavailable(creditBalanceLoadState)
        }
        return AnimateFinalRenderRules.availabilityMessage(
            availability,
            missingMomentMessage: AnimateCreateAvailabilityCopy.finalRenderMissingWorkspace,
            insufficientCreditsMessage: AnimateCreateAvailabilityCopy.finalRenderInsufficientCredits(
                missingCredits: missingCredits(template: template, balance: balance)
            )
        )
    }

    private static func missingCredits(template: AnimateVideoTemplate, balance: AnimateCreditBalance) -> Int {
        max(template.creditCost - balance.spendable, 0)
    }
}
