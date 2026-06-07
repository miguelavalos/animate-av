import Foundation
import OSLog
import Photos

@MainActor
final class FinalRenderWorkflow: WorkspaceObservingWorkflow {
    @Published private(set) var finalExport: MomentArtifact?
    @Published private(set) var latestFinalJob: MomentRenderJob?
    @Published private(set) var renderPlan: MomentsRenderPlanResponse?
    @Published private(set) var videoQuote: AnimateVideoQuoteResponse?
    @Published private(set) var isGenerating = false
    @Published private(set) var pendingGalleryVideo: MomentsGalleryVideoRecord?
    @Published private(set) var canRetryFinalVideoDownload = false
    @Published private(set) var statusMessage: String?

    private var latestFinalJobMomentId: String?

    private let currentUserProvider: any MomentsCurrentUserProviding
    private let authTokenProvider: any MomentsAuthTokenProviding
    private let creditBalanceProvider: any MomentsCreditBalanceProviding
    private let finalRenderClient: MomentsFinalRenderClient
    private let videoQuoteClient: MomentsVideoQuoteClient
    private let galleryStore: any MomentsGalleryStoring
    private let logger = Logger(subsystem: "com.avalsys.animateav", category: "final-render")
    private var downloadingArtifactIds = Set<String>()
    private var lastCreditRefreshKey: String?

    init(
        currentUserProvider: any MomentsCurrentUserProviding,
        authTokenProvider: any MomentsAuthTokenProviding,
        creditBalanceProvider: any MomentsCreditBalanceProviding,
        workspaceObserver: any MomentsActiveWorkspaceObserving,
        finalRenderClient: MomentsFinalRenderClient,
        videoQuoteClient: MomentsVideoQuoteClient? = nil,
        galleryStore: any MomentsGalleryStoring = MomentsGalleryStore()
    ) {
        self.currentUserProvider = currentUserProvider
        self.authTokenProvider = authTokenProvider
        self.creditBalanceProvider = creditBalanceProvider
        self.finalRenderClient = finalRenderClient
        self.videoQuoteClient = videoQuoteClient ?? MomentsVideoQuoteClient(baseURLString: finalRenderClient.baseURLString)
        self.galleryStore = galleryStore
        super.init(workspaceObserver: workspaceObserver)
    }

    override func workspaceDidChange(_ workspace: MomentWorkspace?) {
        finalExport = workspace?.latestArtifact(kind: "final_export")
        let momentId = workspace?.moment.id
        if let workspaceFinalJob = workspace?.latestRenderJob(kind: "final") {
            latestFinalJob = workspaceFinalJob
            latestFinalJobMomentId = momentId
        } else if momentId == nil || latestFinalJobMomentId != momentId {
            latestFinalJob = nil
            latestFinalJobMomentId = momentId
        }
        refreshCreditBalanceIfTerminalStateChanged(workspace: workspace)
        scheduleLocalGalleryDownloadIfNeeded(workspace: workspace)
    }

    var isConfigured: Bool {
        finalRenderClient.isConfigured
    }

    func canGenerate(template: MomentTemplate) -> Bool {
        guard activeWorkspace?.moment != nil else { return false }
        return currentUserProvider.currentUserId != nil
            && isConfigured
            && !isGenerating
    }

    func canPreparePlan() -> Bool {
        currentUserProvider.currentUserId != nil
            && isConfigured
            && activeWorkspace?.moment != nil
            && !isGenerating
    }

