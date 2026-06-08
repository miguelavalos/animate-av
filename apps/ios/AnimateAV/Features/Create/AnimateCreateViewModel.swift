import Combine
import CryptoKit
import Foundation

enum AnimateFinalVideoCommandState: Equatable {
    case idle
    case validating(String)
    case preparingPlan(String)
    case confirming(String)
    case queued(String)
    case failed(String)
    case completedDownloadReady(String)
    case completedInGallery(String)

    var message: String? {
        switch self {
        case .idle:
            return nil
        case let .validating(message),
             let .preparingPlan(message),
             let .confirming(message),
             let .queued(message),
             let .failed(message),
             let .completedDownloadReady(message),
             let .completedInGallery(message):
            return message
        }
    }

    var isRunning: Bool {
        switch self {
        case .validating, .preparingPlan, .confirming:
            return true
        case .idle, .queued, .failed, .completedDownloadReady, .completedInGallery:
            return false
        }
    }
}

@MainActor
final class AnimateCreateViewModel: ObservableObject {
    @Published private(set) var isSignedIn = false
    @Published private(set) var balance = AnimateCreditBalance.empty
    @Published private(set) var creditBalanceLoadState = AnimateCreditBalanceLoadState.signedOut
    @Published private(set) var templates = AnimateVideoTemplate.launchTemplates
    @Published private(set) var creationStyles = AnimateVideoCreationStyle.launchStyles
    @Published var selectedCreationStyle = AnimateVideoCreationStyle.launchStyles[0]
    @Published var selectedMusicPreset = AnimateVideoCreationStyle.launchStyles[0].defaultMusic
    @Published var form = AnimateVideoSetupForm(template: AnimateVideoTemplate.launchTemplates[0])
    @Published private(set) var isCreatingVideo = false
    @Published private(set) var isContinuingVideoCreation = false
    @Published var isLocalVideoCreationStarted = false
    @Published private(set) var workflowActiveVideoId: String?
    @Published private(set) var setupErrorMessage: String?
    @Published private(set) var selectedMedia: [AnimateSelectedMedia] = []
    @Published private(set) var mediaStatusMessage: String?
    @Published private(set) var isImportingMedia = false
    @Published private(set) var mediaImportProgress: AnimateMediaImportProgress?
    @Published private(set) var autoStyleSuggestion: AnimateMediaAutoStyleSuggestion?
    @Published private(set) var canUndoAutoStyleSuggestion = false
    @Published private(set) var savedScenes: [AnimateVideoDirectionScene] = []
    @Published private(set) var generatedScenes: [AnimateVideoDirectionSceneResponse] = []
    @Published private(set) var videoDirectionStatusMessage: String?
    @Published private(set) var isPreparingVideoDirection = false
    @Published var isPreparingVideoDirectionAction = false
    @Published private(set) var activeWorkspace: AnimateWorkspace?
    @Published private(set) var finalExport: AnimateArtifact?
    @Published private(set) var latestFinalJob: AnimateRenderJob?
    @Published private(set) var renderPlan: AnimateRenderPlanResponse?
    @Published private(set) var videoQuote: AnimateVideoQuoteResponse?
    @Published private(set) var imageGenerationAvailability: AnimateImageGenerationAvailabilityResponse?
    @Published private(set) var isLoadingImageGenerationAvailability = false
    @Published private(set) var isStartingImageGeneration = false
    @Published private(set) var isPurchasingImageGenerationPack = false
    @Published private(set) var imageGenerationAvailabilityMessage: String?
    @Published private(set) var imageGenerationQueueNonce = UUID()
    @Published private(set) var pendingGalleryVideo: AnimateGalleryVideoRecord?
    @Published private(set) var canRetryFinalVideoDownload = false
    @Published private(set) var finalRenderStatusMessage: String?
    @Published private(set) var isGeneratingFinalRender = false
    @Published private(set) var isPreparingFinalPlan = false
    @Published private(set) var finalVideoCommandState = AnimateFinalVideoCommandState.idle
    @Published var pendingFocus: AnimateContinuationFocus?
    @Published private(set) var continuationFocusHint: AnimateContinuationFocus?
    @Published var mediaPickerOpenRequest = 0

    private(set) var videoCreationWorkflow: AnimateVideoCreationWorkflow?
    private(set) var mediaUploadWorkflow: MediaUploadWorkflow?
    private(set) var videoDirectionWorkflow: VideoDirectionWorkflow?
    private(set) var finalRenderWorkflow: FinalRenderWorkflow?
    private var authTokenProvider: (any AnimateAuthTokenProviding)?
    private var imageGenerationAccountingClient: AnimateImageGenerationAccountingClient?
    let operationRunner = AnimateCreateOperationRunner()
    var cancellables = Set<AnyCancellable>()
    private var autoStyleMediaSignature: String?
    var lastPreparedVideoDirectionInputSignature: String?
    private var renderPlanInputSignature: String?
    private var pendingRenderPlanInputSignature: String?
    private var hasExplicitMediaEditsAfterPreparedVideoDirection = false
    private var hasLocalSetupEdits = false
    private var hasUserStyleOverride = false
    private var hasUserLookOverride = false
    private var hasUserVoiceOverride = false
    private var autoStyleUndoSelection: (style: AnimateVideoCreationStyle, musicPreset: AnimateVideoMusicPreset, form: AnimateVideoSetupForm)?

    var activeVideo: AnimateVideo? {
        if activeUITestFixtureMode != nil {
            return AnimateCreateUITestFixtures.video
        }

        return activeWorkspace?.video
    }

