extension AnimateCreateViewModel {
    var setupAvailabilityMessage: String? {
        AnimateCreateAvailabilityMessageFactory.setup(
            isSetupLocked: isSetupLocked,
            isSignedIn: isSignedIn,
            isMomentCreationConfigured: momentCreationWorkflow?.isConfigured ?? false,
            setupFormAvailability: setupFormAvailability
        )
    }

    var mediaAvailabilityMessage: String? {
        AnimateCreateAvailabilityMessageFactory.media(
            hasMomentWorkspace: hasMomentWorkspace,
            isImportingMedia: isImportingMedia,
            isMediaUploadConfigured: mediaUploadWorkflow?.isConfigured ?? false,
            mediaRemainingSlots: mediaRemainingSlots
        )
    }

    var storyAvailabilityMessage: String? {
        AnimateCreateAvailabilityMessageFactory.story(
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
        AnimateCreateAvailabilityMessageFactory.finalRender(
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