    func quoteVideo(
        form: MomentSetupForm,
        removesWatermark: Bool = false
    ) async {
        guard let bearerToken = await validatedBearerTokenForFinalRender() else { return }
        let messageFields = Self.videoMessageFields(form)

        do {
            videoQuote = try await videoQuoteClient.quoteVideo(
                message: messageFields.message,
                script: messageFields.script,
                removeBranding: removesWatermark,
                bearerToken: bearerToken
            )
        } catch let error as MomentsAPIError {
            logger.error("Video quote API error code=\(error.code, privacy: .public) message=\(error.message, privacy: .public)")
            videoQuote = nil
            statusMessage = error.localizedDescription
        } catch {
            MomentsWorkflowDiagnostics.capture(
                error,
                feature: "moments.final_render",
                operation: "quote_video",
                step: "unknown",
                data: [
                    "has_message": String(messageFields.message != nil),
                    "has_script": String(messageFields.script != nil),
                    "removes_watermark": String(removesWatermark),
                ]
            )
            videoQuote = nil
            statusMessage = MomentsVideoQuoteError.quoteFailed.localizedDescription
        }
    }

    func prepareFinalRenderPlan(
        momentId: String,
        template: MomentTemplate,
        creationStyle: MomentCreationStyleID?,
        form: MomentSetupForm,
        selectedMedia: [MomentsSelectedMedia],
        removesWatermark: Bool = false
    ) async {
        guard let bearerToken = await validatedBearerTokenForFinalRender() else { return }
        guard validateRecoveredSourceMediaAvailable(selectedMedia: selectedMedia) else { return }
        guard needsRenderPlanForFinalRender(momentId: momentId, removesWatermark: removesWatermark) else {
            statusMessage = L10n.string("workflow.final.planReady")
            return
        }

        let generation = beginWorkflowGeneration()
        isGenerating = true
        renderPlan = nil
        statusMessage = L10n.string("workflow.final.preparing")
        MomentsWorkflowDiagnostics.addBreadcrumb(
            feature: "moments.final_render",
            operation: "prepare_plan",
            data: [
                "selected_count": String(selectedMedia.filter(\.selected).count),
                "removes_watermark": String(removesWatermark),
            ]
        )

        do {
            statusMessage = L10n.string("workflow.final.checkingPlan")
            logger.info("Preparing final render plan momentId=\(momentId, privacy: .public)")
            let plan = try await prepareRenderPlanWithUploadVisibilityRetry(
                momentId: momentId,
                bearerToken: bearerToken,
                template: template,
                creationStyle: creationStyle,
                form: form,
                removesWatermark: removesWatermark,
                selectedSourceLocalIdentifiers: selectedSourceLocalIdentifiersForFinalRender(from: selectedMedia)
            )
            guard isCurrentWorkflowGeneration(generation) else { return }
            renderPlan = plan
            statusMessage = plan.canCreateVideo
                ? L10n.string("workflow.final.planReady")
                : L10n.string("workflow.final.needsUsableMedia")
            logger.info("Final render plan ready momentId=\(momentId, privacy: .public) planId=\(plan.planId, privacy: .public) cost=\(plan.plan.totalCreditCost, privacy: .public)")
            if !plan.canCreateVideo {
                logger.warning(
                    "Final render plan blocked momentId=\(momentId, privacy: .public) planId=\(plan.planId, privacy: .public) blockers=\(plan.createVideoBlockers.joined(separator: ","), privacy: .public) cost=\(plan.plan.totalCreditCost, privacy: .public) plannedAssets=\(plan.plan.plannedAssetCount, privacy: .public) usedAssets=\(plan.plan.usedAssetCount, privacy: .public)"
                )
                if plan.createVideoBlockers.contains("insufficient_credits") {
                    await creditBalanceProvider.refreshCreditBalance()
                }
            }
        } catch let error as MomentsAPIError {
            guard isCurrentWorkflowGeneration(generation) else { return }
            logger.error("Final render plan API error code=\(error.code, privacy: .public) message=\(error.message, privacy: .public) momentId=\(momentId, privacy: .public)")
            MomentsWorkflowDiagnostics.capture(
                error,
                feature: "moments.final_render",
                operation: "prepare_plan",
                step: "api",
                data: [
                    "selected_count": String(selectedMedia.filter(\.selected).count),
                    "removes_watermark": String(removesWatermark),
                ]
            )
            renderPlan = nil
            statusMessage = error.localizedDescription
        } catch {
            guard isCurrentWorkflowGeneration(generation) else { return }
            MomentsWorkflowDiagnostics.capture(
                error,
                feature: "moments.final_render",
                operation: "prepare_plan",
                step: "unknown",
                data: [
                    "selected_count": String(selectedMedia.filter(\.selected).count),
                    "removes_watermark": String(removesWatermark),
                ]
            )
            renderPlan = nil
            statusMessage = MomentsRecoveryCopy.renderStartFailure()
        }

        guard isCurrentWorkflowGeneration(generation) else { return }
        isGenerating = false
    }

