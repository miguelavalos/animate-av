import Foundation
import PhotosUI
import SwiftUI

extension AnimateCreateViewModel {
    @discardableResult
    func beginNewVideoCreation(openMediaPicker: Bool = false) -> Bool {
        guard canBeginNewVideoCreation else {
            updateSetupErrorMessage(setupAvailabilityMessage ?? L10n.string("create.error.startWhenReady"))
            return false
        }
        prepareNewVideoCreation()
        isLocalVideoCreationStarted = true
        pendingFocus = .media
        if openMediaPicker {
            mediaPickerOpenRequest += 1
        }
        return true
    }

    func requestMediaPickerOpen() {
        mediaPickerOpenRequest += 1
    }

    func discardVideoCreation() {
        guard !isBusy else {
            updateSetupErrorMessage(L10n.string("create.error.waitBeforeDiscard"))
            return
        }
        guard effectiveLatestFinalJob?.isActiveRender != true else {
            updateSetupErrorMessage(L10n.string("create.error.waitBeforeDiscard"))
            return
        }
        guard hasActiveVideoWorkspace || hasRecoverableVideoContext else {
            updateSetupErrorMessage(L10n.string("create.error.noActiveMoment"))
            return
        }
        if hasLocalAnimateWorkspace {
            resetActiveVideoCreation(force: true)
            return
        }
        guard let videoCreationWorkflow else {
            resetActiveVideoCreation(force: true)
            return
        }

        runOperation {
            let discarded = await videoCreationWorkflow.discardActiveVideo(momentId: self.activeVideoId)
            if discarded {
                self.resetActiveVideoCreation(force: true)
            } else if let message = videoCreationWorkflow.errorMessage {
                self.updateSetupErrorMessage(message)
            } else {
                self.updateSetupErrorMessage(L10n.string("create.error.discardMoment"))
            }
        }
    }

    func importPickerItems(_ items: [PhotosPickerItem]) {
        guard canAddMedia, let mediaUploadWorkflow else {
            updateSetupErrorMessage(mediaAvailabilityMessage ?? L10n.string("create.error.mediaUnavailable"))
            return
        }
        let template = form.template
        markPreparedStoryMediaEdited()

        runOperation {
            await mediaUploadWorkflow.importPickerItems(
                items,
                template: template,
                momentId: self.activeVideoId
            )
        }
    }

    func removeMedia(_ media: AnimateSelectedMedia) {
        markPreparedStoryMediaEdited()
        mediaUploadWorkflow?.remove(media)
    }

    func restoreLocalMediaForEditing() {
        mediaUploadWorkflow?.restoreLocalMediaForEditing()
    }

    func generateStory() {
        guard canPrepareVideoDirection, let storyWorkflow else {
            updateVideoDirectionStatusMessage(videoDirectionAvailabilityMessage ?? L10n.string("create.error.storyPreparationNotReady"))
            return
        }
        let form = form
        let selectedMedia = selectedMedia
        isPreparingVideoDirectionAction = true

        runOperation {
            defer { self.isPreparingVideoDirectionAction = false }
            let momentId: String?
            if let activeVideoId = self.activeVideoId {
                momentId = activeVideoId
            } else if let videoCreationWorkflow = self.videoCreationWorkflow {
                momentId = await videoCreationWorkflow.createVideo(form: form)
                if momentId != nil {
                    self.isLocalVideoCreationStarted = false
                }
            } else {
                momentId = nil
            }

            guard let momentId else {
                self.updateVideoDirectionStatusMessage(self.videoCreationFailureMessage())
                return
            }
            if self.videoDirectionSummary.hasScenes,
               self.lastPreparedStoryInputSignature == self.preparedStoryComparisonInputSignature(momentId: momentId) {
                self.updateVideoDirectionStatusMessage(L10n.string("create.story.status.alreadyReady"))
                return
            }

            let persistedMedia = await self.mediaUploadWorkflow?.persistSelectedMedia(momentId: momentId)
            guard persistedMedia != nil || selectedMedia.isEmpty else {
                self.updateVideoDirectionStatusMessage(self.mediaStatusMessage
                    ?? AnimateRecoveryCopy.mediaStorySaveFailure()
                )
                return
            }
            let inputSignature = self.currentStoryInputSignature(
                momentId: momentId,
                persistedMedia: persistedMedia
            )

            let didPrepareStory = await storyWorkflow.generatePlan(
                momentId: momentId,
                form: form,
                selectedMedia: selectedMedia,
                persistedMedia: persistedMedia
            )
            if didPrepareStory {
                self.recordPreparedStoryInputSignature(inputSignature, momentId: momentId)
            }
        }
    }