    var activeVideoId: String? {
        activeVideo?.id ?? workflowActiveVideoId
    }

    var hasActiveVideoWorkspace: Bool {
        activeVideoId != nil || isLocalVideoCreationStarted
    }

    var hasRecoverableVideoContext: Bool {
        activeVideoId != nil
            || !selectedMedia.isEmpty
            || isImportingMedia
            || isPreparingVideoDirection
            || !savedScenes.isEmpty
            || !generatedScenes.isEmpty
            || finalExport != nil
            || latestFinalJob != nil
            || renderPlan != nil
    }

    var hasLocalAnimateWorkspace: Bool {
        activeVideoId == nil && isLocalVideoCreationStarted
    }

    var hasPendingLocalSetupEdits: Bool {
        hasLocalSetupEdits
    }

    var workflowErrorAlertMessage: String? {
        [
            setupErrorMessage,
            mediaStatusMessage,
            videoDirectionStatusMessage,
            finalVideoCommandFailureMessage,
            finalRenderAlertMessage
        ]
            .compactMap(\.self)
            .first(where: Self.isUserFacingErrorMessage)
    }

    func bind(
        accountStateProvider: any AnimateAccountStateProviding,
        videoCreationWorkflow: AnimateVideoCreationWorkflow,
        mediaUploadWorkflow: MediaUploadWorkflow,
        videoDirectionWorkflow: VideoDirectionWorkflow,
        finalRenderWorkflow: FinalRenderWorkflow,
        authTokenProvider: any AnimateAuthTokenProviding,
        imageGenerationAccountingClient: AnimateImageGenerationAccountingClient
    ) {
        cancelOperations()
        self.videoCreationWorkflow = videoCreationWorkflow
        self.mediaUploadWorkflow = mediaUploadWorkflow
        self.videoDirectionWorkflow = videoDirectionWorkflow
        self.finalRenderWorkflow = finalRenderWorkflow
        self.authTokenProvider = authTokenProvider
        self.imageGenerationAccountingClient = imageGenerationAccountingClient
        templates = videoCreationWorkflow.launchTemplates
        creationStyles = AnimateVideoCreationStyle.launchStyles
        selectedCreationStyle = AnimateVideoCreationStyle.launchStyles[0]
        selectedMusicPreset = selectedCreationStyle.defaultMusic
        form = AnimateVideoSetupForm(template: videoCreationWorkflow.launchTemplates[0])
        canUndoAutoStyleSuggestion = false
        autoStyleUndoSelection = nil
        applyStyleDefaults(selectedCreationStyle)
        cancellables.removeAll()

        bindWorkflowState(
            accountStateProvider: accountStateProvider,
            videoCreationWorkflow: videoCreationWorkflow,
            mediaUploadWorkflow: mediaUploadWorkflow,
            videoDirectionWorkflow: videoDirectionWorkflow,
            finalRenderWorkflow: finalRenderWorkflow
        )
    }

    func selectCreationStyle(_ style: AnimateVideoCreationStyle) {
        guard style.isEnabled else { return }
        guard canEditCreationOptions else { return }
        selectedCreationStyle = style
        selectedMusicPreset = style.defaultMusic
        hasUserStyleOverride = true
        canUndoAutoStyleSuggestion = false
        autoStyleUndoSelection = nil
        applyStyleDefaults(style, preserveUserOverrides: true)
        markLocalSetupEdited()
    }

    func selectMusicPreset(_ preset: AnimateVideoMusicPreset) {
        guard selectedCreationStyle.allowedMusic.contains(preset) else { return }
        hasUserStyleOverride = true
        canUndoAutoStyleSuggestion = false
        autoStyleUndoSelection = nil
        selectedMusicPreset = preset
        form.tone = AnimateVideoSetupTone(musicPreset: preset)
        markLocalSetupEdited()
    }

    func useAutoStyleSuggestion() {
        guard canEditCreationOptions else { return }
        guard let suggestion = autoStyleSuggestion else { return }
        guard let suggestedStyle = creationStyles.first(where: { $0.id == suggestion.styleID && $0.isEnabled }) else { return }
        autoStyleUndoSelection = (selectedCreationStyle, selectedMusicPreset, form)
        selectedCreationStyle = suggestedStyle
        selectedMusicPreset = suggestion.musicPreset
        hasUserStyleOverride = false
        canUndoAutoStyleSuggestion = true
        applyStyleDefaults(suggestedStyle, preserveUserOverrides: true)
        form.tone = AnimateVideoSetupTone(musicPreset: suggestion.musicPreset)
        markLocalSetupEdited()
    }

    func undoAutoStyleSuggestion() {
        guard canEditCreationOptions else { return }
        guard let previous = autoStyleUndoSelection else { return }
        selectedCreationStyle = previous.style
        selectedMusicPreset = previous.musicPreset
        form = previous.form
        hasUserStyleOverride = true
        canUndoAutoStyleSuggestion = false
        autoStyleUndoSelection = nil
        markLocalSetupEdited()
    }

    func clearSessionState() {
        resetActiveVideoCreation(force: true)
        imageGenerationAvailability = nil
        imageGenerationAvailabilityMessage = nil
        isLoadingImageGenerationAvailability = false
        isStartingImageGeneration = false
        isPurchasingImageGenerationPack = false
    }