    func confirmPreparedFinalRender(
        momentId: String,
        template: MomentTemplate,
        creationStyle: MomentCreationStyleID?,
        form: MomentSetupForm,
        selectedMedia: [MomentsSelectedMedia],
        removesWatermark: Bool = false
    ) async {
        guard let ownerUserId = currentUserProvider.currentUserId else {
            statusMessage = L10n.string("workflow.final.signInRender")
            return
        }
        guard let bearerToken = await validatedBearerTokenForFinalRender() else { return }
        guard let renderPlan, renderPlan.canCreateVideo else {
            statusMessage = L10n.string("workflow.final.checkingPlan")
            return
        }
        guard validateRecoveredSourceMediaAvailable(selectedMedia: selectedMedia) else { return }
        guard !needsRenderPlanForFinalRender(momentId: momentId, removesWatermark: removesWatermark) else {
            self.renderPlan = nil
            statusMessage = L10n.string("workflow.final.checkingPlan")
            return
        }

        let requiredCredits = renderPlan.plan.totalCreditCost
        guard creditBalanceProvider.currentCreditBalance.spendable >= requiredCredits else {
            statusMessage = MomentsCreateAvailabilityCopy.finalRenderInsufficientCredits(
                missingCredits: max(0, requiredCredits - creditBalanceProvider.currentCreditBalance.spendable)
            )
            return
        }

        let generation = beginWorkflowGeneration()
        isGenerating = true
        statusMessage = L10n.string("workflow.final.creatingVideo")
        MomentsWorkflowDiagnostics.addBreadcrumb(
            feature: "moments.final_render",
            operation: "confirm",
            data: [
                "selected_count": String(selectedMedia.filter(\.selected).count),
                "required_credits": String(requiredCredits),
                "removes_watermark": String(removesWatermark),
            ]
        )

        do {
            let selectedSourceLocalIdentifiers = selectedSourceLocalIdentifiersForFinalRender(from: selectedMedia)
            logger.info("Confirming final render momentId=\(momentId, privacy: .public) planId=\(renderPlan.planId, privacy: .public) cost=\(renderPlan.plan.totalCreditCost, privacy: .public) selectedMedia=\(selectedSourceLocalIdentifiers.count, privacy: .public)")
            let confirmed = try await finalRenderClient.confirmFinalRender(
                momentId: momentId,
                bearerToken: bearerToken,
                template: template,
                creationStyle: creationStyle,
                form: form,
                removesWatermark: removesWatermark,
                selectedSourceLocalIdentifiers: selectedSourceLocalIdentifiers,
                planId: renderPlan.planId,
                renderOptionId: renderPlan.plan.renderOptionId
            )
            self.renderPlan = confirmed.renderPlan

            guard isCurrentWorkflowGeneration(generation) else { return }

            await creditBalanceProvider.refreshCreditBalance()
            workspaceObserver.observeWorkspace(ownerUserId: ownerUserId, momentId: momentId)
            statusMessage = L10n.string("workflow.final.creatingVideo")
        } catch let error as MomentsAPIError {
            guard isCurrentWorkflowGeneration(generation) else { return }
            logger.error("Final render API error code=\(error.code, privacy: .public) message=\(error.message, privacy: .public) momentId=\(momentId, privacy: .public)")
            MomentsWorkflowDiagnostics.capture(
                error,
                feature: "moments.final_render",
                operation: "confirm",
                step: "api",
                data: [
                    "selected_count": String(selectedMedia.filter(\.selected).count),
                    "required_credits": String(requiredCredits),
                    "removes_watermark": String(removesWatermark),
                ]
            )
            if error.code == "moments_render_plan_stale" {
                self.renderPlan = nil
            }
            statusMessage = error.localizedDescription
        } catch {
            guard isCurrentWorkflowGeneration(generation) else { return }
            MomentsWorkflowDiagnostics.capture(
                error,
                feature: "moments.final_render",
                operation: "confirm",
                step: "unknown",
                data: [
                    "selected_count": String(selectedMedia.filter(\.selected).count),
                    "required_credits": String(requiredCredits),
                    "removes_watermark": String(removesWatermark),
                ]
            )
            statusMessage = MomentsRecoveryCopy.renderStartFailure()
        }

        guard isCurrentWorkflowGeneration(generation) else { return }
        isGenerating = false
    }