    func prepareFinalVideoPlanFromCurrentSelection(removesWatermark: Bool = false) {
        guard let finalRenderWorkflow else {
            failFinalVideoCommand(L10n.string("create.error.videoCreationNotConfigured"))
            return
        }
        guard mediaSelectedCount > 0 else {
            failFinalVideoCommand(mediaAvailabilityMessage ?? L10n.string("create.error.mediaUnavailable"))
            return
        }
        guard !isFinalRenderEditingLocked else {
            failFinalVideoCommand(finalRenderAvailabilityMessage ?? L10n.string("create.error.videoCreationNotReady"))
            return
        }
        let form = effectiveFinalRenderForm()
        let creationStyleId = selectedCreationStyle.id
        beginFinalVideoCommand(.preparingPlan(L10n.string("workflow.final.checkingPlan")))
        updateFinalRenderStatusMessage(L10n.string("workflow.final.checkingPlan"))

        runOperation {
            let momentId = await self.resolveMomentIdForPreparation(form: form)

            guard let momentId else {
                self.failFinalVideoCommand(self.videoCreationFailureMessage())
                return
            }

            guard await self.persistSetupEditsIfNeeded(momentId: momentId, form: form) else {
                self.failFinalVideoCommand(self.videoCreationFailureMessage())
                return
            }

            let inputSignature = self.currentFinalRenderInputSignature(
                momentId: momentId,
                removesWatermark: removesWatermark
            )
            let currentRenderPlan = self.confirmableRenderPlan(momentId: momentId)
            let hasCurrentRenderPlan = currentRenderPlan != nil

            if !hasCurrentRenderPlan {
                self.clearStaleRenderPlan()
                self.beginFinalPlanPreparation(inputSignature: inputSignature)
                self.updateFinalRenderStatusMessage(L10n.string("workflow.final.checkingPlan"))
            } else if let currentRenderPlan {
                finalRenderWorkflow.usePreparedRenderPlan(currentRenderPlan)
                self.beginFinalVideoCommand(.idle)
            }
            defer {
                if !hasCurrentRenderPlan {
                    self.finishFinalPlanPreparation()
                }
            }

            if !hasCurrentRenderPlan {
                guard let mediaUploadWorkflow = self.mediaUploadWorkflow else {
                    self.failFinalVideoCommand(self.mediaAvailabilityMessage ?? L10n.string("create.error.mediaUnavailable"))
                    return
                }
                guard await mediaUploadWorkflow.persistSelectedMediaForFinalVideo(momentId: momentId) else {
                    self.failFinalVideoCommand(self.mediaStatusMessage ?? AnimateRecoveryCopy.mediaVideoSaveFailure())
                    return
                }
            }

            await finalRenderWorkflow.quoteVideo(
                form: form,
                removesWatermark: removesWatermark
            )
            await finalRenderWorkflow.prepareFinalRenderPlan(
                momentId: momentId,
                template: form.template,
                creationStyle: creationStyleId,
                form: form,
                selectedMedia: self.selectedMedia,
                removesWatermark: removesWatermark
            )
        }
    }

    func submitFinalVideoConfirmation(removesWatermark: Bool = false) {
        beginFinalVideoCommand(.validating(L10n.string("workflow.final.checkingPlan")))
        let currentRemovesWatermark = renderPlan?.watermark?.selectedRemoveWatermark ?? false
        let needsUpdatedPlan = removesWatermark != currentRemovesWatermark
            || renderPlan?.canCreateVideo != true
        if needsUpdatedPlan {
            prepareFinalVideoPlanFromCurrentSelection(removesWatermark: removesWatermark)
        } else {
            confirmFinalVideoFromCurrentSelection(removesWatermark: removesWatermark)
        }
    }

