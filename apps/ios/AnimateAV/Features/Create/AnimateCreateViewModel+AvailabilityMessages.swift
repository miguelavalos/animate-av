extension AnimateCreateViewModel {
    var setupAvailabilityMessage: String? {
        AnimateCreateAvailabilityMessageFactory.setup(
            isSetupLocked: isSetupLocked,
            isSignedIn: isSignedIn,
            isVideoCreationConfigured: videoCreationWorkflow?.isConfigured ?? false,
            setupFormAvailability: setupFormAvailability
        )
    }

    var mediaAvailabilityMessage: String? {
        AnimateCreateAvailabilityMessageFactory.media(
            hasAnimateWorkspace: hasAnimateWorkspace,
            isImportingMedia: isImportingMedia,
            isMediaUploadConfigured: mediaUploadWorkflow?.isConfigured ?? false,
            mediaRemainingSlots: mediaRemainingSlots
        )
    }

    var storyAvailabilityMessage: String? {
        AnimateCreateAvailabilityMessageFactory.story(
            isSignedIn: isSignedIn,
            hasAnimateWorkspace: hasAnimateWorkspace,
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

    var setupFormAvailability: AnimateVideoSetupRules.Availability {
        AnimateVideoSetupRules.availability(form: form, balance: balance)
    }

}
