import Foundation
import PhotosUI
import SwiftUI

extension MomentsCreateViewModel {
    @discardableResult
    func beginNewMoment(openMediaPicker: Bool = false, openAlbumPicker: Bool = false) -> Bool {
        guard canBeginNewMoment else {
            updateSetupErrorMessage(setupAvailabilityMessage ?? L10n.string("create.error.startWhenReady"))
            return false
        }
        prepareNewMomentCreation()
        isLocalMomentStarted = true
        pendingFocus = .media
        if openMediaPicker {
            mediaPickerOpenRequest += 1
        } else if openAlbumPicker {
            albumPickerOpenRequest += 1
        }
        return true
    }

    func requestMediaPickerOpen() {
        mediaPickerOpenRequest += 1
    }

    func requestAlbumPickerOpen() {
        albumPickerOpenRequest += 1
    }

    func discardMoment() {
        guard !isBusy else {
            updateSetupErrorMessage(L10n.string("create.error.waitBeforeDiscard"))
            return
        }
        guard effectiveLatestFinalJob?.isActiveRender != true else {
            updateSetupErrorMessage(L10n.string("create.error.waitBeforeDiscard"))
            return
        }
        guard hasMomentWorkspace || hasRecoverableMomentContext else {
            updateSetupErrorMessage(L10n.string("create.error.noActiveMoment"))
            return
        }
        if hasLocalMomentWorkspace {
            resetActiveMoment(force: true)
            return
        }
        guard let momentCreationWorkflow else {
            resetActiveMoment(force: true)
            return
        }

        runOperation {
            let discarded = await momentCreationWorkflow.discardActiveMoment(momentId: self.activeMomentId)
            if discarded {
                self.resetActiveMoment(force: true)
            } else if let message = momentCreationWorkflow.errorMessage {
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
                momentId: self.activeMomentId
            )
        }
    }

    func importLatestPhotos() {
        guard canAddMedia, let mediaUploadWorkflow else {
            updateSetupErrorMessage(mediaAvailabilityMessage ?? L10n.string("create.error.mediaUnavailable"))
            return
        }
        let template = form.template
        markPreparedStoryMediaEdited()

        runOperation {
            await mediaUploadWorkflow.importLatestPhotos(
                template: template,
                momentId: self.activeMomentId
            )
        }
    }

    func importPhotoAlbum(id albumId: String) {
        guard canAddMedia, let mediaUploadWorkflow else {
            updateSetupErrorMessage(mediaAvailabilityMessage ?? L10n.string("create.error.mediaUnavailable"))
            return
        }
        let template = form.template
        markPreparedStoryMediaEdited()

        runOperation {
            await mediaUploadWorkflow.importPhotoAlbum(
                id: albumId,
                template: template,
                momentId: self.activeMomentId
            )
        }
    }

    func removeMedia(_ media: MomentsSelectedMedia) {
        markPreparedStoryMediaEdited()
        mediaUploadWorkflow?.remove(media)
    }

    func moveMedia(_ media: MomentsSelectedMedia, before target: MomentsSelectedMedia) {
        markPreparedStoryMediaEdited()
        mediaUploadWorkflow?.move(media, before: target)
    }

    func reorderMedia(_ media: [MomentsSelectedMedia]) {
        markPreparedStoryMediaEdited()
        mediaUploadWorkflow?.reorder(media)
    }

    func autoPickStrongMoments() {
        markPreparedStoryMediaEdited()
        mediaUploadWorkflow?.autoPickStrongMoments()
    }

    func restoreLocalMediaForEditing() {
        mediaUploadWorkflow?.restoreLocalMediaForEditing()
    }

