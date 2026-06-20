import Combine
import Foundation
import OSLog
import Photos

@MainActor
final class FinalRenderWorkflow: WorkspaceObservingWorkflow {
    @Published private(set) var finalExport: AnimateArtifact?
    @Published private(set) var latestFinalJob: AnimateRenderJob?
    @Published private(set) var renderPlan: AnimateRenderPlanResponse?
    @Published private(set) var videoQuote: AnimateVideoQuoteResponse?
    @Published private(set) var isGenerating = false
    @Published private(set) var pendingGalleryVideo: AnimateGalleryVideoRecord?
    @Published private(set) var pendingGalleryImage: AnimateGalleryImageRecord?
    @Published private(set) var canRetryFinalVideoDownload = false
    @Published private(set) var isSavingFinalVideo = false
    @Published private(set) var statusMessage: String?

    private var latestFinalJobVideoId: String?
    private var workspaceErrorCancellable: AnyCancellable?

    private let currentUserProvider: any AnimateCurrentUserProviding
    private let authTokenProvider: any AnimateAuthTokenProviding
    private let creditBalanceProvider: any AnimateCreditBalanceProviding
    private let finalRenderClient: AnimateFinalRenderClient
    private let renderStatusClient: AnimateRenderStatusClient
    private let videoQuoteClient: AnimateVideoQuoteClient
    private let uploadClient: AnimateUploadClient?
    private let galleryStore: any AnimateGalleryStoring
    private let logger = Logger(subsystem: "com.avalsys.animateav", category: "final-render")
    private var downloadingArtifactIds = Set<String>()
    private var lastCreditRefreshKey: String?
    private var preparedVideoSourceUpload: PreparedVideoSourceUpload?
    private var pendingSourceComparisonImageData: Data?
    private let finalArtifactDownloadTimeout: UInt64 = 130_000_000_000
    private var renderStatusWatchTask: Task<Void, Never>?
    private var watchedRenderJobId: String?
    private let renderStatusWatchTimeout: TimeInterval = 12 * 60
    private let renderStatusWatchInterval: UInt64 = 10_000_000_000

