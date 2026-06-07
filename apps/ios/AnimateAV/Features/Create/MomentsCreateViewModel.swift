import Combine
import CryptoKit
import Foundation

enum MomentsFinalVideoCommandState: Equatable {
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
final class MomentsCreateViewModel: ObservableObject {
    @Published private(set) var isSignedIn = false
    @Published private(set) var balance = MomentsCreditBalance.empty
    @Published private(set) var creditBalanceLoadState = MomentsCreditBalanceLoadState.signedOut
    @Published private(set) var templates = MomentTemplate.launchTemplates
    @Published private(set) var creationStyles = MomentCreationStyle.launchStyles
    @Published var selectedCreationStyle = MomentCreationStyle.launchStyles[0]
    @Published var selectedMusicPreset = MomentCreationStyle.launchStyles[0].defaultMusic
    @Published var form = MomentSetupForm(template: MomentTemplate.launchTemplates[0])
    @Published private(set) var isCreatingMoment = false
    @Published private(set) var isContinuingMoment = false
    @Published var isLocalMomentStarted = false
    @Published private(set) var workflowActiveMomentId: String?
    @Published private(set) var setupErrorMessage: String?
    @Published private(set) var selectedMedia: [MomentsSelectedMedia] = []
    @Published private(set) var mediaStatusMessage: String?
    @Published private(set) var isImportingMedia = false
    @Published private(set) var mediaImportProgress: MomentsMediaImportProgress?
    @Published private(set) var autoStyleSuggestion: MomentsMediaAutoStyleSuggestion?
    @Published private(set) var canUndoAutoStyleSuggestion = false
    @Published private(set) var savedScenes: [MomentStoryScene] = []
    @Published private(set) var generatedScenes: [MomentsStorySceneResponse] = []
    @Published private(set) var storyStatusMessage: String?
    @Published private(set) var isPlanningStory = false
    @Published var isPreparingStory = false
    @Published private(set) var activeWorkspace: MomentWorkspace?
    @Published private(set) var finalExport: MomentArtifact?
    @Published private(set) var latestFinalJob: MomentRenderJob?
    @Published private(set) var renderPlan: MomentsRenderPlanResponse?
    @Published private(set) var videoQuote: AnimateVideoQuoteResponse?
    @Published private(set) var pendingGalleryVideo: MomentsGalleryVideoRecord?
    @Published private(set) var canRetryFinalVideoDownload = false
    @Published private(set) var finalRenderStatusMessage: String?
    @Published private(set) var isGeneratingFinalRender = false
    @Published private(set) var isPreparingFinalPlan = false
    @Published private(set) var finalVideoCommandState = MomentsFinalVideoCommandState.idle
    @Published var pendingFocus: MomentsContinuationFocus?
    @Published private(set) var continuationFocusHint: MomentsContinuationFocus?
    @Published var mediaPickerOpenRequest = 0
    @Published var albumPickerOpenRequest = 0

    private(set) var momentCreationWorkflow: MomentCreationWorkflow?
    private(set) var mediaUploadWorkflow: MediaUploadWorkflow?
    private(set) var storyWorkflow: StoryWorkflow?
    private(set) var finalRenderWorkflow: FinalRenderWorkflow?
    let operationRunner = MomentsCreateOperationRunner()
    var cancellables = Set<AnyCancellable>()
    private var autoStyleMediaSignature: String?
    var lastPreparedStoryInputSignature: String?
    private var renderPlanInputSignature: String?
    private var pendingRenderPlanInputSignature: String?
    private var hasExplicitMediaEditsAfterPreparedStory = false
    private var hasLocalSetupEdits = false
    private var hasUserStyleOverride = false
    private var hasUserLookOverride = false
    private var hasUserDurationOverride = false
    private var autoStyleUndoSelection: (style: MomentCreationStyle, musicPreset: MomentMusicPreset, form: MomentSetupForm)?

    var activeMoment: InProgressMoment? {
        if let fixtureMode = activeUITestFixtureMode {
            return MomentsCreateUITestFixtures.moment(for: fixtureMode)
        }

        return activeWorkspace?.moment
    }

