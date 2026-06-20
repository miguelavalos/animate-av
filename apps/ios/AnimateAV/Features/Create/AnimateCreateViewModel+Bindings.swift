import Combine
import Foundation

extension AnimateCreateViewModel {
    func bindWorkflowState(
        accountStateProvider: any AnimateAccountStateProviding,
        videoCreationWorkflow: AnimateVideoCreationWorkflow,
        mediaUploadWorkflow: MediaUploadWorkflow,
        videoDirectionWorkflow: VideoDirectionWorkflow,
        finalRenderWorkflow: FinalRenderWorkflow
    ) {
        bindAccount(accountStateProvider)
        bindVideoCreation(videoCreationWorkflow)
        bindMediaUpload(mediaUploadWorkflow)
        bindVideoDirection(videoDirectionWorkflow)
        bindFinalRender(finalRenderWorkflow)
    }

    private func bindAccount(_ accountStateProvider: any AnimateAccountStateProviding) {
        Publishers.CombineLatest3(
            accountStateProvider.isSignedInPublisher,
            accountStateProvider.creditBalancePublisher,
            accountStateProvider.creditBalanceLoadStatePublisher
        )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSignedIn, balance, creditBalanceLoadState in
                self?.applyAccountState(
                    AnimateCreateAccountState(
                        isSignedIn: isSignedIn,
                        balance: balance,
                        creditBalanceLoadState: creditBalanceLoadState
                    )
                )
            }
            .store(in: &cancellables)
    }

    private func bindVideoCreation(_ workflow: AnimateVideoCreationWorkflow) {
        Publishers.CombineLatest3(
            workflow.$isCreatingVideo,
            workflow.$activeVideoId,
            workflow.$errorMessage
        )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isCreatingVideo, activeVideoId, setupErrorMessage in
                self?.applyVideoCreationState(
                    AnimateCreateVideoCreationState(
                        isCreatingVideo: isCreatingVideo,
                        activeVideoId: activeVideoId,
                        setupErrorMessage: setupErrorMessage
                    )
                )
            }
            .store(in: &cancellables)
    }

    private func bindMediaUpload(_ workflow: MediaUploadWorkflow) {
        Publishers.CombineLatest4(
            workflow.$selectedMedia,
            workflow.$statusMessage,
            workflow.$isImporting,
            workflow.$importProgress
        )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] selectedMedia, statusMessage, isImporting, importProgress in
                self?.applyMediaUploadState(
                    AnimateCreateMediaUploadState(
                        selectedMedia: selectedMedia,
                        statusMessage: statusMessage,
                        isImporting: isImporting,
                        importProgress: importProgress
                    )
                )
            }
            .store(in: &cancellables)
    }

    private func bindVideoDirection(_ workflow: VideoDirectionWorkflow) {
        Publishers.CombineLatest4(
            workflow.$activeWorkspace,
            workflow.$generatedPlan.map { $0?.scenes ?? [] },
            workflow.$statusMessage,
            workflow.$isPlanning
        )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeWorkspace, generatedScenes, statusMessage, isPlanning in
                self?.applyVideoDirectionState(
                    AnimateCreateVideoDirectionState(
                        activeWorkspace: activeWorkspace,
                        savedScenes: activeWorkspace?.storyScenes ?? [],
                        generatedScenes: generatedScenes,
                        statusMessage: statusMessage,
                        isPlanning: isPlanning
                    )
                )
            }
            .store(in: &cancellables)
    }

    private func bindFinalRender(_ workflow: FinalRenderWorkflow) {
        Publishers.CombineLatest4(
            Publishers.CombineLatest4(
                workflow.$finalExport,
                workflow.$latestFinalJob,
                workflow.$renderPlan,
                workflow.$pendingGalleryVideo
            ),
            Publishers.CombineLatest4(
                workflow.$videoQuote,
                workflow.$isGenerating,
                workflow.$statusMessage,
                workflow.$canRetryFinalVideoDownload
            ),
            workflow.$pendingGalleryImage,
            workflow.$isSavingFinalVideo
        )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] content, state, pendingGalleryImage, isSavingFinalVideo in
                let (finalExport, latestFinalJob, renderPlan, pendingGalleryVideo) = content
                let (videoQuote, isGenerating, statusMessage, canRetryFinalVideoDownload) = state
                self?.applyFinalRenderState(
                    AnimateCreateFinalRenderState(
                        finalExport: finalExport,
                        latestFinalJob: latestFinalJob,
                        renderPlan: renderPlan,
                        videoQuote: videoQuote,
                        pendingGalleryVideo: pendingGalleryVideo,
                        pendingGalleryImage: pendingGalleryImage,
                        canRetryFinalVideoDownload: canRetryFinalVideoDownload,
                        isSavingFinalVideo: isSavingFinalVideo,
                        statusMessage: statusMessage,
                        isGenerating: isGenerating
                    )
                )
            }
            .store(in: &cancellables)
    }
}
