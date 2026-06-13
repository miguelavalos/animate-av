import UIKit

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

    var videoDirectionSummary: AnimateCreateVideoDirectionSummary {
        AnimateCreateVideoDirectionSummary(
            savedScenes: effectiveSavedScenes,
            generatedScenes: generatedScenes,
            isPlanning: isPreparingVideoDirection,
            statusMessage: videoDirectionStatusMessage
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
            isPreparingPlan: isPreparingFinalPlan,
            statusMessage: effectiveLatestFinalJob?.userMessage
                ?? finalVideoCommandState.message
                ?? finalRenderStatusMessage
        )
    }

    var mediaSelectedCount: Int {
        mediaSummary.effectiveMediaCount
    }

    var hasRenderableSelectedPhoto: Bool {
        effectiveSelectedMedia.contains { media in
            (media.kind == "photo" || media.kind == "image")
                && UIImage(data: media.data) != nil
        }
    }

    var mediaRemainingSlots: Int {
        mediaSummary.remainingSlots(template: form.template)
    }
}
