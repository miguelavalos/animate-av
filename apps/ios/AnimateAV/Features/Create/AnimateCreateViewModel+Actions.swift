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
            updateSetupErrorMessage(L10n.string("create.error.noActiveVideo"))
            return
        }
        cancelOperations()
        invalidateFinalPlanPreparation()
        if hasLocalAnimateWorkspace {
            resetActiveVideoCreation(force: true)
            return
        }
        guard let videoCreationWorkflow else {
            resetActiveVideoCreation(force: true)
            return
        }

        runOperation {
            let discarded = await videoCreationWorkflow.discardActiveVideo(videoId: self.activeVideoId)
            if discarded {
                self.resetActiveVideoCreation(force: true)
            } else if let message = videoCreationWorkflow.errorMessage {
                self.updateSetupErrorMessage(message)
            } else {
                self.updateSetupErrorMessage(L10n.string("create.error.discardVideo"))
            }
        }
    }

    func cancelLocalVideoCreationDraft() {
        resetActiveVideoCreation(force: true)
        _ = beginNewVideoCreation(openMediaPicker: false)
    }

    func importPickerItems(_ items: [PhotosPickerItem]) {
        guard canAddMedia, let mediaUploadWorkflow else {
            updateSetupErrorMessage(mediaAvailabilityMessage ?? L10n.string("create.error.mediaUnavailable"))
            return
        }
        let template = form.template
        markPreparedVideoDirectionMediaEdited()

        runOperation {
            await mediaUploadWorkflow.importPickerItems(
                items,
                template: template,
                videoId: self.activeVideoId
            )
        }
    }

    func replaceMedia(_ media: AnimateSelectedMedia, withPickerItems items: [PhotosPickerItem]) {
        guard !isFinalRenderEditingLocked, let mediaUploadWorkflow else {
            updateSetupErrorMessage(mediaAvailabilityMessage ?? L10n.string("create.error.mediaUnavailable"))
            return
        }
        markPreparedVideoDirectionMediaEdited()

        runOperation {
            await mediaUploadWorkflow.replace(media, withPickerItems: items)
        }
    }

    func removeMedia(_ media: AnimateSelectedMedia) {
        markPreparedVideoDirectionMediaEdited()
        mediaUploadWorkflow?.remove(media)
    }

    func updateMedia(_ media: AnimateSelectedMedia, withPhotoData data: Data) {
        markPreparedVideoDirectionMediaEdited()
        mediaUploadWorkflow?.update(media, withPhotoData: data)
    }

    func restoreOriginalMedia(_ media: AnimateSelectedMedia) {
        markPreparedVideoDirectionMediaEdited()
        mediaUploadWorkflow?.restoreOriginalPhotoData(media)
    }

    func restoreLocalMediaForEditing() {
        mediaUploadWorkflow?.restoreLocalMediaForEditing()
    }

    func prepareVideoDirection() {
        guard canPrepareVideoDirection, let videoDirectionWorkflow else {
            failVideoDirectionPreparation(videoDirectionAvailabilityMessage ?? L10n.string("create.error.storyPreparationNotReady"))
            return
        }
        let form = form
        let selectedMedia = selectedMedia
        updateSetupErrorMessage(nil)
        updateVideoDirectionStatusMessage(nil)
        isPreparingVideoDirectionAction = true

        runOperation {
            defer { self.isPreparingVideoDirectionAction = false }
            let videoId: String?
            if let activeVideoId = self.activeVideoId {
                videoId = activeVideoId
            } else if let videoCreationWorkflow = self.videoCreationWorkflow {
                videoId = await videoCreationWorkflow.createVideo(form: form)
                if videoId != nil {
                    self.isLocalVideoCreationStarted = false
                }
            } else {
                videoId = nil
            }

            guard let videoId else {
                self.failVideoDirectionPreparation(self.videoCreationFailureMessage())
                return
            }
            if self.videoDirectionSummary.hasScenes,
               self.lastPreparedVideoDirectionInputSignature == self.preparedVideoDirectionComparisonInputSignature(videoId: videoId) {
                self.updateVideoDirectionStatusMessage(L10n.string("create.story.status.alreadyReady"))
                return
            }

            let persistedMedia = await self.mediaUploadWorkflow?.persistSelectedMedia(videoId: videoId)
            guard persistedMedia != nil || selectedMedia.isEmpty else {
                self.failVideoDirectionPreparation(self.mediaStatusMessage
                    ?? AnimateRecoveryCopy.mediaStorySaveFailure()
                )
                return
            }
            let inputSignature = self.currentVideoDirectionInputSignature(
                videoId: videoId,
                persistedMedia: persistedMedia
            )

            let didPrepareVideoDirection = await videoDirectionWorkflow.generatePlan(
                videoId: videoId,
                form: form,
                selectedMedia: selectedMedia,
                persistedMedia: persistedMedia
            )
            if didPrepareVideoDirection {
                let generatedScenes = videoDirectionWorkflow.generatedPlan?.scenes ?? []
                if !generatedScenes.isEmpty {
                    self.applyVideoDirectionState(
                        AnimateCreateVideoDirectionState(
                            activeWorkspace: self.activeWorkspace,
                            savedScenes: self.savedScenes,
                            generatedScenes: generatedScenes,
                            statusMessage: nil,
                            isPlanning: videoDirectionWorkflow.isPlanning
                        )
                    )
                }
                self.recordPreparedVideoDirectionInputSignature(inputSignature, videoId: videoId)
                if !generatedScenes.isEmpty {
                    self.lastPreparedVideoDirectionInputSignature = inputSignature
                }
            }
            guard didPrepareVideoDirection else {
                self.failVideoDirectionPreparation(AnimateRecoveryCopy.storyFailure())
                return
            }
            guard (self.videoDirectionSummary.hasScenes || videoDirectionWorkflow.generatedPlan?.scenes.isEmpty == false),
                  self.lastPreparedVideoDirectionInputSignature == inputSignature else {
                self.failVideoDirectionPreparation(L10n.string("create.error.storyPreparationUnfinished"))
                return
            }
        }
    }

    func prepareFinalVideoPlanFromCurrentSelection(
        removesWatermark: Bool = false,
        confirmsAfterPreparation: Bool = false
    ) {
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
            let videoId = await self.resolveVideoIdForPreparation(form: form)
            guard !Task.isCancelled else { return }

            guard let videoId else {
                self.failFinalVideoCommand(self.videoCreationFailureMessage())
                return
            }

            guard await self.persistSetupEditsIfNeeded(videoId: videoId, form: form) else {
                guard !Task.isCancelled else { return }
                self.failFinalVideoCommand(self.videoCreationFailureMessage())
                return
            }
            guard !Task.isCancelled else { return }

            let inputSignature = self.currentFinalRenderInputSignature(
                videoId: videoId,
                removesWatermark: removesWatermark
            )
            let currentRenderPlan = self.confirmableRenderPlan(videoId: videoId)
            let hasCurrentRenderPlan = currentRenderPlan != nil
            var finalPlanGeneration: Int?

            if !hasCurrentRenderPlan {
                self.clearStaleRenderPlan()
                finalPlanGeneration = self.beginFinalPlanPreparation(inputSignature: inputSignature)
                self.updateFinalRenderStatusMessage(L10n.string("workflow.final.checkingPlan"))
            } else if let currentRenderPlan {
                finalRenderWorkflow.usePreparedRenderPlan(currentRenderPlan)
                self.beginFinalVideoCommand(.idle)
            }
            defer {
                if !hasCurrentRenderPlan {
                    self.finishFinalPlanPreparation(generation: finalPlanGeneration)
                }
            }

            let selectedMedia = self.effectiveSelectedMedia
            await finalRenderWorkflow.prepareFinalRenderPlan(
                videoId: videoId,
                template: form.template,
                creationStyle: creationStyleId,
                form: form,
                selectedMedia: selectedMedia,
                removesWatermark: removesWatermark
            )
            if let finalPlanGeneration {
                guard self.isCurrentFinalPlanPreparation(finalPlanGeneration) else { return }
            } else {
                guard !Task.isCancelled else { return }
            }
            guard finalRenderWorkflow.renderPlan != nil else {
                self.failFinalVideoCommand(
                    finalRenderWorkflow.statusMessage
                        ?? L10n.string("create.error.videoCreationNotReady")
                )
                return
            }

            guard confirmsAfterPreparation else {
                return
            }
            guard finalRenderWorkflow.renderPlan?.canCreateVideo == true else {
                self.failFinalVideoCommand(
                    finalRenderWorkflow.statusMessage
                        ?? L10n.string("create.error.videoCreationNotReady")
                )
                return
            }

            self.beginFinalVideoCommand(.confirming(L10n.string("workflow.final.creatingVideo")))
            self.updateFinalRenderStatusMessage(L10n.string("workflow.final.creatingVideo"))
            let didStartFinalRender = await finalRenderWorkflow.confirmPreparedFinalRender(
                videoId: videoId,
                template: form.template,
                creationStyle: creationStyleId,
                form: form,
                selectedMedia: selectedMedia,
                removesWatermark: removesWatermark
            )
            if didStartFinalRender {
                if let pendingGalleryVideo = finalRenderWorkflow.pendingGalleryVideo {
                    self.acceptPendingGalleryVideo(pendingGalleryVideo)
                    self.beginFinalVideoCommand(.completedDownloadReady(
                        finalRenderWorkflow.statusMessage ?? L10n.string("workflow.final.savedLocal")
                    ))
                    self.updateFinalRenderStatusMessage(
                        finalRenderWorkflow.statusMessage ?? L10n.string("workflow.final.savedLocal")
                    )
                    return
                }
                self.beginFinalVideoCommand(.queued(L10n.string("workflow.final.creatingVideo")))
                self.updateFinalRenderStatusMessage(L10n.string("workflow.final.creatingVideo"))
                return
            }
            guard finalRenderWorkflow.latestFinalJob != nil
                    || finalRenderWorkflow.finalExport != nil
                    || finalRenderWorkflow.pendingGalleryVideo != nil
                    || finalRenderWorkflow.isGenerating else {
                self.failFinalVideoCommand(
                    finalRenderWorkflow.statusMessage
                        ?? L10n.string("workflow.final.tryAgain")
                )
                return
            }
        }
    }

    func submitFinalVideoConfirmation(removesWatermark: Bool = false) {
        beginFinalVideoCommand(.validating(L10n.string("workflow.final.checkingPlan")))
        let currentRemovesWatermark = renderPlan?.watermark?.selectedRemoveWatermark ?? false
        let needsUpdatedPlan = removesWatermark != currentRemovesWatermark
            || renderPlan?.canCreateVideo != true
        if needsUpdatedPlan {
            prepareFinalVideoPlanFromCurrentSelection(
                removesWatermark: removesWatermark,
                confirmsAfterPreparation: true
            )
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
            failFinalVideoCommand(L10n.string("create.error.currentVideoMissing"))
            return
        }
        guard canGenerateFinalRender || renderPlan?.canCreateVideo == true else {
            failFinalVideoCommand(
                finalRenderAvailabilityMessage
                    ?? videoDirectionAvailabilityMessage
                    ?? L10n.string("create.error.videoCreationNotReady")
            )
            return
        }

        let form = effectiveFinalRenderForm()
        let preparedRenderPlan = confirmableRenderPlan(videoId: context.videoId)
        beginFinalVideoCommand(.confirming(L10n.string("workflow.final.creatingVideo")))
        updateFinalRenderStatusMessage(L10n.string("workflow.final.creatingVideo"))

        runOperation {
            if let preparedRenderPlan {
                finalRenderWorkflow.usePreparedRenderPlan(preparedRenderPlan)
            }

            let didStartFinalRender = await finalRenderWorkflow.confirmPreparedFinalRender(
                videoId: context.videoId,
                template: context.template,
                creationStyle: self.selectedCreationStyle.id,
                form: form,
                selectedMedia: self.effectiveSelectedMedia,
                removesWatermark: removesWatermark
            )
            if didStartFinalRender {
                if let pendingGalleryVideo = finalRenderWorkflow.pendingGalleryVideo {
                    self.acceptPendingGalleryVideo(pendingGalleryVideo)
                    self.beginFinalVideoCommand(.completedDownloadReady(
                        finalRenderWorkflow.statusMessage ?? L10n.string("workflow.final.savedLocal")
                    ))
                    self.updateFinalRenderStatusMessage(
                        finalRenderWorkflow.statusMessage ?? L10n.string("workflow.final.savedLocal")
                    )
                    return
                }
                self.beginFinalVideoCommand(.queued(L10n.string("workflow.final.creatingVideo")))
                self.updateFinalRenderStatusMessage(L10n.string("workflow.final.creatingVideo"))
                return
            }
            guard finalRenderWorkflow.latestFinalJob != nil
                    || finalRenderWorkflow.finalExport != nil
                    || finalRenderWorkflow.pendingGalleryVideo != nil
                    || finalRenderWorkflow.isGenerating else {
                self.failFinalVideoCommand(
                    finalRenderWorkflow.statusMessage
                        ?? L10n.string("workflow.final.tryAgain")
                )
                return
            }
        }
    }

    private func resolveVideoIdForPreparation(form: AnimateVideoSetupForm) async -> String? {
        if let activeVideoId {
            return activeVideoId
        }
        guard let videoCreationWorkflow else {
            return nil
        }
        let videoId = await videoCreationWorkflow.createVideo(form: form)
        if videoId != nil {
            isLocalVideoCreationStarted = false
        }
        return videoId
    }

    private func persistSetupEditsIfNeeded(videoId: String, form: AnimateVideoSetupForm) async -> Bool {
        guard hasPendingLocalSetupEdits else { return true }
        guard let videoCreationWorkflow else { return false }
        return await videoCreationWorkflow.updateVideoSetup(videoId: videoId, form: form)
    }

    private func prepareVideoDirectionIfNeeded(
        videoId: String,
        form: AnimateVideoSetupForm,
        selectedMedia: [AnimateSelectedMedia],
        videoDirectionWorkflow: VideoDirectionWorkflow
    ) async -> Bool {
        var inputSignature = preparedVideoDirectionComparisonInputSignature(videoId: videoId)
        if videoDirectionSummary.hasScenes, lastPreparedVideoDirectionInputSignature == inputSignature {
            updateVideoDirectionStatusMessage(L10n.string("create.story.status.alreadyReady"))
            return true
        }

        let persistedMedia = await mediaUploadWorkflow?.persistSelectedMedia(videoId: videoId)
        guard persistedMedia != nil || selectedMedia.isEmpty else {
            updateVideoDirectionStatusMessage(mediaStatusMessage ?? AnimateRecoveryCopy.mediaStorySaveFailure())
            return false
        }
        inputSignature = currentVideoDirectionInputSignature(
            videoId: videoId,
            persistedMedia: persistedMedia
        )

        let didPrepareVideoDirection = await videoDirectionWorkflow.generatePlan(
            videoId: videoId,
            form: form,
            selectedMedia: selectedMedia,
            persistedMedia: persistedMedia
        )
        if didPrepareVideoDirection {
            let generatedScenes = videoDirectionWorkflow.generatedPlan?.scenes ?? []
            if !generatedScenes.isEmpty {
                applyVideoDirectionState(
                    AnimateCreateVideoDirectionState(
                        activeWorkspace: activeWorkspace,
                        savedScenes: savedScenes,
                        generatedScenes: generatedScenes,
                        statusMessage: nil,
                        isPlanning: videoDirectionWorkflow.isPlanning
                    )
                )
            }
            recordPreparedVideoDirectionInputSignature(inputSignature, videoId: videoId)
            if !generatedScenes.isEmpty {
                lastPreparedVideoDirectionInputSignature = inputSignature
            }
        }

        guard (videoDirectionSummary.hasScenes || videoDirectionWorkflow.generatedPlan?.scenes.isEmpty == false),
              lastPreparedVideoDirectionInputSignature == inputSignature else {
            failVideoDirectionPreparation(L10n.string("create.error.storyPreparationUnfinished"))
            return false
        }
        return true
    }

    func retryFinalVideoDownload() {
        guard let finalRenderWorkflow else {
            updateFinalRenderStatusMessage(L10n.string("create.error.finalDownloadUnavailable"))
            return
        }

        finalRenderWorkflow.retryFinalVideoDownload(workspace: effectiveActiveWorkspace)
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

    private var activeTemplateContext: (videoId: String, template: AnimateVideoTemplate)? {
        guard let activeVideoId else { return nil }
        return (activeVideoId, form.template)
    }

    private var activeFormContext: (videoId: String, form: AnimateVideoSetupForm)? {
        guard let activeVideoId else { return nil }
        return (activeVideoId, form)
    }

    private func failVideoDirectionPreparation(_ message: String) {
        updateVideoDirectionStatusMessage(message)
        updateSetupErrorMessage(message)
    }

    private func videoCreationFailureMessage() -> String {
        videoCreationWorkflow?.errorMessage
            ?? setupErrorMessage
            ?? AnimateRecoveryCopy.storyStartFailure()
    }
}