    private func refreshCreditBalanceIfTerminalStateChanged(workspace: MomentWorkspace?) {
        guard let workspace else {
            lastCreditRefreshKey = nil
            return
        }

        let refreshKey: String?
        if let finalExport = workspace.latestArtifact(kind: "final_export") {
            refreshKey = "artifact:\(finalExport.id)"
        } else if let finalJob = workspace.latestRenderJob(kind: "final"),
                  !finalJob.isActiveRender {
            refreshKey = "job:\(finalJob.id):\(finalJob.status)"
        } else {
            refreshKey = nil
        }

        guard let refreshKey, refreshKey != lastCreditRefreshKey else { return }
        lastCreditRefreshKey = refreshKey
        Task { [creditBalanceProvider] in
            await creditBalanceProvider.refreshCreditBalance()
        }
    }

    private func validatedBearerTokenForFinalRender() async -> String? {
        guard let bearerToken = try? await authTokenProvider.currentBearerToken() else {
            statusMessage = L10n.string("workflow.final.signInAgainRender")
            return nil
        }
        guard isConfigured else {
            statusMessage = L10n.string("workflow.final.notConfigured")
            return nil
        }
        return bearerToken
    }

    private func prepareRenderPlanWithUploadVisibilityRetry(
        momentId: String,
        bearerToken: String,
        template: MomentTemplate,
        creationStyle: MomentCreationStyleID?,
        form: MomentSetupForm,
        removesWatermark: Bool,
        selectedSourceLocalIdentifiers: [String]
    ) async throws -> MomentsRenderPlanResponse {
        var attempt = 0

        while true {
            do {
                return try await finalRenderClient.prepareRenderPlan(
                    momentId: momentId,
                    bearerToken: bearerToken,
                    template: template,
                    creationStyle: creationStyle,
                    form: form,
                    removesWatermark: removesWatermark,
                    selectedSourceLocalIdentifiers: selectedSourceLocalIdentifiers
                )
            } catch let error as MomentsAPIError where error.isRetryableMediaVisibilityError && attempt < 2 {
                attempt += 1
                try await Task.sleep(nanoseconds: UInt64(attempt) * 750_000_000)
            }
        }
    }

    func selectedSourceLocalIdentifiersForFinalRender(from selectedMedia: [MomentsSelectedMedia]) -> [String] {
        selectedSourceLocalIdentifiersForFinalRender(
            from: selectedMedia,
            workspaceMedia: activeWorkspace?.mediaAssets ?? []
        )
    }