    init(
        currentUserProvider: any AnimateCurrentUserProviding,
        authTokenProvider: any AnimateAuthTokenProviding,
        creditBalanceProvider: any AnimateCreditBalanceProviding,
        workspaceObserver: any AnimateActiveWorkspaceObserving,
        finalRenderClient: AnimateFinalRenderClient,
        renderStatusClient: AnimateRenderStatusClient? = nil,
        videoQuoteClient: AnimateVideoQuoteClient? = nil,
        uploadClient: AnimateUploadClient? = nil,
        galleryStore: any AnimateGalleryStoring = AnimateGalleryStore()
    ) {
        self.currentUserProvider = currentUserProvider
        self.authTokenProvider = authTokenProvider
        self.creditBalanceProvider = creditBalanceProvider
        self.finalRenderClient = finalRenderClient
        self.renderStatusClient = renderStatusClient ?? AnimateRenderStatusClient(baseURLString: finalRenderClient.baseURLString)
        self.videoQuoteClient = videoQuoteClient ?? AnimateVideoQuoteClient(baseURLString: finalRenderClient.baseURLString)
        self.uploadClient = uploadClient
        self.galleryStore = galleryStore
        super.init(workspaceObserver: workspaceObserver)
        workspaceErrorCancellable = workspaceObserver.workspaceErrorPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let message, !message.isEmpty else { return }
                self?.logger.error("Animate workspace observation failed: \(message, privacy: .public)")
                self?.statusMessage = message
            }
    }

    override func workspaceDidChange(_ workspace: AnimateWorkspace?) {
        logger.info(
            "Animate workspace update videoId=\(workspace?.video.id ?? "nil", privacy: .public) finalArtifact=\(workspace?.latestFinalVideoArtifact?.id ?? "nil", privacy: .public) latestJobStatus=\(workspace?.latestRenderJob(kind: "final")?.status ?? "nil", privacy: .public)"
        )
        let latestFinalExport = workspace?.latestFinalVideoArtifact
        if shouldScheduleLocalGalleryDownload(workspace: workspace, artifact: latestFinalExport) {
            isSavingFinalVideo = true
            canRetryFinalVideoDownload = false
        }
        finalExport = latestFinalExport
        let videoId = workspace?.video.id
        if let workspaceFinalJob = workspace?.latestRenderJob(kind: "final") {
            latestFinalJob = workspaceFinalJob
            latestFinalJobVideoId = videoId
        } else if videoId == nil || latestFinalJobVideoId != videoId {
            latestFinalJob = nil
            latestFinalJobVideoId = videoId
        }
        refreshCreditBalanceIfTerminalStateChanged(workspace: workspace)
        scheduleGeneratedImagePreviewDownloadIfNeeded(workspace: workspace)
        scheduleLocalGalleryDownloadIfNeeded(workspace: workspace)
        updateRenderStatusWatch(workspace: workspace)
    }

    var isConfigured: Bool {
        finalRenderClient.isConfigured
    }

    func canGenerate(template: AnimateVideoTemplate) -> Bool {
        guard activeWorkspace?.video != nil else { return false }
        return currentUserProvider.currentUserId != nil
            && isConfigured
            && !isGenerating
    }

    func canPreparePlan() -> Bool {
        currentUserProvider.currentUserId != nil
            && isConfigured
            && activeWorkspace?.video != nil
            && !isGenerating
    }

    func quoteVideo(
        form: AnimateVideoSetupForm,
        removesWatermark: Bool = false
    ) async {
        guard let bearerToken = await validatedBearerTokenForFinalRender() else { return }

        do {
            videoQuote = try await videoQuoteClient.quoteVideo(
                hasMessage: form.activeMessageText != nil,
                messageText: form.activeMessageText,
                removeBranding: removesWatermark,
                bearerToken: bearerToken
            )
        } catch let error as AnimateAPIError {
            logger.error("Video quote API error code=\(error.code, privacy: .public) message=\(error.message, privacy: .public)")
            videoQuote = nil
            statusMessage = finalRenderMessage(for: error)
        } catch {
            AnimateWorkflowDiagnostics.capture(
                error,
                feature: "animate.final_render",
                operation: "quote_video",
                step: "unknown",
                data: [
                    "has_message": String(form.activeMessageText != nil),
                    "voice_enabled": String(form.activeVoiceProfile != nil),
                    "removes_watermark": String(removesWatermark),
                ]
            )
            videoQuote = nil
            statusMessage = AnimateVideoQuoteError.quoteFailed.localizedDescription
        }
    }

    func prepareFinalRenderPlan(
        videoId: String,
        template: AnimateVideoTemplate,
        creationStyle: AnimateVideoCreationStyleID?,
        form: AnimateVideoSetupForm,
        selectedMedia: [AnimateSelectedMedia],
        removesWatermark: Bool = false
    ) async {
        guard let bearerToken = await validatedBearerTokenForFinalRender() else { return }
        guard validateRecoveredSourceMediaAvailable(selectedMedia: selectedMedia) else { return }
        pendingSourceComparisonImageData = comparisonSourceImageData(from: selectedMedia)
        guard needsRenderPlanForFinalRender(videoId: videoId, removesWatermark: removesWatermark) else {
            statusMessage = L10n.string("workflow.final.planReady")
            return
        }

        let generation = beginWorkflowGeneration()
        isGenerating = true
        renderPlan = nil
        videoQuote = nil
        statusMessage = L10n.string("workflow.final.preparing")
        AnimateWorkflowDiagnostics.addBreadcrumb(
            feature: "animate.final_render",
            operation: "prepare_plan",
            data: [
                "video_id": videoId,
                "selected_count": String(selectedMedia.filter(\.selected).count),
                "removes_watermark": String(removesWatermark),
                "has_message": String(form.activeMessageText != nil),
            ]
        )

        do {
            statusMessage = L10n.string("workflow.final.checkingPlan")
            logger.info("Preparing final render plan videoId=\(videoId, privacy: .public)")
            let selectedSourceLocalIdentifiers = selectedSourceLocalIdentifiersForFinalRender(from: selectedMedia)
            AnimateWorkflowDiagnostics.addBreadcrumb(
                feature: "animate.final_render",
                operation: "prepare_plan_source",
                data: [
                    "video_id": videoId,
                    "has_source_upload": "false",
                    "selected_source_count": String(selectedSourceLocalIdentifiers.count),
                ]
            )
            let plan = try await prepareRenderPlanWithUploadVisibilityRetry(
                videoId: videoId,
                bearerToken: bearerToken,
                template: template,
                creationStyle: creationStyle,
                form: form,
                removesWatermark: removesWatermark,
                selectedSourceLocalIdentifiers: selectedSourceLocalIdentifiers,
                sourceImageUploadId: nil
            )
            guard isCurrentWorkflowGeneration(generation) else { return }
            renderPlan = plan
            statusMessage = plan.canCreateVideo
                ? L10n.string("workflow.final.planReady")
                : L10n.string("workflow.final.needsUsableMedia")
            logger.info("Final render plan ready videoId=\(videoId, privacy: .public) planId=\(plan.planId, privacy: .public) cost=\(plan.plan.totalCreditCost, privacy: .public)")
            if !plan.canCreateVideo {
                logger.warning(
                    "Final render plan blocked videoId=\(videoId, privacy: .public) planId=\(plan.planId, privacy: .public) blockers=\(plan.createVideoBlockers.joined(separator: ","), privacy: .public) cost=\(plan.plan.totalCreditCost, privacy: .public) plannedAssets=\(plan.plan.plannedAssetCount, privacy: .public) usedAssets=\(plan.plan.usedAssetCount, privacy: .public)"
                )
                if plan.createVideoBlockers.contains("insufficient_credits") {
                    await creditBalanceProvider.refreshCreditBalance()
                }
            }
        } catch let error as AnimateAPIError {
            guard isCurrentWorkflowGeneration(generation) else { return }
            logger.error("Final render plan API error code=\(error.code, privacy: .public) message=\(error.message, privacy: .public) videoId=\(videoId, privacy: .public)")
            AnimateWorkflowDiagnostics.capture(
                error,
                feature: "animate.final_render",
                operation: "prepare_plan",
                step: "api",
                data: [
                    "selected_count": String(selectedMedia.filter(\.selected).count),
                    "removes_watermark": String(removesWatermark),
                ]
            )
            renderPlan = nil
            statusMessage = finalRenderMessage(for: error)
        } catch {
            guard isCurrentWorkflowGeneration(generation) else { return }
            AnimateWorkflowDiagnostics.capture(
                error,
                feature: "animate.final_render",
                operation: "prepare_plan",
                step: "unknown",
                data: [
                    "selected_count": String(selectedMedia.filter(\.selected).count),
                    "removes_watermark": String(removesWatermark),
                ]
            )
            renderPlan = nil
            statusMessage = AnimateRecoveryCopy.renderStartFailure()
        }

        guard isCurrentWorkflowGeneration(generation) else { return }
        isGenerating = false
    }

    @discardableResult
    func confirmPreparedFinalRender(
        videoId: String,
        template: AnimateVideoTemplate,
        creationStyle: AnimateVideoCreationStyleID?,
        form: AnimateVideoSetupForm,
        selectedMedia: [AnimateSelectedMedia],
        removesWatermark: Bool = false
    ) async -> Bool {
        guard let ownerUserId = currentUserProvider.currentUserId else {
            statusMessage = L10n.string("workflow.final.signInRender")
            logger.warning("Final render confirm aborted: missing owner user id")
            return false
        }
        guard let bearerToken = await validatedBearerTokenForFinalRender() else {
            logger.warning("Final render confirm aborted: missing or invalid bearer token")
            return false
        }
        guard let renderPlan, renderPlan.canCreateVideo else {
            statusMessage = L10n.string("workflow.final.checkingPlan")
            logger.warning("Final render confirm aborted: missing or non-creatable render plan")
            return false
        }
        guard validateRecoveredSourceMediaAvailable(selectedMedia: selectedMedia) else {
            logger.warning("Final render confirm aborted: recovered source media unavailable")
            return false
        }
        pendingSourceComparisonImageData = comparisonSourceImageData(from: selectedMedia)
        guard !needsRenderPlanForFinalRender(videoId: videoId, removesWatermark: removesWatermark) else {
            self.renderPlan = nil
            statusMessage = L10n.string("workflow.final.checkingPlan")
            logger.warning("Final render confirm aborted: render plan needs refresh")
            return false
        }

        let requiredCredits = renderPlan.plan.totalCreditCost
        guard creditBalanceProvider.currentCreditBalance.spendable >= requiredCredits else {
            statusMessage = AnimateCreateAvailabilityCopy.finalRenderInsufficientCredits(
                missingCredits: max(0, requiredCredits - creditBalanceProvider.currentCreditBalance.spendable)
            )
            logger.warning("Final render confirm aborted: insufficient credits required=\(requiredCredits, privacy: .public) spendable=\(self.creditBalanceProvider.currentCreditBalance.spendable, privacy: .public)")
            return false
        }

        let generation = beginWorkflowGeneration()
        isGenerating = true
        statusMessage = L10n.string("workflow.final.creatingVideo")
        AnimateWorkflowDiagnostics.addBreadcrumb(
            feature: "animate.final_render",
            operation: "confirm",
            data: [
                "video_id": videoId,
                "plan_id": renderPlan.planId,
                "selected_count": String(selectedMedia.filter(\.selected).count),
                "required_credits": String(requiredCredits),
                "removes_watermark": String(removesWatermark),
                "has_message": String(form.activeMessageText != nil),
            ]
        )

        if AnimateUITestEnvironment.current.isEnabled {
            latestFinalJob = AnimateCreateUITestFixtures
                .workspace(for: .full)
                .latestRenderJob(kind: "final")
            latestFinalJobVideoId = videoId
            prepareUITestFinalExportForGallery(
                workspace: AnimateCreateUITestFixtures.workspace(for: .full)
            )
            guard isCurrentWorkflowGeneration(generation) else { return true }
            isGenerating = false
            return true
        }

        do {
            let selectedSourceLocalIdentifiers = selectedSourceLocalIdentifiersForFinalRender(from: selectedMedia)
            let sourceImageUploadId = try await prepareVideoSourceUploadIfNeeded(
                videoId: videoId,
                selectedMedia: selectedMedia,
                bearerToken: bearerToken
            )
            AnimateWorkflowDiagnostics.addBreadcrumb(
                feature: "animate.final_render",
                operation: "confirm_source",
                data: [
                    "video_id": videoId,
                    "plan_id": renderPlan.planId,
                    "has_source_upload": String(sourceImageUploadId != nil),
                    "selected_source_count": String(selectedSourceLocalIdentifiers.count),
                ]
            )
            logger.info("Confirming final render videoId=\(videoId, privacy: .public) planId=\(renderPlan.planId, privacy: .public) cost=\(renderPlan.plan.totalCreditCost, privacy: .public) selectedMedia=\(selectedSourceLocalIdentifiers.count, privacy: .public)")
            let confirmed = try await finalRenderClient.confirmFinalRender(
                videoId: videoId,
                bearerToken: bearerToken,
                template: template,
                creationStyle: creationStyle,
                form: form,
                removesWatermark: removesWatermark,
                selectedSourceLocalIdentifiers: selectedSourceLocalIdentifiers,
                sourceImageUploadId: sourceImageUploadId,
                planId: renderPlan.planId,
                renderOptionId: renderPlan.plan.renderOptionId
            )
            self.renderPlan = confirmed.renderPlan
            latestFinalJob = AnimateRenderJob(
                id: confirmed.workflow.renderJobId,
                kind: "final",
                status: confirmed.workflow.status,
                userMessage: L10n.string("workflow.final.creatingVideo"),
                canEditSetup: false,
                totalCreditCost: Double(requiredCredits),
                plannedAssetCount: Double(renderPlan.plan.plannedAssetCount),
                usedAssetCount: Double(renderPlan.plan.usedAssetCount),
                rendererMode: renderPlan.plan.rendererMode,
                workflowRunId: confirmed.workflow.workflowRunId,
                createdAt: Date().timeIntervalSince1970 * 1000,
                updatedAt: Date().timeIntervalSince1970 * 1000
            )
            latestFinalJobVideoId = videoId
            startRenderStatusWatch(renderJobId: confirmed.workflow.renderJobId, videoId: videoId)

            guard isCurrentWorkflowGeneration(generation) else { return true }

            if AnimateUITestEnvironment.current.isEnabled {
                prepareUITestFinalExportForGallery(
                    workspace: AnimateCreateUITestFixtures.workspace(for: .full)
                )
                isGenerating = false
                return true
            }

            workspaceObserver.observeWorkspace(ownerUserId: ownerUserId, videoId: videoId)
            await creditBalanceProvider.refreshCreditBalance()
            statusMessage = L10n.string("workflow.final.creatingVideo")
            isGenerating = false
            return true
        } catch let error as AnimateAPIError {
            guard isCurrentWorkflowGeneration(generation) else { return false }
            logger.error("Final render API error code=\(error.code, privacy: .public) message=\(error.message, privacy: .public) videoId=\(videoId, privacy: .public)")
            AnimateWorkflowDiagnostics.capture(
                error,
                feature: "animate.final_render",
                operation: "confirm",
                step: "api",
                data: [
                    "selected_count": String(selectedMedia.filter(\.selected).count),
                    "required_credits": String(requiredCredits),
                    "removes_watermark": String(removesWatermark),
                ]
            )
            if error.code == "animate_render_plan_stale" {
                self.renderPlan = nil
            }
            statusMessage = finalRenderMessage(for: error)
        } catch {
            guard isCurrentWorkflowGeneration(generation) else { return false }
            logger.error("Final render unexpected error type=\(String(describing: type(of: error)), privacy: .public) message=\(error.localizedDescription, privacy: .public) videoId=\(videoId, privacy: .public)")
            AnimateWorkflowDiagnostics.capture(
                error,
                feature: "animate.final_render",
                operation: "confirm",
                step: "unknown",
                data: [
                    "selected_count": String(selectedMedia.filter(\.selected).count),
                    "required_credits": String(requiredCredits),
                    "removes_watermark": String(removesWatermark),
                ]
            )
            statusMessage = AnimateRecoveryCopy.renderStartFailure()
        }

        guard isCurrentWorkflowGeneration(generation) else { return false }
        isGenerating = false
        return false
    }

    private func refreshCreditBalanceIfTerminalStateChanged(workspace: AnimateWorkspace?) {
        guard let workspace else {
            lastCreditRefreshKey = nil
            return
        }

        let refreshKey: String?
        if let finalExport = workspace.latestFinalVideoArtifact {
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

    private func finalRenderMessage(for error: AnimateAPIError) -> String {
        if error.code == "animate_sign_in_required"
            || error.code == "animate_auth_token_missing" {
            return L10n.string("workflow.final.signInAgainRender")
        }
        if error.code == "unauthorized" {
            return L10n.string("workflow.final.tryAgain")
        }
        if error.code == "insufficient_credits" || error.code == "insufficient_animate_credits" {
            return L10n.string("workflow.final.addCredits")
        }
        if error.code == "animate_render_plan_stale" {
            return L10n.string("workflow.final.planChanged")
        }
        if error.code == "animate_render_plan_not_creatable" {
            return L10n.string("workflow.final.notCreatable")
        }
        if error.code == "animate_workspace_video_not_found" {
            return L10n.string("workflow.final.missingVideo")
        }
        if error.isLikelyConfigurationOrServerContractError {
            return L10n.string("workflow.final.contactSupport")
        }
        return L10n.string("workflow.final.tryAgain")
    }

    private func prepareRenderPlanWithUploadVisibilityRetry(
        videoId: String,
        bearerToken: String,
        template: AnimateVideoTemplate,
        creationStyle: AnimateVideoCreationStyleID?,
        form: AnimateVideoSetupForm,
        removesWatermark: Bool,
        selectedSourceLocalIdentifiers: [String],
        sourceImageUploadId: String?
    ) async throws -> AnimateRenderPlanResponse {
        var attempt = 0

        while true {
            do {
                return try await finalRenderClient.prepareRenderPlan(
                    videoId: videoId,
                    bearerToken: bearerToken,
                    template: template,
                    creationStyle: creationStyle,
                    form: form,
                    removesWatermark: removesWatermark,
                    selectedSourceLocalIdentifiers: selectedSourceLocalIdentifiers,
                    sourceImageUploadId: sourceImageUploadId
                )
            } catch let error as AnimateAPIError where error.isRetryableMediaVisibilityError && attempt < 2 {
                attempt += 1
                try await Task.sleep(nanoseconds: UInt64(attempt) * 750_000_000)
            }
        }
    }

    private func prepareVideoSourceUploadIfNeeded(
        videoId: String,
        selectedMedia: [AnimateSelectedMedia],
        bearerToken: String
    ) async throws -> String? {
        guard let client = uploadClient,
              client.isConfigured,
              let media = selectedMedia
                .filter(\.selected)
                .sorted(by: { $0.sortOrder < $1.sortOrder })
                .first,
              !media.data.isEmpty
        else {
            return nil
        }

        let cacheKey = "\(media.sourceLocalIdentifier):\(media.sha256)"
        if let preparedVideoSourceUpload,
           preparedVideoSourceUpload.cacheKey == cacheKey {
            return preparedVideoSourceUpload.sourceImageUploadId
        }

        let preparedUpload = try await client.prepareUpload(
            videoId: videoId,
            bearerToken: bearerToken,
            media: media
        )
        let uploadedSource = try await client.upload(
            media: media,
            preparedUpload: preparedUpload
        )
        preparedVideoSourceUpload = PreparedVideoSourceUpload(
            cacheKey: cacheKey,
            sourceImageUploadId: uploadedSource.mediaAssetId
        )
        return uploadedSource.mediaAssetId
    }

    func selectedSourceLocalIdentifiersForFinalRender(from selectedMedia: [AnimateSelectedMedia]) -> [String] {
        selectedSourceLocalIdentifiersForFinalRender(
            from: selectedMedia,
            workspaceMedia: activeWorkspace?.mediaAssets ?? []
        )
    }

    private func comparisonSourceImageData(from selectedMedia: [AnimateSelectedMedia]) -> Data? {
        let selectedPhoto = selectedMedia
            .filter { $0.selected && $0.kind == "photo" && !$0.data.isEmpty }
            .sorted { $0.sortOrder < $1.sortOrder }
            .first
        if let selectedPhoto {
            return selectedPhoto.data
        }

        return selectedMedia
            .filter { $0.kind == "photo" && !$0.data.isEmpty }
            .sorted { $0.sortOrder < $1.sortOrder }
            .first?
            .data
    }

    func selectedSourceLocalIdentifiersForFinalRender(
        from selectedMedia: [AnimateSelectedMedia],
        workspaceMedia: [AnimateMediaAsset]
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

    private func validateRecoveredSourceMediaAvailable(selectedMedia: [AnimateSelectedMedia]) -> Bool {
        guard selectedMedia.isEmpty else { return true }
        let workspaceMedia = activeWorkspace?.mediaAssets ?? []
        let selectedWorkspaceMedia = workspaceMedia.filter(\.selected)
        let recoveredWorkspaceMedia = selectedWorkspaceMedia.isEmpty ? workspaceMedia : selectedWorkspaceMedia
        if recoveredWorkspaceMedia.contains(where: { media in
            Self.nonBlankIdentifier(media.uploadId) != nil
                || Self.nonBlankIdentifier(media.r2Key) != nil
        }) {
            return true
        }

        let sourceIdentifiers = recoveredWorkspaceMedia
            .sorted { $0.sortOrder < $1.sortOrder }
            .compactMap { Self.nonBlankIdentifier($0.platformMediaAssetId) }
        guard !sourceIdentifiers.isEmpty else { return true }

        let result = PHAsset.fetchAssets(withLocalIdentifiers: sourceIdentifiers, options: nil)
        guard result.count == sourceIdentifiers.count else {
            renderPlan = nil
            statusMessage = L10n.string("workflow.final.sourceMediaMissing")
            return false
        }

        return true
    }

    func needsRenderPlanForFinalRender(videoId: String, removesWatermark: Bool) -> Bool {
        Self.needsRenderPlanForFinalRender(
            renderPlan: renderPlan,
            videoId: videoId,
            removesWatermark: removesWatermark
        )
    }

    static func needsRenderPlanForFinalRender(
        renderPlan: AnimateRenderPlanResponse?,
        videoId: String,
        removesWatermark: Bool
    ) -> Bool {
        guard let renderPlan else { return true }
        return renderPlan.videoId != videoId
            || (renderPlan.watermark?.selectedRemoveWatermark ?? false) != removesWatermark
    }

    func clearRenderPlan(invalidateActiveGeneration: Bool = false) {
        if invalidateActiveGeneration {
            advanceWorkflowGeneration()
            isGenerating = false
        } else {
            guard !isGenerating else { return }
        }
        renderPlan = nil
        videoQuote = nil
        preparedVideoSourceUpload = nil
        statusMessage = nil
    }

    func usePreparedRenderPlan(_ plan: AnimateRenderPlanResponse) {
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
        latestFinalJobVideoId = nil
        renderPlan = nil
        videoQuote = nil
        preparedVideoSourceUpload = nil
        pendingGalleryVideo = nil
        pendingGalleryImage = nil
        pendingSourceComparisonImageData = nil
        canRetryFinalVideoDownload = false
        isSavingFinalVideo = false
        stopRenderStatusWatch()
        statusMessage = nil
    }

    private func updateRenderStatusWatch(workspace: AnimateWorkspace?) {
        guard let workspace,
              let job = workspace.latestRenderJob(kind: "final"),
              job.isActiveRender else {
            stopRenderStatusWatchIfNoActiveJob()
            return
        }
        startRenderStatusWatch(renderJobId: job.id, videoId: workspace.video.id)
    }

    private func startRenderStatusWatch(renderJobId: String, videoId: String) {
        guard renderStatusClient.isConfigured else { return }
        guard watchedRenderJobId != renderJobId else { return }
        stopRenderStatusWatch()
        watchedRenderJobId = renderJobId
        renderStatusWatchTask = Task { [weak self] in
            await self?.watchRenderStatus(renderJobId: renderJobId, videoId: videoId)
        }
    }

    private func stopRenderStatusWatchIfNoActiveJob() {
        guard latestFinalJob?.isActiveRender != true else { return }
        stopRenderStatusWatch()
    }

    private func stopRenderStatusWatch() {
        renderStatusWatchTask?.cancel()
        renderStatusWatchTask = nil
        watchedRenderJobId = nil
    }

    private func watchRenderStatus(renderJobId: String, videoId: String) async {
        let startedAt = Date()

        while !Task.isCancelled {
            if Date().timeIntervalSince(startedAt) > renderStatusWatchTimeout {
                await applyRenderStatusWatchTimeout(renderJobId: renderJobId, videoId: videoId)
                return
            }

            do {
                guard let bearerToken = try? await authTokenProvider.currentBearerToken() else {
                    try await Task.sleep(nanoseconds: renderStatusWatchInterval)
                    continue
                }
                let status = try await renderStatusClient.fetchStatus(
                    renderJobId: renderJobId,
                    bearerToken: bearerToken
                )
                await applyPolledRenderStatus(status, videoId: videoId)
                if Self.isTerminalRenderStatus(status.status) {
                    return
                }
            } catch {
                AnimateWorkflowDiagnostics.capture(
                    error,
                    feature: "animate.final_render",
                    operation: "watch_status",
                    step: "poll",
                    data: [
                        "render_job_id": renderJobId,
                    ]
                )
            }

            do {
                try await Task.sleep(nanoseconds: renderStatusWatchInterval)
            } catch {
                return
            }
        }
    }

    private func applyPolledRenderStatus(
        _ status: AnimateRenderStatusResponse,
        videoId: String
    ) async {
        guard status.renderJobId == latestFinalJob?.id || latestFinalJob?.id == nil else {
            return
        }

        latestFinalJob = AnimateRenderJob(
            id: status.renderJobId,
            kind: status.renderKind,
            status: status.status,
            phase: status.phase,
            progressPercent: Double(status.progressPercent),
            userMessage: status.userMessage,
            canEditSetup: status.canEditSetup,
            canRetry: status.canRetry,
            totalCreditCost: status.artifactCreditCost.map(Double.init),
            targetDurationMs: status.artifactDurationSeconds.map { Double($0) * 1000 },
            rendererMode: nil,
            workflowRunId: status.workflowRunId,
            errorCode: status.errorCode,
            errorMessage: status.errorMessage,
            createdAt: Date().timeIntervalSince1970 * 1000,
            updatedAt: Self.milliseconds(from: status.updatedAt)
        )
        latestFinalJobVideoId = videoId

        if status.status == "completed",
           let artifact = Self.artifact(from: status) {
            finalExport = artifact
            canRetryFinalVideoDownload = false
            refreshCreditBalanceIfTerminalStateChanged(workspace: activeWorkspace)
            if let workspace = activeWorkspace {
                scheduleLocalGalleryDownloadIfNeeded(workspace: workspace, artifact: artifact)
            }
            stopRenderStatusWatch()
        } else if Self.isTerminalRenderStatus(status.status) {
            canRetryFinalVideoDownload = false
            await creditBalanceProvider.refreshCreditBalance()
            stopRenderStatusWatch()
        }
    }

    private func applyRenderStatusWatchTimeout(renderJobId: String, videoId: String) async {
        guard latestFinalJob?.id == renderJobId,
              latestFinalJob?.isActiveRender == true else {
            return
        }

        latestFinalJob = AnimateRenderJob(
            id: renderJobId,
            kind: "final",
            status: "failed",
            phase: "failed_recoverable",
            progressPercent: 100,
            userMessage: L10n.string("workflow.final.tryAgain"),
            canEditSetup: true,
            canRetry: true,
            workflowRunId: latestFinalJob?.workflowRunId,
            errorCode: "animate_ios_render_status_timeout",
            errorMessage: L10n.string("workflow.final.tryAgain"),
            createdAt: latestFinalJob?.createdAt ?? Date().timeIntervalSince1970 * 1000,
            updatedAt: Date().timeIntervalSince1970 * 1000
        )
        latestFinalJobVideoId = videoId
        statusMessage = L10n.string("recovery.renderRefreshFailure")
        canRetryFinalVideoDownload = false
        await creditBalanceProvider.refreshCreditBalance()
        stopRenderStatusWatch()
    }

    private static func isTerminalRenderStatus(_ status: String) -> Bool {
        ["completed", "failed", "blocked", "cancelled"].contains(status)
    }

    private static func artifact(from status: AnimateRenderStatusResponse) -> AnimateArtifact? {
        guard let artifactId = status.artifactId,
              let kind = status.artifactKind,
              let artifactStatus = status.artifactStatus,
              let r2Key = status.artifactR2Key else {
            return nil
        }

        return AnimateArtifact(
            id: artifactId,
            workflowArtifactId: artifactId,
            kind: kind,
            r2Key: r2Key,
            title: nil,
            look: nil,
            videoJobId: status.renderJobId,
            status: artifactStatus,
            durationSeconds: status.artifactDurationSeconds.map(Double.init),
            creditCost: status.artifactCreditCost,
            hasWatermark: status.artifactHasWatermark,
            expiresAt: Date().addingTimeInterval(30 * 24 * 60 * 60).timeIntervalSince1970 * 1000,
            createdAt: Self.milliseconds(from: status.updatedAt)
        )
    }

    private static func milliseconds(from isoString: String) -> Double {
        (ISO8601DateFormatter().date(from: isoString)?.timeIntervalSince1970 ?? Date().timeIntervalSince1970) * 1000
    }

    func retryFinalVideoDownload(workspace workspaceOverride: AnimateWorkspace? = nil) {
        guard let workspace = workspaceOverride ?? activeWorkspace,
              let artifact = workspace.latestFinalVideoArtifact,
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

    private func scheduleLocalGalleryDownloadIfNeeded(
        workspace: AnimateWorkspace?,
        artifact artifactOverride: AnimateArtifact? = nil
    ) {
        guard
            let workspace,
            let artifact = artifactOverride ?? workspace.latestFinalVideoArtifact,
            shouldScheduleLocalGalleryDownload(workspace: workspace, artifact: artifact)
        else {
            return
        }

        downloadingArtifactIds.insert(artifact.id)
        canRetryFinalVideoDownload = false
        isSavingFinalVideo = true
        Task { [weak self] in
            await self?.downloadFinalExportToGallery(workspace: workspace, artifact: artifact)
        }
    }

    private func shouldScheduleLocalGalleryDownload(
        workspace: AnimateWorkspace?,
        artifact: AnimateArtifact?
    ) -> Bool {
        guard
            workspace != nil,
            let artifact,
            artifact.status == "available",
            pendingGalleryVideo?.artifactId != finalDownloadArtifactId(for: artifact),
            !galleryStore.contains(artifactId: finalDownloadArtifactId(for: artifact)),
            !downloadingArtifactIds.contains(artifact.id)
        else {
            return false
        }

        return true
    }

    private func scheduleGeneratedImagePreviewDownloadIfNeeded(workspace: AnimateWorkspace?) {
        guard let artifact = workspace?.latestGeneratedImageArtifact else {
            return
        }
        if let localImage = localGeneratedImageRecord(for: artifact) {
            pendingGalleryImage = localImage
            return
        }
        guard
            artifact.status == "available",
            pendingGalleryImage?.artifactId != finalDownloadArtifactId(for: artifact),
            !downloadingArtifactIds.contains(artifact.id)
        else {
            return
        }

        downloadingArtifactIds.insert(artifact.id)
        Task { [weak self] in
            await self?.downloadGeneratedImagePreview(artifact: artifact)
        }
    }

    private func downloadGeneratedImagePreview(artifact: AnimateArtifact) async {
        defer { downloadingArtifactIds.remove(artifact.id) }

        guard let bearerToken = try? await authTokenProvider.currentBearerToken() else {
            return
        }

        do {
            pendingGalleryImage = try await downloadGeneratedImageToGallery(
                artifact: artifact,
                bearerToken: bearerToken
            )
        } catch {
            AnimateWorkflowDiagnostics.capture(
                error,
                feature: "animate.final_render",
                operation: "download",
                step: "generated_image_preview",
                data: [
                    "artifact_status": artifact.status,
                ]
            )
        }
    }

    private func downloadFinalExportToGallery(
        workspace: AnimateWorkspace,
        artifact: AnimateArtifact
    ) async {
        isSavingFinalVideo = true
        defer {
            downloadingArtifactIds.remove(artifact.id)
            isSavingFinalVideo = false
        }

        guard let bearerToken = try? await authTokenProvider.currentBearerToken() else {
            statusMessage = L10n.string("workflow.final.signInAgainSaveLocal")
            canRetryFinalVideoDownload = true
            return
        }

        do {
            statusMessage = L10n.string("workflow.final.savingToGallery")
            AnimateWorkflowDiagnostics.addBreadcrumb(
                feature: "animate.final_render",
                operation: "download",
                data: [
                    "artifact_status": artifact.status,
                ]
            )
            let downloadArtifactId = finalDownloadArtifactId(for: artifact)
            let (temporaryFileURL, downloadedR2Key) = try await withFinalArtifactDownloadTimeout { [self] in
                let download = try await self.finalRenderClient.prepareFinalArtifactDownload(
                    videoId: workspace.video.id,
                    artifactId: downloadArtifactId,
                    bearerToken: bearerToken
                )
                let fileURL = try await self.finalRenderClient.downloadFinalArtifact(from: download)
                return (fileURL, download.r2Key)
            }
            var generatedImageRelativePath: String?
            if let imageArtifact = workspace.latestGeneratedImageArtifact {
                do {
                    pendingGalleryImage = try await downloadGeneratedImageToGallery(
                        artifact: imageArtifact,
                        bearerToken: bearerToken
                    )
                    generatedImageRelativePath = pendingGalleryImage?.localRelativePath
                } catch {
                    pendingGalleryImage = nil
                    AnimateWorkflowDiagnostics.capture(
                        error,
                        feature: "animate.final_render",
                        operation: "download",
                        step: "generated_image_gallery_save",
                        data: [
                            "artifact_status": imageArtifact.status,
                        ]
                    )
                }
            }
            let sourceImageRelativePath: String?
            if let pendingSourceComparisonImageData {
                do {
                    sourceImageRelativePath = try galleryStore.saveSourceImage(
                        data: pendingSourceComparisonImageData,
                        videoId: workspace.video.id,
                        artifactId: downloadArtifactId
                    )
                } catch {
                    AnimateWorkflowDiagnostics.capture(
                        error,
                        feature: "animate.final_render",
                        operation: "download",
                        step: "source_image_gallery_save",
                        data: [
                            "artifact_status": artifact.status,
                        ]
                    )
                    sourceImageRelativePath = nil
                }
            } else {
                sourceImageRelativePath = nil
            }
            let createdAt = Date()
            pendingGalleryVideo = try galleryStore.saveDownloadedVideo(
                temporaryFileURL: temporaryFileURL,
                videoId: workspace.video.id,
                artifactId: downloadArtifactId,
                title: AnimateGalleryVideoPresentation.automaticTitle(
                    lookTitle: workspace.video.look.formattedAnimateLookTitle,
                    createdAt: createdAt.timeIntervalSince1970 * 1000
                ),
                r2Key: downloadedR2Key ?? artifact.r2Key,
                sourceImageLocalRelativePath: sourceImageRelativePath,
                generatedImageLocalRelativePath: generatedImageRelativePath,
                createdAt: createdAt
            )
            canRetryFinalVideoDownload = false
            statusMessage = L10n.string("workflow.final.savedLocal")
        } catch {
            pendingGalleryVideo = nil
            pendingGalleryImage = nil
            AnimateWorkflowDiagnostics.capture(
                error,
                feature: "animate.final_render",
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

    private func withFinalArtifactDownloadTimeout<T: Sendable>(
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask { [finalArtifactDownloadTimeout] in
                try await Task.sleep(nanoseconds: finalArtifactDownloadTimeout)
                throw AnimateFinalRenderError.downloadFailed
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    func finalDownloadArtifactId(for artifact: AnimateArtifact) -> String {
        artifact.workflowArtifactId ?? artifact.id
    }

    private func downloadGeneratedImageToGallery(
        artifact: AnimateArtifact,
        bearerToken: String
    ) async throws -> AnimateGalleryImageRecord {
        let artifactId = finalDownloadArtifactId(for: artifact)
        if let pendingGalleryImage,
           pendingGalleryImage.artifactId == artifactId,
           galleryStore.localFileExists(for: pendingGalleryImage) {
            return pendingGalleryImage
        }
        if let localImage = localGeneratedImageRecord(for: artifact) {
            return localImage
        }

        let download = try await finalRenderClient.prepareImageArtifactDownload(
            artifactId: artifactId,
            bearerToken: bearerToken
        )
        let temporaryFileURL = try await finalRenderClient.downloadFinalArtifact(from: download)
        return try galleryStore.saveDownloadedImage(
            temporaryFileURL: temporaryFileURL,
            artifactId: artifactId,
            title: L10n.string("gallery.image.defaultTitle"),
            look: artifact.look,
            r2Key: download.r2Key ?? artifact.r2Key,
            createdAt: Date(timeIntervalSince1970: artifact.createdAt / 1000)
        )
    }

    private func localGeneratedImageRecord(for artifact: AnimateArtifact) -> AnimateGalleryImageRecord? {
        let artifactId = finalDownloadArtifactId(for: artifact)
        guard galleryStore.containsImage(artifactId: artifactId) else {
            return nil
        }

        let record = AnimateGalleryImageRecord(
            id: artifactId,
            artifactId: artifactId,
            title: L10n.string("gallery.image.defaultTitle"),
            look: artifact.look,
            r2Key: artifact.r2Key,
            localRelativePath: "Images/\(artifactId).jpg",
            createdAt: artifact.createdAt
        )
        return galleryStore.localFileExists(for: record) ? record : nil
    }

    func prepareUITestFinalExportForGallery(workspace: AnimateWorkspace) {
        guard AnimateUITestEnvironment.current.isEnabled,
              let artifact = workspace.latestFinalVideoArtifact
        else { return }

        do {
            let temporaryFileURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("animateav-ui-test-\(UUID().uuidString).mp4")
            try Data("animateav-ui-test-mock-video".utf8).write(to: temporaryFileURL, options: .atomic)
            let downloadArtifactId = finalDownloadArtifactId(for: artifact)
            pendingGalleryVideo = try galleryStore.saveDownloadedVideo(
                temporaryFileURL: temporaryFileURL,
                videoId: workspace.video.id,
                artifactId: downloadArtifactId,
                title: workspace.video.title,
                r2Key: artifact.r2Key,
                sourceImageLocalRelativePath: nil,
                generatedImageLocalRelativePath: workspace.latestGeneratedImageArtifact.map {
                    "Images/\(finalDownloadArtifactId(for: $0)).jpg"
                },
                createdAt: Date(timeIntervalSince1970: max(workspace.video.updatedAt, artifact.createdAt) / 1000)
            )
            if let imageArtifact = workspace.latestGeneratedImageArtifact {
                pendingGalleryImage = AnimateGalleryImageRecord(
                    id: finalDownloadArtifactId(for: imageArtifact),
                    artifactId: finalDownloadArtifactId(for: imageArtifact),
                    title: L10n.string("gallery.image.defaultTitle"),
                    look: imageArtifact.look,
                    r2Key: imageArtifact.r2Key,
                    localRelativePath: "Images/\(finalDownloadArtifactId(for: imageArtifact)).jpg",
                    createdAt: imageArtifact.createdAt
                )
            }
            canRetryFinalVideoDownload = false
            downloadingArtifactIds.remove(artifact.id)
            statusMessage = L10n.string("workflow.final.savedLocal")
        } catch {
            canRetryFinalVideoDownload = true
            statusMessage = L10n.string("workflow.final.saveLocalFailed")
        }
    }

    @discardableResult
    func finishFinalExportToGallery() -> Bool {
        guard let pendingGalleryVideo else {
            if let finalExport,
               galleryStore.contains(artifactId: finalDownloadArtifactId(for: finalExport)) {
                canRetryFinalVideoDownload = false
                statusMessage = L10n.string("workflow.final.movedToGallery")
                return true
            }

            statusMessage = L10n.string("workflow.final.downloadBeforeGallery")
            return false
        }

        galleryStore.addRecord(pendingGalleryVideo)
        if let pendingGalleryImage {
            galleryStore.addImageRecord(pendingGalleryImage)
        }
        self.pendingGalleryVideo = nil
        self.pendingGalleryImage = nil
        self.pendingSourceComparisonImageData = nil
        canRetryFinalVideoDownload = false
        statusMessage = L10n.string("workflow.final.movedToGallery")
        return true
    }

    func clearFinalSessionAfterGalleryMove() {
        advanceWorkflowGeneration()
        clearActiveWorkspace()
        finalExport = nil
        latestFinalJob = nil
        latestFinalJobVideoId = nil
        renderPlan = nil
        isGenerating = false
        pendingGalleryVideo = nil
        pendingGalleryImage = nil
        pendingSourceComparisonImageData = nil
        canRetryFinalVideoDownload = false
        isSavingFinalVideo = false
        downloadingArtifactIds.removeAll()
        lastCreditRefreshKey = nil
        statusMessage = nil
    }

    private func generateBlockMessage(_ availability: AnimateFinalRenderRules.Availability) -> String {
        AnimateFinalRenderRules.availabilityMessage(
            availability,
            missingVideoMessage: L10n.string("workflow.final.missingVideo"),
            insufficientCreditsMessage: L10n.string("workflow.final.addCredits")
        ) ?? L10n.string("workflow.final.notReady")
    }

    private static func nonBlankOptional(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

}

private struct PreparedVideoSourceUpload {
    let cacheKey: String
    let sourceImageUploadId: String
}

private extension AnimateAPIError {
    var isRetryableMediaVisibilityError: Bool {
        code == "insufficient_allowed_media"
            || code == "animate_final_render_source_media_required"
            || code == "animate_render_timeline_duration_required"
    }
}