    func confirmFinalVideoFromCurrentSelection(removesWatermark: Bool = false) {
        guard let finalRenderWorkflow else {
            failFinalVideoCommand(L10n.string("create.error.videoCreationNotConfigured"))
            return
        }
        guard let context = activeTemplateContext else {
            failFinalVideoCommand(L10n.string("create.error.currentMomentMissing"))
            return
        }
        guard canGenerateFinalRender else {
            failFinalVideoCommand(
                finalRenderAvailabilityMessage
                    ?? videoDirectionAvailabilityMessage
                    ?? L10n.string("create.error.videoCreationNotReady")
            )
            return
        }

        let form = effectiveFinalRenderForm()
        beginFinalVideoCommand(.confirming(L10n.string("workflow.final.creatingVideo")))
        updateFinalRenderStatusMessage(L10n.string("workflow.final.creatingVideo"))

        runOperation {
            await finalRenderWorkflow.confirmPreparedFinalRender(
                momentId: context.momentId,
                template: context.template,
                creationStyle: self.selectedCreationStyle.id,
                form: form,
                selectedMedia: self.selectedMedia,
                removesWatermark: removesWatermark
            )
        }
    }

    private func resolveMomentIdForPreparation(form: AnimateVideoSetupForm) async -> String? {
        if let activeVideoId {
            return activeVideoId
        }
        guard let videoCreationWorkflow else {
            return nil
        }
        let momentId = await videoCreationWorkflow.createVideo(form: form)
        if momentId != nil {
            isLocalVideoCreationStarted = false
        }
        return momentId
    }

    private func persistSetupEditsIfNeeded(momentId: String, form: AnimateVideoSetupForm) async -> Bool {
        guard hasPendingLocalSetupEdits else { return true }
        guard let videoCreationWorkflow else { return false }
        return await videoCreationWorkflow.updateVideoSetup(momentId: momentId, form: form)
    }

    private func prepareStoryIfNeeded(
        momentId: String,
        form: AnimateVideoSetupForm,
        selectedMedia: [AnimateSelectedMedia],
        storyWorkflow: StoryWorkflow
    ) async -> Bool {
        var inputSignature = preparedStoryComparisonInputSignature(momentId: momentId)
        if videoDirectionSummary.hasScenes, lastPreparedStoryInputSignature == inputSignature {
            updateVideoDirectionStatusMessage(L10n.string("create.story.status.alreadyReady"))
            return true
        }

        let persistedMedia = await mediaUploadWorkflow?.persistSelectedMedia(momentId: momentId)
        guard persistedMedia != nil || selectedMedia.isEmpty else {
            updateVideoDirectionStatusMessage(mediaStatusMessage ?? AnimateRecoveryCopy.mediaStorySaveFailure())
            return false
        }
        inputSignature = currentStoryInputSignature(
            momentId: momentId,
            persistedMedia: persistedMedia
        )

        let didPrepareStory = await storyWorkflow.generatePlan(
            momentId: momentId,
            form: form,
            selectedMedia: selectedMedia,
            persistedMedia: persistedMedia
        )
        if didPrepareStory {
            recordPreparedStoryInputSignature(inputSignature, momentId: momentId)
        }

        guard videoDirectionSummary.hasScenes, lastPreparedStoryInputSignature == inputSignature else {
            updateVideoDirectionStatusMessage(L10n.string("create.error.storyPreparationUnfinished"))
            return false
        }
        return true
    }

    func retryFinalVideoDownload() {
        guard let finalRenderWorkflow else {
            updateFinalRenderStatusMessage(L10n.string("create.error.finalDownloadUnavailable"))
            return
        }

        finalRenderWorkflow.retryFinalVideoDownload()
    }

    @discardableResult
    func finishFinalVideoToGallery() -> Bool {
        guard let finalRenderWorkflow else {
            updateFinalRenderStatusMessage(L10n.string("create.error.galleryUnavailable"))
            return false
        }

        guard finalRenderWorkflow.finishFinalExportToGallery() else {
            beginFinalVideoCommand(.failed(finalRenderWorkflow.statusMessage ?? L10n.string("workflow.final.downloadBeforeGallery")))
            return false
        }

        beginFinalVideoCommand(.completedInGallery(L10n.string("workflow.final.movedToGallery")))
        return true
    }

    private var activeTemplateContext: (momentId: String, template: AnimateVideoTemplate)? {
        guard let activeVideoId else { return nil }
        return (activeVideoId, form.template)
    }

    private var activeFormContext: (momentId: String, form: AnimateVideoSetupForm)? {
        guard let activeVideoId else { return nil }
        return (activeVideoId, form)
    }

    private func videoCreationFailureMessage() -> String {
        videoCreationWorkflow?.errorMessage
            ?? setupErrorMessage
            ?? AnimateRecoveryCopy.storyStartFailure()
    }
}
