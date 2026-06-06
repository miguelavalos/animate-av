extension MomentsCreateViewModel {
    var setupAvailabilityMessage: String? {
        MomentsCreateAvailabilityMessageFactory.setup(
            isSetupLocked: isSetupLocked,
            isSignedIn: isSignedIn,
            isMomentCreationConfigured: momentCreationWorkflow?.isConfigured ?? false,
            setupFormAvailability: setupFormAvailability
        )
    }

    var mediaAvailabilityMessage: String? {
        MomentsCreateAvailabilityMessageFactory.media(
            hasMomentWorkspace: hasMomentWorkspace,
            isImportingMedia: isImportingMedia,
            isMediaUploadConfigured: mediaUploadWorkflow?.isConfigured ?? false,
            mediaRemainingSlots: mediaRemainingSlots
        )
    }

    var storyAvailabilityMessage: String? {
        MomentsCreateAvailabilityMessageFactory.story(
            isSignedIn: isSignedIn,
            hasMomentWorkspace: hasMomentWorkspace,
            isStoryPlanning: storyWorkflow?.isPlanning ?? false,
            isStoryAvailable: storyWorkflow != nil,
            isStoryConfigured: storyWorkflow?.isConfigured ?? false,
            mediaAssets: effectiveActiveWorkspace?.mediaAssets,
            selectedMediaCount: mediaSelectedCount,
            template: form.template
        )
    }

    var finalRenderAvailabilityMessage: String? {
        MomentsCreateAvailabilityMessageFactory.finalRender(
            activeMomentId: activeMomentId,
            isFinalRenderAvailable: finalRenderWorkflow != nil,
            isFinalRenderGenerating: finalRenderWorkflow?.isGenerating ?? false,
            isFinalRenderConfigured: finalRenderWorkflow?.isConfigured ?? false,
            moment: activeMoment,
            template: form.template,
            balance: balance,
            creditBalanceLoadState: creditBalanceLoadState
        )
    }

    var setupFormAvailability: MomentSetupRules.Availability {
        MomentSetupRules.availability(form: form, balance: balance)
    }

}
