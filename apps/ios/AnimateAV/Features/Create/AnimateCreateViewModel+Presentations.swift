extension AnimateCreateViewModel {
    var workflowPresentation: AnimateCreateWorkflowPresentation {
        AnimateCreateWorkflowPresentation.make(
            activeVideoId: activeVideoId,
            isSignedIn: isSignedIn,
            isCreatingVideo: isCreatingVideo,
            hasAnimateWorkspace: hasAnimateWorkspace,
            hasUnsavedLocalVideo: hasLocalAnimateWorkspace,
            template: form.template,
            creationStyleTitle: selectedCreationStyle.title,
            toneTitle: form.tone.title,
            tempoTitle: form.tempo.title,
            occasionTitle: form.title,
            balance: balance,
            creditBalanceLoadState: creditBalanceLoadState,
            mediaSummary: mediaSummary,
            videoDirectionSummary: videoDirectionSummary,
            finalRenderSummary: finalRenderSummary,
            availability: workflowAvailability
        )
    }

    var workflowAvailability: AnimateCreateWorkflowAvailability {
        AnimateCreateWorkflowAvailability.make(
            canAddMedia: canAddMedia,
            canPrepareVideoDirection: canPrepareVideoDirection,
            canPrepareFinalRenderPlan: canPrepareFinalRenderPlan,
            canGenerateFinalRender: canGenerateFinalRender,
            canRefreshFinalRenderStatus: canRefreshFinalRenderStatus,
            mediaMessage: mediaAvailabilityMessage,
            videoDirectionMessage: videoDirectionAvailabilityMessage,
            finalRenderMessage: finalRenderAvailabilityMessage
        )
    }

}
