extension AnimateCreateViewModel {
    var canBeginNewVideoCreation: Bool {
        !isSetupLocked && !isBusy
    }

    var isSetupLocked: Bool {
        activeVideoId != nil
    }

    var isBusy: Bool {
        isCreatingVideo
            || isImportingMedia
            || isPreparingVideoDirection
            || isGeneratingFinalRender
            || finalVideoCommandState.isRunning
    }

    var canAddMedia: Bool {
        !isFinalRenderEditingLocked && workflowCapability.canAddMedia
    }

    var canPrepareVideoDirection: Bool {
        !isFinalRenderEditingLocked && workflowCapability.canPrepareVideoDirection
    }

    var canPrepareFinalRenderPlan: Bool {
        !isFinalRenderEditingLocked
            && workflowCapability.canPrepareFinalRenderPlan
    }

    var canGenerateFinalRender: Bool {
        !isFinalRenderEditingLocked
            && workflowCapability.canGenerateFinalRender
    }

    var canRefreshFinalRenderStatus: Bool {
        workflowCapability.canRefreshFinalRenderStatus
    }

    var workflowCapability: AnimateCreateWorkflowCapability {
        if let fixtureMode = activeUITestFixtureMode {
            return AnimateCreateWorkflowCapability(
                canAddMedia: false,
                canPrepareVideoDirection: false,
                canPrepareFinalRenderPlan: fixtureMode != .full
                    && !isBusy,
                canGenerateFinalRender: fixtureMode != .full
                    && !isBusy
                    && AnimateCreditGate.canAfford(form.template, balance: balance),
                canRefreshFinalRenderStatus: false
            )
        }

        return AnimateCreateWorkflowCapabilityFactory.make(
            activeVideoId: activeVideoId,
            isSignedIn: isSignedIn,
            hasActiveVideoWorkspace: hasActiveVideoWorkspace,
            isImportingMedia: isImportingMedia,
            mediaRemainingSlots: mediaRemainingSlots,
            videoDirectionWorkflow: videoDirectionWorkflow,
            finalRenderWorkflow: finalRenderWorkflow,
            creditBalanceLoadState: creditBalanceLoadState,
            template: form.template,
            selectedMediaCount: mediaSelectedCount
        )
    }

    var isFinalRenderEditingLocked: Bool {
        guard let latestFinalJob = effectiveLatestFinalJob,
              latestFinalJob.isActiveRender else {
            return false
        }
        return latestFinalJob.canEditSetup != true
    }

    var isVideoDirectionPreparedForCurrentInput: Bool {
        if usesCreateUITestFixture {
            return true
        }
        guard videoDirectionSummary.hasScenes else { return false }
        guard let activeVideoId else { return false }
        let preparedSignature = lastPreparedVideoDirectionInputSignature ?? effectiveActiveWorkspace?.video.storyInputSignature
        guard let preparedSignature else {
            return true
        }
        return preparedVideoDirectionComparisonInputSignature(videoId: activeVideoId) == preparedSignature
    }
}