    func refreshImageGenerationAvailability() {
        guard !isLoadingImageGenerationAvailability else { return }
        guard let authTokenProvider,
              let imageGenerationAccountingClient,
              imageGenerationAccountingClient.isConfigured
        else {
            imageGenerationAvailabilityMessage = AnimateImageGenerationAccountingError.apiNotConfigured.localizedDescription
            return
        }

        isLoadingImageGenerationAvailability = true
        imageGenerationAvailabilityMessage = nil
        Task { [weak self, authTokenProvider, imageGenerationAccountingClient] in
            do {
                guard let bearerToken = try await authTokenProvider.currentBearerToken() else {
                    throw AnimateImageGenerationAccountingError.signInRequired
                }
                let availability = try await imageGenerationAccountingClient.fetchAvailability(bearerToken: bearerToken)
                await MainActor.run {
                    self?.imageGenerationAvailability = availability
                    self?.imageGenerationAvailabilityMessage = nil
                    self?.isLoadingImageGenerationAvailability = false
                }
            } catch {
                await MainActor.run {
                    self?.imageGenerationAvailabilityMessage = self?.imageGenerationMessage(for: error)
                    self?.isLoadingImageGenerationAvailability = false
                }
            }
        }
    }

    func startImageGeneration(
        sourceImageLocalIdentifier: String?,
        imageData: Data?,
        width: Int?,
        height: Int?,
        looks: [String]
    ) {
        guard !isStartingImageGeneration else { return }
        guard let sourceImageLocalIdentifier = sourceImageLocalIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines),
              !sourceImageLocalIdentifier.isEmpty
        else {
            imageGenerationAvailabilityMessage = L10n.string("create.images.action.needsImage")
            return
        }
        guard let imageData, !imageData.isEmpty else {
            imageGenerationAvailabilityMessage = L10n.string("create.images.action.needsImage")
            return
        }
        guard let availability = imageGenerationAvailability,
              availability.availableImages >= looks.count
        else {
            imageGenerationAvailabilityMessage = L10n.string("create.images.balance.empty")
            return
        }
        guard let authTokenProvider,
              let imageGenerationAccountingClient,
              imageGenerationAccountingClient.isConfigured
        else {
            imageGenerationAvailabilityMessage = AnimateImageGenerationAccountingError.apiNotConfigured.localizedDescription
            return
        }

