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
        hasActiveVideoWorkspace: Bool,
        isImportingMedia: Bool,
        isMediaUploadConfigured: Bool,
        mediaRemainingSlots: Int
    ) -> String? {
        if !hasActiveVideoWorkspace { return AnimateCreateAvailabilityCopy.mediaMissingVideo }
        if isImportingMedia { return nil }
        if !isMediaUploadConfigured { return AnimateCreateAvailabilityCopy.mediaUploadNotConfigured }
        if mediaRemainingSlots == 0 { return AnimateCreateAvailabilityCopy.mediaTemplateFull }
        return nil
    }

    static func story(
        isSignedIn: Bool,
        hasActiveVideoWorkspace: Bool,
        isStoryPlanning: Bool,
        isStoryAvailable: Bool,
        isStoryConfigured: Bool,
        mediaAssets: [AnimateMediaAsset]?,
        selectedMediaCount: Int,
        template: AnimateVideoTemplate
    ) -> String? {
        guard isSignedIn else { return AnimateCreateAvailabilityCopy.storySignInRequired }
        guard hasActiveVideoWorkspace else { return AnimateCreateAvailabilityCopy.videoDirectionMissingVideo }
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

        return AnimateVideoDirectionRules.availabilityMessage(
            AnimateVideoDirectionRules.availability(
                mediaAssets: mediaAssets,
                template: template
            ),
            missingMediaMessage: AnimateCreateAvailabilityCopy.storyMissingMedia
        )
    }

    static func finalRender(
        activeVideoId: String?,
        isFinalRenderAvailable: Bool,
        isFinalRenderGenerating: Bool,
        isFinalRenderConfigured: Bool,
        video: AnimateVideo?,
        template: AnimateVideoTemplate,
        balance: AnimateCreditBalance,
        creditBalanceLoadState: AnimateCreditBalanceLoadState = .loaded
    ) -> String? {
        guard activeVideoId != nil else { return AnimateCreateAvailabilityCopy.finalRenderMissingVideo }
        guard isFinalRenderAvailable else { return AnimateCreateAvailabilityCopy.finalRenderUnavailable }
        if isFinalRenderGenerating { return nil }
        if !isFinalRenderConfigured { return AnimateCreateAvailabilityCopy.finalRenderNotConfigured }
        let availability = AnimateFinalRenderRules.availability(
            video: video,
            template: template,
            balance: balance
        )
        if availability.blockReason == .insufficientCredits, !creditBalanceLoadState.hasLoadedBalance {
            return AnimateCreateAvailabilityCopy.finalRenderCreditBalanceUnavailable(creditBalanceLoadState)
        }
        return AnimateFinalRenderRules.availabilityMessage(
            availability,
            missingVideoMessage: AnimateCreateAvailabilityCopy.finalRenderMissingVideoWorkspace,
            insufficientCreditsMessage: AnimateCreateAvailabilityCopy.finalRenderInsufficientCredits(
                missingCredits: missingCredits(template: template, balance: balance)
            )
        )
    }

    private static func missingCredits(template: AnimateVideoTemplate, balance: AnimateCreditBalance) -> Int {
        max(template.creditCost - balance.spendable, 0)
    }
}