    var activeMomentId: String? {
        activeMoment?.id ?? workflowActiveMomentId
    }

    var hasMomentWorkspace: Bool {
        activeMomentId != nil || isLocalMomentStarted
    }

    var hasRecoverableMomentContext: Bool {
        activeMomentId != nil
            || !selectedMedia.isEmpty
            || isImportingMedia
            || isPlanningStory
            || !savedScenes.isEmpty
            || !generatedScenes.isEmpty
            || finalExport != nil
            || latestFinalJob != nil
            || renderPlan != nil
    }

    var hasLocalMomentWorkspace: Bool {
        activeMomentId == nil && isLocalMomentStarted
    }

    var hasPendingLocalSetupEdits: Bool {
        hasLocalSetupEdits
    }

    var workflowErrorAlertMessage: String? {
        [
            setupErrorMessage,
            mediaStatusMessage,
            storyStatusMessage,
            finalVideoCommandFailureMessage,
            finalRenderAlertMessage
        ]
            .compactMap(\.self)
            .first(where: Self.isUserFacingErrorMessage)
    }

    func bind(
        accountStateProvider: any MomentsAccountStateProviding,
        momentCreationWorkflow: MomentCreationWorkflow,
        mediaUploadWorkflow: MediaUploadWorkflow,
        storyWorkflow: StoryWorkflow,
        finalRenderWorkflow: FinalRenderWorkflow
    ) {
        cancelOperations()
        self.momentCreationWorkflow = momentCreationWorkflow
        self.mediaUploadWorkflow = mediaUploadWorkflow
        self.storyWorkflow = storyWorkflow
        self.finalRenderWorkflow = finalRenderWorkflow
        templates = momentCreationWorkflow.launchTemplates
        creationStyles = MomentCreationStyle.launchStyles
        selectedCreationStyle = MomentCreationStyle.launchStyles[0]
        selectedMusicPreset = selectedCreationStyle.defaultMusic
        form = MomentSetupForm(template: momentCreationWorkflow.launchTemplates[0])
        canUndoAutoStyleSuggestion = false
        autoStyleUndoSelection = nil
        applyStyleDefaults(selectedCreationStyle)
        cancellables.removeAll()

        bindWorkflowState(
            accountStateProvider: accountStateProvider,
            momentCreationWorkflow: momentCreationWorkflow,
            mediaUploadWorkflow: mediaUploadWorkflow,
            storyWorkflow: storyWorkflow,
            finalRenderWorkflow: finalRenderWorkflow
        )
    }

    func selectTemplate(id: MomentTemplateID) {
        guard !isSetupLocked else { return }
        guard let template = templates.first(where: { $0.id == id }) else { return }
        form.template = template
        markLocalSetupEdited()
    }