        isStartingImageGeneration = true
        imageGenerationAvailabilityMessage = nil
        Task { [weak self, authTokenProvider, imageGenerationAccountingClient] in
            do {
                guard let bearerToken = try await authTokenProvider.currentBearerToken() else {
                    throw AnimateImageGenerationAccountingError.signInRequired
                }
                let sha256 = SHA256.hash(data: imageData)
                    .map { String(format: "%02x", $0) }
                    .joined()
                let preparedUpload = try await imageGenerationAccountingClient.prepareSourceImageUpload(
                    sourceLocalIdentifier: sourceImageLocalIdentifier,
                    originalFilename: "animate-source.jpg",
                    contentType: "image/jpeg",
                    byteSize: imageData.count,
                    sha256: sha256,
                    width: width,
                    height: height,
                    bearerToken: bearerToken
                )
                let uploadedSource = try await imageGenerationAccountingClient.uploadSourceImage(
                    data: imageData,
                    preparedUpload: preparedUpload
                )
                let response = try await imageGenerationAccountingClient.startGeneration(
                    sourceImageUploadId: uploadedSource.sourceImageUploadId,
                    looks: looks,
                    idempotencyKey: "animate-images-\(UUID().uuidString)",
                    bearerToken: bearerToken
                )
                await MainActor.run {
                    self?.imageGenerationAvailability = response.availability
                    self?.imageGenerationAvailabilityMessage = L10n.string("create.images.action.queued", response.jobs.count)
                    self?.imageGenerationQueueNonce = UUID()
                    self?.isStartingImageGeneration = false
                }
            } catch {
                await MainActor.run {
                    self?.imageGenerationAvailabilityMessage = self?.imageGenerationMessage(for: error)
                    self?.isStartingImageGeneration = false
                }
            }
        }
    }

    func purchaseImageGenerationPack() {
        guard !isPurchasingImageGenerationPack else { return }
        guard let availability = imageGenerationAvailability,
              availability.packOffer.userCanPurchase
        else {
            imageGenerationAvailabilityMessage = L10n.string("create.images.balance.empty")
            return
        }
        guard let authTokenProvider,
              let imageGenerationAccountingClient,
              imageGenerationAccountingClient.isConfigured
        else {
            imageGenerationAvailabilityMessage = AnimateImageGenerationAccountingError.apiNotConfigured.localizedDescription
            return
        }

        isPurchasingImageGenerationPack = true
        imageGenerationAvailabilityMessage = nil
        Task { [weak self, authTokenProvider, imageGenerationAccountingClient] in
            do {
                guard let bearerToken = try await authTokenProvider.currentBearerToken() else {
                    throw AnimateImageGenerationAccountingError.signInRequired
                }
                let response = try await imageGenerationAccountingClient.purchasePack(
                    idempotencyKey: "animate-image-pack-\(UUID().uuidString)",
                    bearerToken: bearerToken
                )
                await MainActor.run {
                    self?.imageGenerationAvailability = response.availability
                    self?.imageGenerationAvailabilityMessage = L10n.string(
                        "create.images.balance.packPurchased",
                        response.purchase.imageGenerationsAdded,
                        response.purchase.creditCost
                    )
                    self?.isPurchasingImageGenerationPack = false
                }
            } catch {
                await MainActor.run {
                    self?.imageGenerationAvailabilityMessage = self?.imageGenerationMessage(for: error)
                    self?.isPurchasingImageGenerationPack = false
                }
            }
        }
    }

    private func imageGenerationMessage(for error: Error) -> String {
        if let accountingError = error as? AnimateImageGenerationAccountingError {
            switch accountingError {
            case .signInRequired:
                return L10n.string("create.images.balance.signIn")
            case .apiNotConfigured, .availabilityFailed, .startFailed, .sourceUploadFailed, .packPurchaseFailed:
                break
            }
        }
        if let apiError = error as? AnimateAPIError,
           apiError.code == "unauthorized" || apiError.code == "moments_sign_in_required" || apiError.code == "moments_auth_token_missing" {
            return L10n.string("create.images.balance.signIn")
        }
        return error.localizedDescription
    }

    func prepareNewVideoCreation() {
        isContinuingVideoCreation = false
        continuationFocusHint = nil
        isLocalVideoCreationStarted = false
        hasLocalSetupEdits = false
        hasUserLookOverride = false
        hasUserVoiceOverride = false
    }

    func continueVideo(_ video: AnimateVideo, focus: AnimateContinuationFocus = .video) {
        cancelOperations()
        isContinuingVideoCreation = true
        isLocalVideoCreationStarted = false
        hasLocalSetupEdits = false
        hasUserLookOverride = false
        hasUserVoiceOverride = false
        pendingFocus = focus
        continuationFocusHint = focus

        if let continuedForm = AnimateVideoSetupForm.continuing(video: video, templates: templates) {
            form = continuedForm
        }

        videoCreationWorkflow?.continueVideo(video)
    }

    func consumePendingFocus() {
        pendingFocus = nil
    }

    func clearContinuationFocusHint() {
        continuationFocusHint = nil
    }

    func consumeMediaPickerOpenRequest() {
        mediaPickerOpenRequest = 0
    }

    func applyUITestCreateFixture() {
        guard let fixtureMode = activeUITestFixtureMode else { return }

        let workspace = AnimateCreateUITestFixtures.workspace(for: fixtureMode)
        let template = templates.first(where: { $0.id == workspace.video.template }) ?? AnimateVideoTemplate.birthdayMessage
        form = AnimateVideoSetupForm(
            template: template,
            occasion: workspace.video.occasion ?? "Birthday",
            recipient: "Ava",
            tone: AnimateVideoSetupTone(rawValue: workspace.video.tone ?? "") ?? .warm,
            tempo: AnimateVideoSetupTempo(rawValue: workspace.video.tempo ?? "") ?? .balanced,
            details: workspace.video.details ?? ""
        )
        isSignedIn = true
        balance = AnimateCreateUITestFixtures.balance(for: fixtureMode)
        isContinuingVideoCreation = true
        workflowActiveVideoId = workspace.video.id
        setupErrorMessage = nil
        selectedMedia = AnimateCreateUITestFixtures.selectedMedia
        mediaStatusMessage = L10n.string("create.media.fixture.synced")
        savedScenes = workspace.storyScenes
        generatedScenes = []
        videoDirectionStatusMessage = L10n.string("create.story.status.ready")
        lastPreparedVideoDirectionInputSignature = workspace.video.storyInputSignature
            ?? currentVideoDirectionInputSignature(momentId: workspace.video.id)
        activeWorkspace = workspace
        finalExport = workspace.latestArtifact(kind: "final_export")
        pendingGalleryVideo = nil
        latestFinalJob = workspace.latestRenderJob(kind: "final")
        switch fixtureMode {
        case .videoPlanReady, .videoPlanInsufficientCredits:
            renderPlan = AnimateCreateUITestFixtures.renderPlan(for: fixtureMode)
        case .storyReady, .finalQueued, .finalRunning, .full:
            renderPlan = nil
        }
        renderPlanInputSignature = renderPlan.map { currentFinalRenderInputSignature(momentId: $0.momentId) }
        finalRenderStatusMessage = {
            switch fixtureMode {
            case .storyReady:
                return nil
            case .videoPlanReady:
                return L10n.string("workflow.final.planReady")
            case .videoPlanInsufficientCredits:
                return L10n.string("create.final.blocker.insufficientCredits")
            case .finalQueued:
                return L10n.string("create.render.status.queued")
            case .finalRunning:
                return L10n.string("create.final.action.creating")
            case .full:
                return L10n.string("create.final.status.ready")
            }
        }()
        pendingFocus = .video
        continuationFocusHint = .video
    }

    var effectiveActiveWorkspace: AnimateWorkspace? {
        if let fixtureMode = activeUITestFixtureMode {
            return AnimateCreateUITestFixtures.workspace(for: fixtureMode)
        }
        return activeWorkspace
    }

    var effectiveSelectedMedia: [AnimateSelectedMedia] {
        usesCreateUITestFixture ? AnimateCreateUITestFixtures.selectedMedia : selectedMedia
    }

    var effectiveSavedScenes: [AnimateVideoDirectionScene] {
        effectiveActiveWorkspace?.storyScenes ?? savedScenes
    }

    var effectiveFinalExport: AnimateArtifact? {
        effectiveActiveWorkspace?.latestArtifact(kind: "final_export") ?? finalExport
    }

    private var canEditCreationOptions: Bool {
        if isBusy { return false }
        if effectiveActiveWorkspace?.canEditSetupDuringRender == false {
            return false
        }
        if effectiveFinalExport != nil || latestFinalJob != nil {
            return false
        }
        return true
    }

    var effectiveLatestFinalJob: AnimateRenderJob? {
        effectiveActiveWorkspace?.latestRenderJob(kind: "final") ?? latestFinalJob
    }

    var activeUITestFixtureMode: AnimateCreateUITestFixtures.Mode? {
        AnimateCreateUITestFixtures.mode
    }

    var usesCreateUITestFixture: Bool {
        activeUITestFixtureMode != nil
    }

    func resetActiveVideoCreation(force: Bool) {
        cancelOperations()
        isContinuingVideoCreation = false
        isLocalVideoCreationStarted = false
        pendingFocus = nil
        continuationFocusHint = nil
        videoCreationWorkflow?.resetVideoSetup(force: force)
        mediaUploadWorkflow?.reset(force: force)
        videoDirectionWorkflow?.reset(force: force)
        finalRenderWorkflow?.reset(force: force)
        clearWorkflowSnapshots()

        if let firstTemplate = templates.first {
            form = AnimateVideoSetupForm(template: firstTemplate)
        }
        selectedCreationStyle = creationStyles.first ?? AnimateVideoCreationStyle.launchStyles[0]
        selectedMusicPreset = selectedCreationStyle.defaultMusic
        autoStyleSuggestion = nil
        canUndoAutoStyleSuggestion = false
        autoStyleUndoSelection = nil
        autoStyleMediaSignature = nil
        lastPreparedVideoDirectionInputSignature = nil
        renderPlanInputSignature = nil
        pendingRenderPlanInputSignature = nil
        isPreparingFinalPlan = false
        hasExplicitMediaEditsAfterPreparedVideoDirection = false
        hasLocalSetupEdits = false
        hasUserStyleOverride = false
        hasUserLookOverride = false
        hasUserVoiceOverride = false
        applyStyleDefaults(selectedCreationStyle)
    }

    func clearFinalSessionAfterGalleryMove() {
        finalRenderWorkflow?.clearFinalSessionAfterGalleryMove()
        clearWorkflowSnapshots()
        finalVideoCommandState = .completedInGallery(L10n.string("workflow.final.movedToGallery"))
    }

    private func clearWorkflowSnapshots() {
        workflowActiveVideoId = nil
        activeWorkspace = nil
        selectedMedia = []
        savedScenes = []
        generatedScenes = []
        mediaStatusMessage = nil
        videoDirectionStatusMessage = nil
        finalExport = nil
        latestFinalJob = nil
        renderPlan = nil
        pendingGalleryVideo = nil
        canRetryFinalVideoDownload = false
        finalRenderStatusMessage = nil
        finalVideoCommandState = .idle
    }

    private func applyStyleDefaults(_ style: AnimateVideoCreationStyle, preserveUserOverrides: Bool = false) {
        let currentLook = form.look
        form.template = style.template
        form.theme = style.id
        form.look = preserveUserOverrides && hasUserLookOverride ? currentLook : .cartoon
        form.creationMode = .quick
        form.duration = .auto
        form.mediaUse = .aviPick
        form.occasion = style.title
        form.tone = style.tone
        form.tempo = style.tempo
    }

    func currentVideoDirectionInputSignature(momentId: String) -> String {
        AnimateVideoDirectionInputSignature.make(
            momentId: momentId,
            form: form,
            selectedMedia: currentVideoDirectionSignatureMedia()
        )
    }

    func currentVideoDirectionInputSignature(
        momentId: String,
        persistedMedia: [AnimateVideoDirectionMedia]?
    ) -> String {
        AnimateVideoDirectionInputSignature.make(
            momentId: momentId,
            form: form,
            selectedMedia: persistedMedia ?? currentVideoDirectionSignatureMedia()
        )
    }

    func preparedVideoDirectionComparisonInputSignature(momentId: String) -> String {
        if !hasExplicitMediaEditsAfterPreparedVideoDirection,
           let workspaceMedia = currentWorkspaceVideoDirectionSignatureMedia(),
           !workspaceMedia.isEmpty {
            return currentVideoDirectionInputSignature(momentId: momentId, persistedMedia: workspaceMedia)
        }

        return currentVideoDirectionInputSignature(momentId: momentId)
    }

    func currentFinalRenderInputSignature(momentId: String, removesWatermark: Bool = false) -> String {
        let input = currentFinalRenderInputSignatureSource(momentId: momentId, removesWatermark: removesWatermark)
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func currentFinalRenderInputSignatureSource(momentId: String, removesWatermark: Bool = false) -> String {
        let finalForm = effectiveFinalRenderForm()
        let mediaSignature = currentFinalRenderSignatureMedia()
            .map { "\($0.sortOrder):\($0.sourceLocalIdentifier):\($0.mediaKind)" }
            .joined(separator: "|")
        return [
            momentId,
            finalForm.creationMode.rawValue,
            finalForm.look.rawValue,
            finalForm.theme.rawValue,
            finalForm.tone.rawValue,
            finalForm.voiceProfile.rawValue,
            finalForm.voiceTone.rawValue,
            finalForm.duration.rawValue,
            finalForm.mediaUse.rawValue,
            finalForm.occasion.trimmingCharacters(in: .whitespacesAndNewlines),
            finalForm.details.trimmingCharacters(in: .whitespacesAndNewlines),
            mediaSignature,
            "\(removesWatermark)"
        ].joined(separator: "|")
    }

    func effectiveFinalRenderForm() -> AnimateVideoSetupForm {
        var finalForm = form
        finalForm.duration = .auto
        return finalForm
    }

    var currentRenderPlan: AnimateRenderPlanResponse? {
        currentRenderPlan(removesWatermark: false)
    }

    func currentRenderPlan(removesWatermark: Bool) -> AnimateRenderPlanResponse? {
        guard let renderPlan else { return nil }
        guard renderPlanInputSignature == currentFinalRenderInputSignature(
            momentId: renderPlan.momentId,
            removesWatermark: removesWatermark
        ) else {
            return nil
        }
        return renderPlan
    }

    func hasConfirmableRenderPlan(momentId: String) -> Bool {
        confirmableRenderPlan(momentId: momentId) != nil
    }

    func confirmableRenderPlan(momentId: String) -> AnimateRenderPlanResponse? {
        guard let renderPlan else { return nil }
        guard renderPlan.momentId == momentId, renderPlan.canCreateVideo else { return nil }
        return renderPlan
    }

    func beginFinalPlanPreparation(inputSignature: String) {
        pendingRenderPlanInputSignature = inputSignature
        isPreparingFinalPlan = true
    }

    func finishFinalPlanPreparation() {
        isPreparingFinalPlan = false
    }

    func beginFinalVideoCommand(_ state: AnimateFinalVideoCommandState) {
        finalVideoCommandState = state
    }

    func failFinalVideoCommand(_ message: String) {
        finalVideoCommandState = .failed(message)
        updateFinalRenderStatusMessage(message)
    }

    func clearFinalVideoCommandIfIdleSafe() {
        guard !finalVideoCommandState.isRunning else { return }
        finalVideoCommandState = .idle
    }

    func clearStaleRenderPlan() {
        renderPlan = nil
        renderPlanInputSignature = nil
        pendingRenderPlanInputSignature = nil
        finalRenderWorkflow?.clearRenderPlan()
    }

    func selectLook(_ look: AnimateVideoLook) {
        form.look = look
        if !hasUserVoiceOverride {
            form.voiceProfile = look.defaultVoiceProfile
        }
        hasUserLookOverride = true
        markLocalSetupEdited()
    }

    func updateVideoMessage(_ message: String) {
        form.details = String(message.prefix(180))
        markLocalSetupEdited()
    }

    func updateVoiceProfile(_ profile: AnimateVideoVoiceProfile) {
        form.voiceProfile = profile
        hasUserVoiceOverride = true
        markLocalSetupEdited()
    }

    func updateVoiceTone(_ tone: AnimateVideoVoiceTone) {
        form.voiceTone = tone
        markLocalSetupEdited()
    }

    private func markLocalSetupEdited() {
        hasLocalSetupEdits = true
        clearStaleRenderPlan()
    }

    func markPreparedVideoDirectionMediaEdited() {
        clearStaleRenderPlan()
        guard !savedScenes.isEmpty || !generatedScenes.isEmpty else { return }
        hasExplicitMediaEditsAfterPreparedVideoDirection = true
    }

    @discardableResult
    func recordPreparedVideoDirectionInputSignature(_ inputSignature: String, momentId: String) -> String {
        let recordedSignature: String
        if let workspaceSignature = effectiveActiveWorkspace?.video.storyInputSignature {
            recordedSignature = workspaceSignature
        } else if currentWorkspaceVideoDirectionSignatureMedia()?.isEmpty == false {
            recordedSignature = inputSignature
        } else {
            recordedSignature = currentVideoDirectionInputSignature(momentId: momentId)
        }
        lastPreparedVideoDirectionInputSignature = recordedSignature
        hasExplicitMediaEditsAfterPreparedVideoDirection = false
        hasLocalSetupEdits = false
        return recordedSignature
    }

    private func currentVideoDirectionSignatureMedia() -> [AnimateVideoDirectionMedia] {
        let localMedia = effectiveSelectedMedia
            .filter(\.selected)
            .sorted { $0.sortOrder < $1.sortOrder }
        if !localMedia.isEmpty {
            let syncedMediaBySourceIdentifier = (effectiveActiveWorkspace?.mediaAssets ?? []).reduce(into: [String: AnimateMediaAsset]()) {
                guard let sourceIdentifier = $1.platformMediaAssetId else { return }
                $0[sourceIdentifier] = $1
            }

            return localMedia
                .map {
                    let syncedMedia = syncedMediaBySourceIdentifier[$0.sourceLocalIdentifier]
                    return AnimateVideoDirectionMedia(
                        mediaAssetId: syncedMedia?.id ?? $0.id.uuidString,
                        mediaKind: syncedMedia?.kind ?? $0.kind,
                        sortOrder: $0.sortOrder,
                        selected: $0.selected,
                        moderationStatus: syncedMedia?.moderationStatus ?? "pending"
                    )
                }
        }

        return (effectiveActiveWorkspace?.mediaAssets ?? [])
            .filter(\.selected)
            .sorted { $0.sortOrder < $1.sortOrder }
            .map {
                AnimateVideoDirectionMedia(
                    mediaAssetId: $0.id,
                    mediaKind: $0.kind,
                    sortOrder: Int($0.sortOrder),
                    selected: $0.selected,
                    moderationStatus: $0.moderationStatus
                )
            }
    }

    private func currentFinalRenderSignatureMedia() -> [(sourceLocalIdentifier: String, mediaKind: String, sortOrder: Int)] {
        let localMedia = effectiveSelectedMedia
            .filter(\.selected)
            .sorted { $0.sortOrder < $1.sortOrder }
        if !localMedia.isEmpty {
            return localMedia.map {
                (
                    sourceLocalIdentifier: $0.sourceLocalIdentifier,
                    mediaKind: $0.kind,
                    sortOrder: $0.sortOrder
                )
            }
        }

        return (effectiveActiveWorkspace?.mediaAssets ?? [])
            .filter(\.selected)
            .sorted { $0.sortOrder < $1.sortOrder }
            .map {
                (
                    sourceLocalIdentifier: $0.platformMediaAssetId ?? $0.id,
                    mediaKind: $0.kind,
                    sortOrder: Int($0.sortOrder)
                )
            }
    }

    private func currentWorkspaceVideoDirectionSignatureMedia() -> [AnimateVideoDirectionMedia]? {
        let mediaAssets = effectiveActiveWorkspace?.mediaAssets ?? []
        guard !mediaAssets.isEmpty else { return nil }
        let selectedAssets = mediaAssets.filter(\.selected)
        return (selectedAssets.isEmpty ? mediaAssets : selectedAssets)
            .sorted { $0.sortOrder < $1.sortOrder }
            .map {
                AnimateVideoDirectionMedia(
                    mediaAssetId: $0.id,
                    mediaKind: $0.kind,
                    sortOrder: Int($0.sortOrder),
                    selected: $0.selected,
                    moderationStatus: $0.moderationStatus
                )
            }
    }
}

