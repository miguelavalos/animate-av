extension MomentsCreateViewModel {
    var canBeginNewMoment: Bool {
        !isSetupLocked && !isBusy
    }

    var isSetupLocked: Bool {
        activeMomentId != nil
    }

    var isBusy: Bool {
        isCreatingMoment
            || isImportingMedia
            || isPlanningStory
            || isGeneratingFinalRender
            || finalVideoCommandState.isRunning
    }

    var canAddMedia: Bool {
        !isFinalRenderEditingLocked && workflowCapability.canAddMedia
    }

    var canPlanStory: Bool {
        !isFinalRenderEditingLocked && workflowCapability.canPlanStory
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

    var workflowCapability: MomentsCreateWorkflowCapability {
        if let fixtureMode = activeUITestFixtureMode {
            return MomentsCreateWorkflowCapability(
                canAddMedia: false,
                canPlanStory: false,
                canPrepareFinalRenderPlan: fixtureMode != .full
                    && !isBusy,
                canGenerateFinalRender: fixtureMode != .full
                    && !isBusy
                    && MomentsCreditGate.canAfford(form.template, balance: balance),
                canRefreshFinalRenderStatus: false
            )
        }

        return MomentsCreateWorkflowCapabilityFactory.make(
            activeMomentId: activeMomentId,
            isSignedIn: isSignedIn,
            hasMomentWorkspace: hasMomentWorkspace,
            isImportingMedia: isImportingMedia,
            mediaRemainingSlots: mediaRemainingSlots,
            storyWorkflow: storyWorkflow,
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

    var isStoryPreparedForCurrentInput: Bool {
        if usesCreateUITestFixture {
            return true
        }
        guard storySummary.hasScenes else { return false }
        guard let activeMomentId else { return false }
        let preparedSignature = lastPreparedStoryInputSignature ?? effectiveActiveWorkspace?.moment.storyInputSignature
        guard let preparedSignature else {
            return true
        }
        return preparedStoryComparisonInputSignature(momentId: activeMomentId) == preparedSignature
    }
}