    func selectedSourceLocalIdentifiersForFinalRender(
        from selectedMedia: [MomentsSelectedMedia],
        workspaceMedia: [MomentMediaAsset]
    ) -> [String] {
        let localSelection = selectedMedia
            .filter(\.selected)
            .sorted { $0.sortOrder < $1.sortOrder }
            .compactMap { media in
                Self.nonBlankIdentifier(media.sourceLocalIdentifier)
            }

        if !localSelection.isEmpty {
            return localSelection
        }

        let selectedWorkspaceMedia = workspaceMedia.filter(\.selected)
        return (selectedWorkspaceMedia.isEmpty ? workspaceMedia : selectedWorkspaceMedia)
            .sorted { $0.sortOrder < $1.sortOrder }
            .compactMap { media in
                Self.nonBlankIdentifier(media.platformMediaAssetId) ?? Self.nonBlankIdentifier(media.id)
            }
    }

    private static func nonBlankIdentifier(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private func validateRecoveredSourceMediaAvailable(selectedMedia: [MomentsSelectedMedia]) -> Bool {
        guard selectedMedia.isEmpty else { return true }
        let sourceIdentifiers = selectedSourceLocalIdentifiersForFinalRender(
            from: selectedMedia,
            workspaceMedia: activeWorkspace?.mediaAssets ?? []
        )
        guard !sourceIdentifiers.isEmpty else { return true }

        let result = PHAsset.fetchAssets(withLocalIdentifiers: sourceIdentifiers, options: nil)
        guard result.count == sourceIdentifiers.count else {
            renderPlan = nil
            statusMessage = L10n.string("workflow.final.sourceMediaMissing")
            return false
        }

        return true
    }

    func needsRenderPlanForFinalRender(momentId: String, removesWatermark: Bool) -> Bool {
        Self.needsRenderPlanForFinalRender(
            renderPlan: renderPlan,
            momentId: momentId,
            removesWatermark: removesWatermark
        )
    }

    static func needsRenderPlanForFinalRender(
        renderPlan: MomentsRenderPlanResponse?,
        momentId: String,
        removesWatermark: Bool
    ) -> Bool {
        guard let renderPlan else { return true }
        return renderPlan.momentId != momentId
            || (renderPlan.watermark?.selectedRemoveWatermark ?? false) != removesWatermark
    }

    func clearRenderPlan() {
        guard !isGenerating else { return }
        renderPlan = nil
        videoQuote = nil
        statusMessage = nil
    }

    func usePreparedRenderPlan(_ plan: MomentsRenderPlanResponse) {
        guard !isGenerating else { return }
        renderPlan = plan
    }

    func reset(force: Bool = false) {
        guard force || !isGenerating else { return }
        advanceWorkflowGeneration()
        isGenerating = false
        clearActiveWorkspace()
        finalExport = nil
        latestFinalJob = nil
        latestFinalJobMomentId = nil
        renderPlan = nil
        videoQuote = nil
        pendingGalleryVideo = nil
        canRetryFinalVideoDownload = false
        statusMessage = nil
    }

    func retryFinalVideoDownload() {
        guard let workspace = activeWorkspace,
              let artifact = workspace.latestArtifact(kind: "final_export"),
              artifact.status == "available"
        else {
            statusMessage = L10n.string("workflow.final.noDownloadReady")
            return
        }

        guard !downloadingArtifactIds.contains(artifact.id) else {
            statusMessage = L10n.string("workflow.final.downloadInProgress")
            return
        }

        canRetryFinalVideoDownload = false
        downloadingArtifactIds.insert(artifact.id)
        Task { [weak self] in
            await self?.downloadFinalExportToGallery(workspace: workspace, artifact: artifact)
        }
    }

    private func scheduleLocalGalleryDownloadIfNeeded(workspace: MomentWorkspace?) {
        guard
            let workspace,
            let artifact = workspace.latestArtifact(kind: "final_export"),
            artifact.status == "available",
            pendingGalleryVideo?.artifactId != finalDownloadArtifactId(for: artifact),
            !galleryStore.contains(artifactId: finalDownloadArtifactId(for: artifact)),
            !downloadingArtifactIds.contains(artifact.id)
        else {
            return
        }

        downloadingArtifactIds.insert(artifact.id)
        canRetryFinalVideoDownload = false
        Task { [weak self] in
            await self?.downloadFinalExportToGallery(workspace: workspace, artifact: artifact)
        }
    }

    private func downloadFinalExportToGallery(
        workspace: MomentWorkspace,
        artifact: MomentArtifact
    ) async {
        defer { downloadingArtifactIds.remove(artifact.id) }

        guard let bearerToken = try? await authTokenProvider.currentBearerToken() else {
            statusMessage = L10n.string("workflow.final.signInAgainSaveLocal")
            return
        }

        do {
            statusMessage = L10n.string("workflow.final.savingToGallery")
            MomentsWorkflowDiagnostics.addBreadcrumb(
                feature: "moments.final_render",
                operation: "download",
                data: [
                    "artifact_status": artifact.status,
                ]
            )
            let downloadArtifactId = finalDownloadArtifactId(for: artifact)
            let download = try await finalRenderClient.prepareFinalArtifactDownload(
                momentId: workspace.moment.id,
                artifactId: downloadArtifactId,
                bearerToken: bearerToken
            )
            let temporaryFileURL = try await finalRenderClient.downloadFinalArtifact(from: download)
            pendingGalleryVideo = try galleryStore.saveDownloadedVideo(
                temporaryFileURL: temporaryFileURL,
                momentId: workspace.moment.id,
                artifactId: downloadArtifactId,
                title: workspace.moment.title,
                r2Key: download.r2Key ?? artifact.r2Key,
                createdAt: Date()
            )
            canRetryFinalVideoDownload = false
            statusMessage = L10n.string("workflow.final.savedLocal")
        } catch {
            MomentsWorkflowDiagnostics.capture(
                error,
                feature: "moments.final_render",
                operation: "download",
                step: "gallery_save",
                data: [
                    "artifact_status": artifact.status,
                ]
            )
            canRetryFinalVideoDownload = true
            statusMessage = L10n.string("workflow.final.saveLocalFailed")
        }
    }

    func finalDownloadArtifactId(for artifact: MomentArtifact) -> String {
        artifact.workflowArtifactId ?? artifact.id
    }

    @discardableResult
    func finishFinalExportToGallery() -> Bool {
        guard let pendingGalleryVideo else {
            statusMessage = L10n.string("workflow.final.downloadBeforeGallery")
            return false
        }

        galleryStore.addRecord(pendingGalleryVideo)
        self.pendingGalleryVideo = nil
        canRetryFinalVideoDownload = false
        statusMessage = L10n.string("workflow.final.movedToGallery")
        return true
    }

    func clearFinalSessionAfterGalleryMove() {
        advanceWorkflowGeneration()
        clearActiveWorkspace()
        finalExport = nil
        latestFinalJob = nil
        latestFinalJobMomentId = nil
        renderPlan = nil
        isGenerating = false
        pendingGalleryVideo = nil
        canRetryFinalVideoDownload = false
        downloadingArtifactIds.removeAll()
        lastCreditRefreshKey = nil
        statusMessage = nil
    }

    private func generateBlockMessage(_ availability: MomentsFinalRenderRules.Availability) -> String {
        MomentsFinalRenderRules.availabilityMessage(
            availability,
            missingMomentMessage: L10n.string("workflow.final.missingMoment"),
            insufficientCreditsMessage: L10n.string("workflow.final.addCredits")
        ) ?? L10n.string("workflow.final.notReady")
    }

    private static func videoMessageFields(_ form: MomentSetupForm) -> (message: String?, script: String?) {
        if let script = nonBlankOptional(form.details) {
            return (message: nil, script: script)
        }

        return (message: nonBlankOptional(form.occasion), script: nil)
    }

    private static func nonBlankOptional(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

}

private extension MomentsAPIError {
    var isRetryableMediaVisibilityError: Bool {
        code == "insufficient_allowed_media"
            || code == "moments_final_render_source_media_required"
            || code == "moments_render_timeline_duration_required"
    }
}
