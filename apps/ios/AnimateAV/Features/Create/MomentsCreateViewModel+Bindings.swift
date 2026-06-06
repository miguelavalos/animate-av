import Combine
import Foundation

extension MomentsCreateViewModel {
    func bindWorkflowState(
        accountStateProvider: any MomentsAccountStateProviding,
        momentCreationWorkflow: MomentCreationWorkflow,
        mediaUploadWorkflow: MediaUploadWorkflow,
        storyWorkflow: StoryWorkflow,
        finalRenderWorkflow: FinalRenderWorkflow
    ) {
        bindAccount(accountStateProvider)
        bindMomentCreation(momentCreationWorkflow)
        bindMediaUpload(mediaUploadWorkflow)
        bindStory(storyWorkflow)
        bindFinalRender(finalRenderWorkflow)
    }

    private func bindAccount(_ accountStateProvider: any MomentsAccountStateProviding) {
        Publishers.CombineLatest3(
            accountStateProvider.isSignedInPublisher,
            accountStateProvider.creditBalancePublisher,
            accountStateProvider.creditBalanceLoadStatePublisher
        )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isSignedIn, balance, creditBalanceLoadState in
                self?.applyAccountState(
                    MomentsCreateAccountState(
                        isSignedIn: isSignedIn,
                        balance: balance,
                        creditBalanceLoadState: creditBalanceLoadState
                    )
                )
            }
            .store(in: &cancellables)
    }

    private func bindMomentCreation(_ workflow: MomentCreationWorkflow) {
        Publishers.CombineLatest3(
            workflow.$isCreatingMoment,
            workflow.$activeMomentId,
            workflow.$errorMessage
        )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isCreatingMoment, activeMomentId, setupErrorMessage in
                self?.applyMomentCreationState(
                    MomentsCreateMomentCreationState(
                        isCreatingMoment: isCreatingMoment,
                        activeMomentId: activeMomentId,
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
                    MomentsCreateMediaUploadState(
                        selectedMedia: selectedMedia,
                        statusMessage: statusMessage,
                        isImporting: isImporting,
                        importProgress: importProgress
                    )
                )
            }
            .store(in: &cancellables)
    }

    private func bindStory(_ workflow: StoryWorkflow) {
        Publishers.CombineLatest4(
            workflow.$activeWorkspace,
            workflow.$generatedPlan.map { $0?.scenes ?? [] },
            workflow.$statusMessage,
            workflow.$isPlanning
        )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] activeWorkspace, generatedScenes, statusMessage, isPlanning in
                self?.applyStoryState(
                    MomentsCreateStoryState(
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
            workflow.$isGenerating,
            workflow.$statusMessage,
            workflow.$canRetryFinalVideoDownload
        )
            .receive(on: DispatchQueue.main)
            .sink { [weak self] content, isGenerating, statusMessage, canRetryFinalVideoDownload in
                let (finalExport, latestFinalJob, renderPlan, pendingGalleryVideo) = content
                self?.applyFinalRenderState(
                    MomentsCreateFinalRenderState(
                        finalExport: finalExport,
                        latestFinalJob: latestFinalJob,
                        renderPlan: renderPlan,
                        pendingGalleryVideo: pendingGalleryVideo,
                        canRetryFinalVideoDownload: canRetryFinalVideoDownload,
                        statusMessage: statusMessage,
                        isGenerating: isGenerating
                    )
                )
            }
            .store(in: &cancellables)
    }
}