    func selectCreationStyle(_ style: MomentCreationStyle) {
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

    func selectMusicPreset(_ preset: MomentMusicPreset) {
        guard selectedCreationStyle.allowedMusic.contains(preset) else { return }
        hasUserStyleOverride = true
        canUndoAutoStyleSuggestion = false
        autoStyleUndoSelection = nil
        selectedMusicPreset = preset
        form.tone = MomentSetupTone(musicPreset: preset)
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
        form.tone = MomentSetupTone(musicPreset: suggestion.musicPreset)
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
        resetActiveMoment(force: true)
    }

    func prepareNewMomentCreation() {
        isContinuingMoment = false
        continuationFocusHint = nil
        isLocalMomentStarted = false
        hasLocalSetupEdits = false
        hasUserLookOverride = false
    }

    func continueMoment(_ moment: InProgressMoment, focus: MomentsContinuationFocus = .moment) {
        cancelOperations()
        isContinuingMoment = true
        isLocalMomentStarted = false
        hasLocalSetupEdits = false
        hasUserLookOverride = false
        pendingFocus = focus
        continuationFocusHint = focus

        if let continuedForm = MomentSetupForm.continuing(moment: moment, templates: templates) {
            form = continuedForm
        }

        momentCreationWorkflow?.continueMoment(moment)
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

    func consumeAlbumPickerOpenRequest() {
        albumPickerOpenRequest = 0
    }

    func applyUITestCreateFixture() {
        guard let fixtureMode = activeUITestFixtureMode else { return }

        let workspace = MomentsCreateUITestFixtures.workspace(for: fixtureMode)
        let template = templates.first(where: { $0.id == workspace.moment.template }) ?? MomentTemplate.birthdayMessage
        form = MomentSetupForm(
            template: template,
            occasion: workspace.moment.occasion ?? "Birthday",
            recipient: "Ava",
            tone: MomentSetupTone(rawValue: workspace.moment.tone ?? "") ?? .warm,
            tempo: MomentSetupTempo(rawValue: workspace.moment.tempo ?? "") ?? .balanced,
            details: workspace.moment.details ?? ""
        )
        isSignedIn = true
        balance = MomentsCreateUITestFixtures.balance(for: fixtureMode)
        isContinuingMoment = true
        workflowActiveMomentId = workspace.moment.id
        setupErrorMessage = nil
        selectedMedia = MomentsCreateUITestFixtures.selectedMedia
        mediaStatusMessage = L10n.string("create.media.fixture.synced")
        savedScenes = workspace.storyScenes
        generatedScenes = []
        storyStatusMessage = L10n.string("create.story.status.ready")
        lastPreparedStoryInputSignature = workspace.moment.storyInputSignature
            ?? currentStoryInputSignature(momentId: workspace.moment.id)
        activeWorkspace = workspace
        finalExport = workspace.latestArtifact(kind: "final_export")
        pendingGalleryVideo = nil
        latestFinalJob = workspace.latestRenderJob(kind: "final")
        switch fixtureMode {
        case .videoPlanReady, .videoPlanInsufficientCredits:
            renderPlan = MomentsCreateUITestFixtures.renderPlan(for: fixtureMode)
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
        pendingFocus = .moment
        continuationFocusHint = .moment
    }

    var effectiveActiveWorkspace: MomentWorkspace? {
        if let fixtureMode = activeUITestFixtureMode {
            return MomentsCreateUITestFixtures.workspace(for: fixtureMode)
        }
        return activeWorkspace
    }

    var effectiveSelectedMedia: [MomentsSelectedMedia] {
        usesCreateUITestFixture ? MomentsCreateUITestFixtures.selectedMedia : selectedMedia
    }

    var effectiveSavedScenes: [MomentStoryScene] {
        effectiveActiveWorkspace?.storyScenes ?? savedScenes
    }

    var effectiveFinalExport: MomentArtifact? {
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

    var effectiveLatestFinalJob: MomentRenderJob? {
        effectiveActiveWorkspace?.latestRenderJob(kind: "final") ?? latestFinalJob
    }

    var activeUITestFixtureMode: MomentsCreateUITestFixtures.Mode? {
        MomentsCreateUITestFixtures.mode
    }

    var usesCreateUITestFixture: Bool {
        activeUITestFixtureMode != nil
    }

    func resetActiveMoment(force: Bool) {
        cancelOperations()
        isContinuingMoment = false
        isLocalMomentStarted = false
        pendingFocus = nil
        continuationFocusHint = nil
        momentCreationWorkflow?.resetMomentSetup(force: force)
        mediaUploadWorkflow?.reset(force: force)
        storyWorkflow?.reset(force: force)
        finalRenderWorkflow?.reset(force: force)
        clearWorkflowSnapshots()

        if let firstTemplate = templates.first {
            form = MomentSetupForm(template: firstTemplate)
        }
        selectedCreationStyle = creationStyles.first ?? MomentCreationStyle.launchStyles[0]
        selectedMusicPreset = selectedCreationStyle.defaultMusic
        autoStyleSuggestion = nil
        canUndoAutoStyleSuggestion = false
        autoStyleUndoSelection = nil
        autoStyleMediaSignature = nil
        lastPreparedStoryInputSignature = nil
        renderPlanInputSignature = nil
        pendingRenderPlanInputSignature = nil
        isPreparingFinalPlan = false
        hasExplicitMediaEditsAfterPreparedStory = false
        hasLocalSetupEdits = false
        hasUserStyleOverride = false
        hasUserLookOverride = false
        hasUserDurationOverride = false
        applyStyleDefaults(selectedCreationStyle)
    }

    func clearFinalSessionAfterGalleryMove() {
        finalRenderWorkflow?.clearFinalSessionAfterGalleryMove()
        clearWorkflowSnapshots()
        finalVideoCommandState = .completedInGallery(L10n.string("workflow.final.movedToGallery"))
    }

    private func clearWorkflowSnapshots() {
        workflowActiveMomentId = nil
        activeWorkspace = nil
        selectedMedia = []
        savedScenes = []
        generatedScenes = []
        mediaStatusMessage = nil
        storyStatusMessage = nil
        finalExport = nil
        latestFinalJob = nil
        renderPlan = nil
        pendingGalleryVideo = nil
        canRetryFinalVideoDownload = false
        finalRenderStatusMessage = nil
        finalVideoCommandState = .idle
    }

    private func applyStyleDefaults(_ style: MomentCreationStyle, preserveUserOverrides: Bool = false) {
        let currentLook = form.look
        let currentDuration = form.duration
        form.template = style.template
        form.theme = style.id
        form.look = preserveUserOverrides && hasUserLookOverride ? currentLook : .real
        form.creationMode = .quick
        form.duration = preserveUserOverrides && hasUserDurationOverride ? currentDuration : .short
        if !preserveUserOverrides {
            hasUserDurationOverride = false
        }
        form.mediaUse = .aviPick
        form.occasion = style.title
        form.tone = style.tone
        form.tempo = style.tempo
    }

    func currentStoryInputSignature(momentId: String) -> String {
        MomentsStoryInputSignature.make(
            momentId: momentId,
            form: form,
            selectedMedia: currentStorySignatureMedia()
        )
    }

    func currentStoryInputSignature(
        momentId: String,
        persistedMedia: [MomentsStoryMedia]?
    ) -> String {
        MomentsStoryInputSignature.make(
            momentId: momentId,
            form: form,
            selectedMedia: persistedMedia ?? currentStorySignatureMedia()
        )
    }

    func preparedStoryComparisonInputSignature(momentId: String) -> String {
        if !hasExplicitMediaEditsAfterPreparedStory,
           let workspaceMedia = currentWorkspaceStorySignatureMedia(),
           !workspaceMedia.isEmpty {
            return currentStoryInputSignature(momentId: momentId, persistedMedia: workspaceMedia)
        }

        return currentStoryInputSignature(momentId: momentId)
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
            finalForm.duration.rawValue,
            finalForm.mediaUse.rawValue,
            finalForm.occasion.trimmingCharacters(in: .whitespacesAndNewlines),
            finalForm.details.trimmingCharacters(in: .whitespacesAndNewlines),
            mediaSignature,
            "\(removesWatermark)"
        ].joined(separator: "|")
    }

    func effectiveFinalRenderForm() -> MomentSetupForm {
        var finalForm = form
        if !hasUserDurationOverride {
            finalForm.duration = .short
        }
        return finalForm
    }

    var currentRenderPlan: MomentsRenderPlanResponse? {
        currentRenderPlan(removesWatermark: false)
    }

    func currentRenderPlan(removesWatermark: Bool) -> MomentsRenderPlanResponse? {
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

    func confirmableRenderPlan(momentId: String) -> MomentsRenderPlanResponse? {
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

    func beginFinalVideoCommand(_ state: MomentsFinalVideoCommandState) {
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

    func selectDuration(_ duration: MomentDuration) {
        form.duration = duration
        hasUserDurationOverride = true
        markLocalSetupEdited()
    }

    func selectLook(_ look: MomentLook) {
        form.look = look
        hasUserLookOverride = true
        markLocalSetupEdited()
    }

    private func markLocalSetupEdited() {
        hasLocalSetupEdits = true
        clearStaleRenderPlan()
    }

    func markPreparedStoryMediaEdited() {
        clearStaleRenderPlan()
        guard !savedScenes.isEmpty || !generatedScenes.isEmpty else { return }
        hasExplicitMediaEditsAfterPreparedStory = true
    }

    @discardableResult
    func recordPreparedStoryInputSignature(_ inputSignature: String, momentId: String) -> String {
        let recordedSignature: String
        if let workspaceSignature = effectiveActiveWorkspace?.moment.storyInputSignature {
            recordedSignature = workspaceSignature
        } else if currentWorkspaceStorySignatureMedia()?.isEmpty == false {
            recordedSignature = inputSignature
        } else {
            recordedSignature = currentStoryInputSignature(momentId: momentId)
        }
        lastPreparedStoryInputSignature = recordedSignature
        hasExplicitMediaEditsAfterPreparedStory = false
        hasLocalSetupEdits = false
        return recordedSignature
    }

    private func currentStorySignatureMedia() -> [MomentsStoryMedia] {
        let localMedia = effectiveSelectedMedia
            .filter(\.selected)
            .sorted { $0.sortOrder < $1.sortOrder }
        if !localMedia.isEmpty {
            let syncedMediaBySourceIdentifier = (effectiveActiveWorkspace?.mediaAssets ?? []).reduce(into: [String: MomentMediaAsset]()) {
                guard let sourceIdentifier = $1.platformMediaAssetId else { return }
                $0[sourceIdentifier] = $1
            }

            return localMedia
                .map {
                    let syncedMedia = syncedMediaBySourceIdentifier[$0.sourceLocalIdentifier]
                    return MomentsStoryMedia(
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
                MomentsStoryMedia(
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

    private func currentWorkspaceStorySignatureMedia() -> [MomentsStoryMedia]? {
        let mediaAssets = effectiveActiveWorkspace?.mediaAssets ?? []
        guard !mediaAssets.isEmpty else { return nil }
        let selectedAssets = mediaAssets.filter(\.selected)
        return (selectedAssets.isEmpty ? mediaAssets : selectedAssets)
            .sorted { $0.sortOrder < $1.sortOrder }
            .map {
                MomentsStoryMedia(
                    mediaAssetId: $0.id,
                    mediaKind: $0.kind,
                    sortOrder: Int($0.sortOrder),
                    selected: $0.selected,
                    moderationStatus: $0.moderationStatus
                )
            }
    }
}

extension MomentsCreateViewModel {
    func applyAccountState(_ state: MomentsCreateAccountState) {
        guard !usesCreateUITestFixture else { return }
        isSignedIn = state.isSignedIn
        balance = state.balance
        creditBalanceLoadState = state.creditBalanceLoadState
        clearInsufficientCreditRenderPlanIfBalanceNowCovers(state.balance)
    }

    private func clearInsufficientCreditRenderPlanIfBalanceNowCovers(_ balance: MomentsCreditBalance) {
        guard let renderPlan,
              renderPlan.canCreateVideo == false,
              renderPlan.createVideoBlockers.contains("insufficient_credits"),
              balance.spendable >= renderPlan.plan.totalCreditCost
        else { return }

        clearStaleRenderPlan()
        updateFinalRenderStatusMessage(nil)
    }

    func applyMomentCreationState(_ state: MomentsCreateMomentCreationState) {
        guard !usesCreateUITestFixture else { return }
        let previousActiveMomentId = workflowActiveMomentId
        isCreatingMoment = state.isCreatingMoment
        workflowActiveMomentId = state.activeMomentId
        setupErrorMessage = state.setupErrorMessage

        if previousActiveMomentId == nil, state.activeMomentId != nil {
            pendingFocus = .media
            continuationFocusHint = nil
        }
    }

    func applyMediaUploadState(_ state: MomentsCreateMediaUploadState) {
        guard !usesCreateUITestFixture else { return }
        selectedMedia = state.selectedMedia
        mediaStatusMessage = state.statusMessage
        isImportingMedia = state.isImporting
        mediaImportProgress = state.importProgress
        updateAutoStyleSuggestion(for: state.selectedMedia)
    }

    func applyStoryState(_ state: MomentsCreateStoryState) {
        guard !usesCreateUITestFixture else { return }
        activeWorkspace = state.activeWorkspace
        syncFormWithActiveWorkspace(state.activeWorkspace)
        savedScenes = state.savedScenes
        generatedScenes = state.generatedScenes
        isPlanningStory = state.isPlanning

        let hasStoryScenes = !state.savedScenes.isEmpty || !state.generatedScenes.isEmpty
        if hasStoryScenes {
            reconcilePreparedStorySignature()
            storyStatusMessage = nil
        } else {
            storyStatusMessage = state.statusMessage
        }
    }

    func updateStoryStatusMessage(_ message: String?) {
        storyStatusMessage = message
    }

    func updateSetupErrorMessage(_ message: String?) {
        setupErrorMessage = message
    }

    func updateFinalRenderStatusMessage(_ message: String?) {
        finalRenderStatusMessage = message
    }

    func applyFinalRenderState(_ state: MomentsCreateFinalRenderState) {
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

    private func syncFormWithActiveWorkspace(_ workspace: MomentWorkspace?) {
        guard let moment = workspace?.moment else { return }
        guard moment.id == activeMomentId else { return }
        guard let continuedForm = MomentSetupForm.continuing(moment: moment, templates: templates) else { return }
        if hasLocalSetupEdits {
            if continuedForm.matchesPersistedSetup(of: form) {
                hasLocalSetupEdits = false
                hasUserLookOverride = false
                hasUserDurationOverride = false
            }
            return
        }

        form = continuedForm
        hasUserDurationOverride = false
        if let continuedStyle = creationStyles.first(where: { $0.template.id == continuedForm.template.id }) {
            selectedCreationStyle = continuedStyle
            selectedMusicPreset = continuedStyle.allowedMusic.first(where: { $0 == continuedStyle.defaultMusic }) ?? continuedStyle.defaultMusic
        }
        if let continuedStyle = creationStyles.first(where: { $0.id.rawValue == moment.theme }) {
            selectedCreationStyle = continuedStyle
            selectedMusicPreset = continuedStyle.allowedMusic.first(where: { $0 == continuedStyle.defaultMusic }) ?? continuedStyle.defaultMusic
        }
    }

    private func reconcilePreparedStorySignature() {
        guard !savedScenes.isEmpty || !generatedScenes.isEmpty else { return }
        guard let activeMomentId else { return }

        if let workspaceSignature = effectiveActiveWorkspace?.moment.storyInputSignature {
            if lastPreparedStoryInputSignature != workspaceSignature {
                hasExplicitMediaEditsAfterPreparedStory = false
            }
            lastPreparedStoryInputSignature = workspaceSignature
            hasLocalSetupEdits = false
            hasUserLookOverride = false
            return
        }

        if lastPreparedStoryInputSignature == nil || currentWorkspaceStorySignatureMedia()?.isEmpty == false {
            lastPreparedStoryInputSignature = preparedStoryComparisonInputSignature(momentId: activeMomentId)
        }
    }

    private func updateAutoStyleSuggestion(for media: [MomentsSelectedMedia]) {
        guard canEditCreationOptions else { return }
        guard !storySummary.hasScenes || hasExplicitMediaEditsAfterPreparedStory else { return }
        let signature = mediaSignature(media)
        guard signature != autoStyleMediaSignature else { return }
        autoStyleMediaSignature = signature
        guard let suggestion = MomentsMediaAutoStyleSuggester.suggest(
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
        form.tone = MomentSetupTone(musicPreset: suggestion.musicPreset)
    }

    private func mediaSignature(_ media: [MomentsSelectedMedia]) -> String {
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
        latestFinalJob: MomentRenderJob?
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

    private func reconcileFinalVideoCommandState(with state: MomentsCreateFinalRenderState) {
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