extension AnimateCreateViewModel {
    func applyAccountState(_ state: AnimateCreateAccountState) {
        guard !usesCreateUITestFixture else { return }
        isSignedIn = state.isSignedIn
        balance = state.balance
        creditBalanceLoadState = state.creditBalanceLoadState
        clearInsufficientCreditRenderPlanIfBalanceNowCovers(state.balance)
    }

    private func clearInsufficientCreditRenderPlanIfBalanceNowCovers(_ balance: AnimateCreditBalance) {
        guard let renderPlan,
              renderPlan.canCreateVideo == false,
              renderPlan.createVideoBlockers.contains("insufficient_credits"),
              balance.spendable >= renderPlan.plan.totalCreditCost
        else { return }

        clearStaleRenderPlan()
        updateFinalRenderStatusMessage(nil)
    }

    func applyVideoCreationState(_ state: AnimateCreateVideoCreationState) {
        guard !usesCreateUITestFixture else { return }
        let previousActiveVideoId = workflowActiveVideoId
        isCreatingVideo = state.isCreatingVideo
        workflowActiveVideoId = state.activeVideoId
        setupErrorMessage = state.setupErrorMessage

        if previousActiveVideoId == nil, state.activeVideoId != nil {
            pendingFocus = .media
            continuationFocusHint = nil
        }
    }

