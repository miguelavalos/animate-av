extension AnimateCreateViewModel {
    var workspaceSummary: AnimateCreateWorkspaceSummary {
        AnimateCreateWorkspaceSummary.make(
            workspace: effectiveActiveWorkspace,
            finalExport: effectiveFinalExport
        )
    }

    var mediaSummary: AnimateCreateMediaSummary {
        AnimateCreateMediaSummary(
            selectedMedia: effectiveSelectedMedia,
            syncedMediaAssets: effectiveActiveWorkspace?.mediaAssets ?? [],
            isImporting: isImportingMedia,
            importProgress: mediaImportProgress,
            statusMessage: mediaStatusMessage
        )
    }

    var storySummary: AnimateCreateStorySummary {
        AnimateCreateStorySummary(
            savedScenes: effectiveSavedScenes,
            generatedScenes: generatedScenes,
            isPlanning: isPlanningStory,
            statusMessage: storyStatusMessage
        )
    }

    var finalRenderSummary: AnimateCreateFinalRenderSummary {
        AnimateCreateFinalRenderSummary(
            creditCost: form.template.creditCost,
            renderPlan: currentRenderPlan,
            videoQuote: videoQuote,
            finalExport: effectiveFinalExport,
            pendingGalleryVideo: pendingGalleryVideo,
            canRetryFinalVideoDownload: canRetryFinalVideoDownload,
            latestFinalJob: effectiveLatestFinalJob,
            isGenerating: isGeneratingFinalRender,
            statusMessage: effectiveLatestFinalJob?.userMessage
                ?? finalVideoCommandState.message
                ?? finalRenderStatusMessage
        )
    }

    var mediaSelectedCount: Int {
        mediaSummary.effectiveMediaCount
    }

    var mediaRemainingSlots: Int {
        mediaSummary.remainingSlots(template: form.template)
    }
}
