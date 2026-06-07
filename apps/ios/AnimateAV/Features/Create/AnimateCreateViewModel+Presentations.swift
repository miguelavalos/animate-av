extension AnimateCreateViewModel {
    var workflowPresentation: AnimateCreateWorkflowPresentation {
        AnimateCreateWorkflowPresentation.make(
            activeMomentId: activeMomentId,
            isSignedIn: isSignedIn,
            isCreatingVideo: isCreatingVideo,
            hasAnimateWorkspace: hasAnimateWorkspace,
            hasUnsavedLocalMoment: hasLocalAnimateWorkspace,
            template: form.template,
            creationStyleTitle: selectedCreationStyle.title,
            toneTitle: form.tone.title,
            tempoTitle: form.tempo.title,
            occasionTitle: form.title,
            balance: balance,
            creditBalanceLoadState: creditBalanceLoadState,
            mediaSummary: mediaSummary,
            storySummary: storySummary,
            finalRenderSummary: finalRenderSummary,
            availability: workflowAvailability
        )
    }

    var workflowAvailability: AnimateCreateWorkflowAvailability {
        AnimateCreateWorkflowAvailability.make(
            canAddMedia: canAddMedia,
            canPlanStory: canPlanStory,
            canPrepareFinalRenderPlan: canPrepareFinalRenderPlan,
            canGenerateFinalRender: canGenerateFinalRender,
            canRefreshFinalRenderStatus: canRefreshFinalRenderStatus,
            mediaMessage: mediaAvailabilityMessage,
            storyMessage: storyAvailabilityMessage,
            finalRenderMessage: finalRenderAvailabilityMessage
        )
    }

}