    func applyMediaUploadState(_ state: AnimateCreateMediaUploadState) {
        guard !usesCreateUITestFixture else { return }
        selectedMedia = state.selectedMedia
        mediaStatusMessage = state.statusMessage
        isImportingMedia = state.isImporting
        mediaImportProgress = state.importProgress
        updateAutoStyleSuggestion(for: state.selectedMedia)
    }

    func applyVideoDirectionState(_ state: AnimateCreateVideoDirectionState) {
        guard !usesCreateUITestFixture else { return }
        activeWorkspace = state.activeWorkspace
        syncFormWithActiveWorkspace(state.activeWorkspace)
        savedScenes = state.savedScenes
        generatedScenes = state.generatedScenes
        isPreparingVideoDirection = state.isPlanning

        let hasStoryScenes = !state.savedScenes.isEmpty || !state.generatedScenes.isEmpty
        if hasStoryScenes {
            reconcilePreparedVideoDirectionSignature()
            videoDirectionStatusMessage = nil
        } else {
            videoDirectionStatusMessage = state.statusMessage
        }
    }

    func updateVideoDirectionStatusMessage(_ message: String?) {
        videoDirectionStatusMessage = message
    }

    func updateSetupErrorMessage(_ message: String?) {
        setupErrorMessage = message
    }