    func generateStory() {
        guard canPlanStory, let storyWorkflow else {
            updateStoryStatusMessage(storyAvailabilityMessage ?? L10n.string("create.error.storyPreparationNotReady"))
            return
        }
        let form = form
        let selectedMedia = selectedMedia
        isPreparingStory = true

        runOperation {
            defer { self.isPreparingStory = false }
            let momentId: String?
            if let activeMomentId = self.activeMomentId {
                momentId = activeMomentId
            } else if let momentCreationWorkflow = self.momentCreationWorkflow {
                momentId = await momentCreationWorkflow.createMoment(form: form)
                if momentId != nil {
                    self.isLocalMomentStarted = false
                }
            } else {
                momentId = nil
            }

            guard let momentId else {
                self.updateStoryStatusMessage(self.momentCreationFailureMessage())
                return
            }
            if self.storySummary.hasScenes,
               self.lastPreparedStoryInputSignature == self.preparedStoryComparisonInputSignature(momentId: momentId) {
                self.updateStoryStatusMessage(L10n.string("create.story.status.alreadyReady"))
                return
            }

            let persistedMedia = await self.mediaUploadWorkflow?.persistSelectedMedia(momentId: momentId)
            guard persistedMedia != nil || selectedMedia.isEmpty else {
                self.updateStoryStatusMessage(self.mediaStatusMessage
                    ?? MomentsRecoveryCopy.mediaStorySaveFailure()
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
                self.failFinalVideoCommand(self.momentCreationFailureMessage())
                return
            }

            guard await self.persistSetupEditsIfNeeded(momentId: momentId, form: form) else {
                self.failFinalVideoCommand(self.momentCreationFailureMessage())
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
                    self.failFinalVideoCommand(self.mediaStatusMessage ?? MomentsRecoveryCopy.mediaVideoSaveFailure())
                    return
                }
            }

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
                    ?? storyAvailabilityMessage
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

    private func resolveMomentIdForPreparation(form: MomentSetupForm) async -> String? {
        if let activeMomentId {
            return activeMomentId
        }
        guard let momentCreationWorkflow else {
            return nil
        }
        let momentId = await momentCreationWorkflow.createMoment(form: form)
        if momentId != nil {
            isLocalMomentStarted = false
        }
        return momentId
    }

    private func persistSetupEditsIfNeeded(momentId: String, form: MomentSetupForm) async -> Bool {
        guard hasPendingLocalSetupEdits else { return true }
        guard let momentCreationWorkflow else { return false }
        return await momentCreationWorkflow.updateMomentSetup(momentId: momentId, form: form)
    }

    private func prepareStoryIfNeeded(
        momentId: String,
        form: MomentSetupForm,
        selectedMedia: [MomentsSelectedMedia],
        storyWorkflow: StoryWorkflow
    ) async -> Bool {
        var inputSignature = preparedStoryComparisonInputSignature(momentId: momentId)
        if storySummary.hasScenes, lastPreparedStoryInputSignature == inputSignature {
            updateStoryStatusMessage(L10n.string("create.story.status.alreadyReady"))
            return true
        }

        let persistedMedia = await mediaUploadWorkflow?.persistSelectedMedia(momentId: momentId)
        guard persistedMedia != nil || selectedMedia.isEmpty else {
            updateStoryStatusMessage(mediaStatusMessage ?? MomentsRecoveryCopy.mediaStorySaveFailure())
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

        guard storySummary.hasScenes, lastPreparedStoryInputSignature == inputSignature else {
            updateStoryStatusMessage(L10n.string("create.error.storyPreparationUnfinished"))
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

    private var activeTemplateContext: (momentId: String, template: MomentTemplate)? {
        guard let activeMomentId else { return nil }
        return (activeMomentId, form.template)
    }

    private var activeFormContext: (momentId: String, form: MomentSetupForm)? {
        guard let activeMomentId else { return nil }
        return (activeMomentId, form)
    }

    private func momentCreationFailureMessage() -> String {
        momentCreationWorkflow?.errorMessage
            ?? setupErrorMessage
            ?? MomentsRecoveryCopy.storyStartFailure()
    }
}