    func updateFinalRenderStatusMessage(_ message: String?) {
        finalRenderStatusMessage = message
    }

    func applyFinalRenderState(_ state: AnimateCreateFinalRenderState) {
        guard !usesCreateUITestFixture else { return }
        finalExport = state.finalExport
        latestFinalJob = state.latestFinalJob
        renderPlan = state.renderPlan
        videoQuote = state.videoQuote
        if let renderPlan = state.renderPlan {
            renderPlanInputSignature = pendingRenderPlanInputSignature
                ?? currentFinalRenderInputSignature(momentId: renderPlan.momentId)
            pendingRenderPlanInputSignature = nil
        } else {
            renderPlanInputSignature = nil
        }
        pendingGalleryVideo = state.pendingGalleryVideo
        canRetryFinalVideoDownload = state.canRetryFinalVideoDownload
        finalRenderStatusMessage = normalizedFinalRenderStatusMessage(
            state.statusMessage,
            latestFinalJob: state.latestFinalJob
        )
        isGeneratingFinalRender = state.isGenerating
        reconcileFinalVideoCommandState(with: state)
    }

    private func syncFormWithActiveWorkspace(_ workspace: AnimateWorkspace?) {
        guard let video = workspace?.video else { return }
        guard video.id == activeVideoId else { return }
        guard let continuedForm = AnimateVideoSetupForm.continuing(video: video, templates: templates) else { return }
        if hasLocalSetupEdits {
            if continuedForm.matchesPersistedSetup(of: form) {
                hasLocalSetupEdits = false
                hasUserLookOverride = false
                hasUserVoiceOverride = false
            }
            return
        }

        form = continuedForm
        if let continuedStyle = creationStyles.first(where: { $0.template.id == continuedForm.template.id }) {
            selectedCreationStyle = continuedStyle
            selectedMusicPreset = continuedStyle.allowedMusic.first(where: { $0 == continuedStyle.defaultMusic }) ?? continuedStyle.defaultMusic
        }
        if let continuedStyle = creationStyles.first(where: { $0.id.rawValue == video.theme }) {
            selectedCreationStyle = continuedStyle
            selectedMusicPreset = continuedStyle.allowedMusic.first(where: { $0 == continuedStyle.defaultMusic }) ?? continuedStyle.defaultMusic
        }
    }

    private func reconcilePreparedVideoDirectionSignature() {
        guard !savedScenes.isEmpty || !generatedScenes.isEmpty else { return }
        guard let activeVideoId else { return }

        if let workspaceSignature = effectiveActiveWorkspace?.video.storyInputSignature {
            if lastPreparedVideoDirectionInputSignature != workspaceSignature {
                hasExplicitMediaEditsAfterPreparedVideoDirection = false
            }
            lastPreparedVideoDirectionInputSignature = workspaceSignature
            hasLocalSetupEdits = false
            hasUserLookOverride = false
            hasUserVoiceOverride = false
            return
        }

        if lastPreparedVideoDirectionInputSignature == nil || currentWorkspaceVideoDirectionSignatureMedia()?.isEmpty == false {
            lastPreparedVideoDirectionInputSignature = preparedVideoDirectionComparisonInputSignature(momentId: activeVideoId)
        }
    }

    private func updateAutoStyleSuggestion(for media: [AnimateSelectedMedia]) {
        guard canEditCreationOptions else { return }
        guard !videoDirectionSummary.hasScenes || hasExplicitMediaEditsAfterPreparedVideoDirection else { return }
        let signature = mediaSignature(media)
        guard signature != autoStyleMediaSignature else { return }
        autoStyleMediaSignature = signature
        guard let suggestion = AnimateMediaAutoStyleSuggester.suggest(
            media: media,
            styles: creationStyles
        ) else {
            autoStyleSuggestion = nil
            return
        }
        guard let suggestedStyle = creationStyles.first(where: { $0.id == suggestion.styleID && $0.isEnabled }) else {
            autoStyleSuggestion = nil
            return
        }

        autoStyleSuggestion = suggestion
        guard !hasUserStyleOverride else { return }
        selectedCreationStyle = suggestedStyle
        selectedMusicPreset = suggestion.musicPreset
        applyStyleDefaults(suggestedStyle)
        form.tone = AnimateVideoSetupTone(musicPreset: suggestion.musicPreset)
    }

    private func mediaSignature(_ media: [AnimateSelectedMedia]) -> String {
        media
            .map { "\($0.id.uuidString):\($0.sha256):\($0.sortOrder)" }
            .joined(separator: "|")
    }

    private var finalRenderAlertMessage: String? {
        guard let finalRenderStatusMessage else { return nil }
        guard !hasActiveFinalRenderJob else { return nil }
        return finalRenderStatusMessage
    }

    private var finalVideoCommandFailureMessage: String? {
        guard case let .failed(message) = finalVideoCommandState else { return nil }
        return message
    }

    private var hasActiveFinalRenderJob: Bool {
        guard let latestFinalJob else { return false }
        return latestFinalJob.status == "queued" || latestFinalJob.status == "running"
    }

    private func normalizedFinalRenderStatusMessage(
        _ message: String?,
        latestFinalJob: AnimateRenderJob?
    ) -> String? {
        guard let message,
              Self.isUserFacingErrorMessage(message),
              let latestFinalJob,
              latestFinalJob.status == "queued" || latestFinalJob.status == "running"
        else {
            return message
        }

        return latestFinalJob.userMessage
    }

    private func reconcileFinalVideoCommandState(with state: AnimateCreateFinalRenderState) {
        if state.pendingGalleryVideo != nil {
            finalVideoCommandState = .completedDownloadReady(
                state.statusMessage ?? L10n.string("workflow.final.savedLocal")
            )
            return
        }
        if state.finalExport != nil {
            finalVideoCommandState = .completedDownloadReady(
                state.statusMessage ?? L10n.string("create.primary.finalReady")
            )
            return
        }
        if let latestFinalJob = state.latestFinalJob,
           latestFinalJob.status == "queued" || latestFinalJob.status == "running" {
            finalVideoCommandState = .queued(
                latestFinalJob.userMessage
                    ?? state.statusMessage
                    ?? L10n.string("workflow.final.creatingVideo")
            )
            return
        }
        if state.isGenerating {
            finalVideoCommandState = .confirming(
                state.statusMessage ?? L10n.string("workflow.final.creatingVideo")
            )
            return
        }
        if let statusMessage = state.statusMessage,
           Self.isUserFacingErrorMessage(statusMessage),
           finalVideoCommandState.isRunning {
            finalVideoCommandState = .failed(statusMessage)
            return
        }
        if case .failed = finalVideoCommandState {
            return
        }
        if case .completedDownloadReady = finalVideoCommandState {
            return
        }
        if case .completedInGallery = finalVideoCommandState {
            return
        }
        finalVideoCommandState = .idle
    }

    private static func isUserFacingErrorMessage(_ message: String) -> Bool {
        let lowercased = message.lowercased()
        return lowercased.contains("couldn’t")
            || lowercased.contains("couldn't")
            || lowercased.contains("failed")
            || lowercased.contains("not configured")
            || lowercased.contains("not available")
            || lowercased.contains("sign in again")
            || lowercased.contains("try again")
    }
}
