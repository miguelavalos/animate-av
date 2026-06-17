import AVAppShellFoundation
import AVBrandFoundation
import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

struct AnimateCreateWorkflowContent: View {
    @ObservedObject var viewModel: AnimateCreateViewModel
    @Binding var pickerItems: [PhotosPickerItem]
    let startSignInFlow: () -> Void
    let openCredits: () -> Void
    let finishFinalVideoToGallery: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.workflowPresentation.showsMediaFirstWorkspace {
                AnimateCreateMediaFirstWorkspace(
                    form: $viewModel.form,
                    selectedStyle: viewModel.selectedCreationStyle,
                    autoStyleSuggestion: viewModel.autoStyleSuggestion,
                    canUndoAutoStyleSuggestion: viewModel.canUndoAutoStyleSuggestion,
                    styles: viewModel.creationStyles,
                    selectedMusicPreset: viewModel.selectedMusicPreset,
                    selectedLook: viewModel.selectedVideoLook,
                    presentation: viewModel.workflowPresentation,
                    isPreparingVideoDirectionAction: viewModel.isPreparingVideoDirectionAction,
                    pickerItems: $pickerItems,
                    importPickerItems: viewModel.importPickerItems,
                    replacePickerItems: viewModel.replaceMedia,
                    removeMedia: viewModel.removeMedia,
                    updateMediaPhotoData: viewModel.updateMedia,
                    restoreOriginalPhotoData: viewModel.restoreOriginalMedia,
                    restoreLocalMediaForEditing: viewModel.restoreLocalMediaForEditing,
                    selectStyle: viewModel.selectCreationStyle,
                    selectLook: viewModel.selectLook,
                    selectMusicPreset: viewModel.selectMusicPreset,
                    selectMovementDirection: viewModel.selectMovementDirection,
                    selectVisualDirection: viewModel.selectVisualDirection,
                    updateAnimationDirection: viewModel.updateAnimationDirection,
                    useAutoStyleSuggestion: viewModel.useAutoStyleSuggestion,
                    undoAutoStyleSuggestion: viewModel.undoAutoStyleSuggestion,
                    openPickerRequest: 0,
                    consumeOpenPickerRequest: {},
                    updateMessage: viewModel.updateVideoMessage,
                    discardVideoCreation: viewModel.discardVideoCreation,
                    cancelLocalVideoCreationDraft: viewModel.cancelLocalVideoCreationDraft,
                    startSignInFlow: startSignInFlow,
                    openCredits: openCredits,
                    prepareVideoDirection: viewModel.prepareVideoDirection,
                    prepareFinalRenderPlan: { removesWatermark in
                        viewModel.prepareFinalVideoPlanFromCurrentSelection(removesWatermark: removesWatermark)
                    },
                    submitFinalVideoConfirmation: viewModel.submitFinalVideoConfirmation,
                    retryFinalVideoDownload: viewModel.retryFinalVideoDownload,
                    finishFinalVideoToGallery: finishFinalVideoToGallery
                )
            } else {
                EmptyView()
            }
        }
    }
}

private struct AnimateCreateMediaFirstWorkspace: View {
    @Binding var form: AnimateVideoSetupForm
    let selectedStyle: AnimateVideoCreationStyle
    let autoStyleSuggestion: AnimateMediaAutoStyleSuggestion?
    let canUndoAutoStyleSuggestion: Bool
    let styles: [AnimateVideoCreationStyle]
    let selectedMusicPreset: AnimateVideoMusicPreset
    let selectedLook: AnimateVideoLook?
    let presentation: AnimateCreateWorkflowPresentation
    let isPreparingVideoDirectionAction: Bool
    @Binding var pickerItems: [PhotosPickerItem]
    let importPickerItems: ([PhotosPickerItem]) -> Void
    let replacePickerItems: (AnimateSelectedMedia, [PhotosPickerItem]) -> Void
    let removeMedia: (AnimateSelectedMedia) -> Void
    let updateMediaPhotoData: (AnimateSelectedMedia, Data) -> Void
    let restoreOriginalPhotoData: (AnimateSelectedMedia) -> Void
    let restoreLocalMediaForEditing: () -> Void
    let selectStyle: (AnimateVideoCreationStyle) -> Void
    let selectLook: (AnimateVideoLook) -> Void
    let selectMusicPreset: (AnimateVideoMusicPreset) -> Void
    let selectMovementDirection: (AnimateVideoMovementDirection) -> Void
    let selectVisualDirection: (AnimateVisualDirectionMode, String?) -> Void
    let updateAnimationDirection: (String) -> Void
    let useAutoStyleSuggestion: () -> Void
    let undoAutoStyleSuggestion: () -> Void
    let openPickerRequest: Int
    let consumeOpenPickerRequest: () -> Void
    let updateMessage: (String) -> Void
    let discardVideoCreation: () -> Void
    let cancelLocalVideoCreationDraft: () -> Void
    let startSignInFlow: () -> Void
    let openCredits: () -> Void
    let prepareVideoDirection: () -> Void
    let prepareFinalRenderPlan: (Bool) -> Void
    let submitFinalVideoConfirmation: (Bool) -> Void
    let retryFinalVideoDownload: () -> Void
    let finishFinalVideoToGallery: () -> Void

    @State private var showsThemeChooser = false
    @State private var showsLookChooser = false
    @State private var showsCreateVideoConfirmation = false
    @State private var waitsForFinalRenderPlan = false
    @State private var showsDiscardVideoConfirmation = false
    @State private var showsCompactPhotoPicker = false
    @State private var showsCompactMediaManager = false
    @State private var shouldOpenMediaManagerAfterImport = false
    @State private var isReviewingImportedMedia = false
    @State private var handledOpenPickerRequest = 0
    @State private var handledOpenAlbumRequest = 0
    @State private var continueGuidedFlowRequest = 0
    @State private var isVideoSetupGuideComplete = false
    @State private var mediaPendingReplacement: AnimateSelectedMedia?

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: showsWorkflowDashboard ? 10 : 12) {
                    if showsFinalVideoCompletion {
                        AnimateCreateFinalVideoReadyScene(
                            presentation: presentation,
                            viewInGallery: finishFinalVideoToGallery
                        )
                            .padding(.top, 28)
                    } else if showsFinalVideoRecovery {
                        AnimateCreateFinalVideoRecoveryScene(
                            presentation: presentation,
                            retryVideoCreation: primaryFinalRenderAction,
                            choosePhoto: presentCompactPhotoPicker,
                            discardVideoCreation: { showsDiscardVideoConfirmation = true }
                        )
                        .padding(.top, 28)
                    } else if presentation.isFinalRenderEditingLocked {
                        AnimateCreateLockedFinalRenderScene(presentation: presentation)
                            .padding(.top, 28)
                    } else {
                        AnimateCreateVideoHeader()

                        AnimateCreateCompactAviGuide(
                            presentation: presentation,
                            isVideoSetupGuideComplete: isVideoSetupGuideComplete
                        )
                    }

                    if showsFinalVideoCompletion || presentation.isFinalRenderEditingLocked {
                        EmptyView()
                    } else if hasMediaSelection {
                        AnimateCreateVideoDirectionCard(
                            presentation: presentation,
                            form: $form,
                            pickerItems: $pickerItems,
                            selectedStyle: selectedStyle,
                            selectedMusicPreset: selectedMusicPreset,
                            selectedLook: selectedLook,
                            autoStyleSuggestion: autoStyleSuggestion,
                            canUndoAutoStyleSuggestion: canUndoAutoStyleSuggestion,
                            styles: styles,
                            useAutoStyleSuggestion: useAutoStyleSuggestion,
                            undoAutoStyleSuggestion: undoAutoStyleSuggestion,
                            selectStyle: selectStyle,
                            selectLook: selectLook,
                            selectMovementDirection: selectMovementDirection,
                            selectVisualDirection: selectVisualDirection,
                            updateAnimationDirection: updateAnimationDirection,
                            editMedia: { showsCompactMediaManager = true },
                            choosePhoto: presentCompactPhotoPicker,
                            isPhotoPickerPresented: showsCompactPhotoPicker,
                            removeMedia: removeMedia,
                            updateMediaPhotoData: updateMediaPhotoData,
                            restoreOriginalPhotoData: restoreOriginalPhotoData,
                            changeTheme: { showsThemeChooser = true },
                            changeLook: { showsLookChooser = true },
                            updateMessage: updateMessage,
                            continueGuidedFlowRequest: continueGuidedFlowRequest,
                            isGuidedFlowComplete: $isVideoSetupGuideComplete,
                            mediaPendingReplacement: $mediaPendingReplacement,
                            suppressAutoGuidedSheet: isReviewingImportedMedia,
                            discardVideoCreation: { showsDiscardVideoConfirmation = true }
                        )
                    } else if hasFinalVideoState {
                        EmptyView()
                    } else {
                        AnimateCreateMediaCard(
                            presentation: mediaPresentation,
                            choosePhotos: presentCompactPhotoPicker
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, bottomContentPadding)
            }
            .scrollIndicators(.hidden)

            if showsPrimaryActionBar {
                VStack(spacing: 0) {
                    Spacer(minLength: 0)

                    AnimateCreatePrimaryActionBar(
                        presentation: presentation,
                        startSignInFlow: startSignInFlow,
                        openCredits: openCredits,
                        prepareVideoDirection: prepareVideoDirection,
                        generateFinalRender: primaryFinalRenderAction,
                        continueFromCompletedVideoSetupGuide: continueFromCompletedVideoSetupGuide,
                        continueVideoSetup: continueVideoSetup,
                        choosePhoto: presentCompactPhotoPicker,
                        isVideoSetupGuideComplete: isVideoSetupGuideComplete,
                        openCreateVideoConfirmation: { showsCreateVideoConfirmation = true },
                        retryFinalVideoDownload: retryFinalVideoDownload,
                        finishFinalVideoToGallery: finishFinalVideoToGallery
                    )
                    .padding(.horizontal, -8)
                    .padding(.bottom, 4)
                }
                .background(alignment: .bottom) {
                    primaryActionBarBackdrop
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: presentation.videoDirectionSummary.hasScenes)
        .photosPicker(
            isPresented: $showsCompactPhotoPicker,
            selection: $pickerItems,
            maxSelectionCount: 1,
            matching: .images
        )
        .onChange(of: pickerItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            if let mediaPendingReplacement {
                replacePickerItems(mediaPendingReplacement, newItems)
            } else {
                importPickerItems(newItems)
            }
            pickerItems = []
        }
        .onChange(of: presentation.mediaSummary.selectedMedia) { _, newMedia in
            isVideoSetupGuideComplete = false
            guard shouldOpenMediaManagerAfterImport,
                  newMedia.contains(where: { $0.kind == "photo" || $0.kind == "image" }) else { return }
            shouldOpenMediaManagerAfterImport = false
            isReviewingImportedMedia = false
        }
        .onChange(of: selectedLook) { _, newValue in
            if newValue == nil {
                isVideoSetupGuideComplete = false
            }
        }
        .navigationDestination(isPresented: $showsCompactMediaManager) {
            AnimateCreateMediaManagerSheet(
                selectedMedia: presentation.mediaSummary.selectedMedia,
                syncedMediaAssets: mediaPresentation.syncedMediaAssets,
                canAddMedia: presentation.canAddMedia,
                isImporting: presentation.mediaSummary.isImporting,
                importProgress: presentation.mediaSummary.importProgress,
                removeMedia: removeMedia,
                updateMediaPhotoData: updateMediaPhotoData,
                restoreLocalMediaForEditing: restoreLocalMediaForEditing,
                discardVideoCreation: cancelLocalVideoCreationDraft,
                chooseManually: {
                    presentCompactPhotoPicker()
                }
            )
            .onDisappear {
                isReviewingImportedMedia = false
            }
        }
        .sheet(isPresented: $showsCreateVideoConfirmation) {
            AnimateCreateFinalVideoConfirmationSheet(
                action: finalVideoAction,
                mediaSummary: presentation.mediaSummary,
                isPreparingPlan: presentation.finalRenderSummary.isPreparingPlan,
                confirm: { removesWatermark in
                    showsCreateVideoConfirmation = false
                    waitsForFinalRenderPlan = false
                    submitFinalVideoConfirmation(removesWatermark)
                },
                openCredits: {
                    showsCreateVideoConfirmation = false
                    openCredits()
                },
                cancel: {
                    showsCreateVideoConfirmation = false
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(presentation.finalRenderSummary.isPreparingPlan)
        }
        .onChange(of: presentation.finalRenderSummary.renderPlan != nil) { _, _ in
            markVideoSetupGuideCompleteIfFinalPlanExists()
        }
        .onChange(of: finalVideoAction.canShowConfirmationSheet) { _, _ in
            presentCreateVideoConfirmationIfReady()
        }
        .onChange(of: presentation.finalRenderSummary.latestFinalJob?.id) { _, jobId in
            if jobId != nil {
                waitsForFinalRenderPlan = false
                showsCreateVideoConfirmation = false
            }
        }
        .onChange(of: presentation.finalRenderSummary.isPreparingPlan) { _, isPreparingPlan in
            guard waitsForFinalRenderPlan, !isPreparingPlan else { return }
            presentCreateVideoConfirmationIfReady()
        }
        .onAppear {
            markVideoSetupGuideCompleteIfFinalPlanExists()
            presentCreateVideoConfirmationIfPreparingPlan()
            openCompactPickerIfRequested(openPickerRequest)
        }
        .onChange(of: openPickerRequest) { _, newValue in
            openCompactPickerIfRequested(newValue)
        }
        .alert(L10n.string("create.discard.confirmTitle"), isPresented: $showsDiscardVideoConfirmation) {
            Button(L10n.string("create.discard.keep"), role: .cancel) {}
            Button(discardConfirmationActionTitle, role: .destructive) {
                discardCurrentVideoCreation()
            }
        } message: {
            Text(discardConfirmationMessage)
        }
        .navigationDestination(isPresented: $showsThemeChooser) {
            AnimateCreateThemeChooserPage(
                styles: styles,
                selectedStyle: selectedStyle,
                selectStyle: selectStyle,
                dismiss: { showsThemeChooser = false }
            )
            .id(selectedStyle.id)
        }
        .navigationDestination(isPresented: $showsLookChooser) {
            AnimateCreateLookChooserPage(
                selectedLook: selectedLook,
                selectLook: {
                    selectLook($0)
                    showsLookChooser = false
                },
                dismiss: { showsLookChooser = false }
            )
            .id(selectedLook?.rawValue ?? "none")
        }
    }

    private var mediaPresentation: AnimateCreateMediaPresentation {
        AnimateCreateMediaPresentation(
            activeVideoId: presentation.activeVideoId,
            template: presentation.template,
            summary: presentation.mediaSummary,
            canAddMedia: presentation.canAddMedia,
            availabilityMessage: presentation.mediaAvailabilityMessage
        )
    }

    private var finalVideoAction: AnimateCreateFinalVideoActionPresentation {
        AnimateCreateFinalVideoActionPresentation(
            summary: presentation.finalRenderSummary,
            template: presentation.template,
            balance: presentation.balance
        )
    }

    private var primaryActionPresentation: AnimateCreatePrimaryActionPresentation {
        AnimateCreatePrimaryActionPresentation(workflow: presentation)
    }

    private func primaryFinalRenderAction() {
        if finalVideoAction.hasRenderPlan {
            showsCreateVideoConfirmation = true
            return
        }

        waitsForFinalRenderPlan = true
        showsCreateVideoConfirmation = true
        prepareFinalRenderPlan(false)
    }

    private func presentCreateVideoConfirmationIfReady() {
        guard waitsForFinalRenderPlan,
              presentation.finalRenderSummary.latestFinalJob == nil,
              presentation.videoDirectionSummary.hasScenes || presentation.finalRenderSummary.renderPlan != nil,
              finalVideoAction.canShowConfirmationSheet else { return }
        waitsForFinalRenderPlan = false
        showsCreateVideoConfirmation = true
    }

    private func markVideoSetupGuideCompleteIfFinalPlanExists() {
        guard presentation.finalRenderSummary.renderPlan != nil
            || presentation.finalRenderSummary.isPreparingPlan else { return }
        isVideoSetupGuideComplete = true
    }

    private func presentCreateVideoConfirmationIfPreparingPlan() {
        guard presentation.finalRenderSummary.isPreparingPlan,
              presentation.finalRenderSummary.latestFinalJob == nil else { return }
        waitsForFinalRenderPlan = true
        showsCreateVideoConfirmation = true
    }

    private func continueFromCompletedVideoSetupGuide() {
        primaryFinalRenderAction()
    }

    private func continueVideoSetup() {
        continueGuidedFlowRequest += 1
    }

    private func openCompactPickerIfRequested(_ request: Int) {
        guard request > handledOpenPickerRequest,
              presentation.mediaSummary.selectedCount == 0 else { return }
        handledOpenPickerRequest = request
        consumeOpenPickerRequest()
        presentCompactPhotoPickerAfterViewUpdate()
    }

    private func presentCompactPhotoPicker() {
        showsCompactPhotoPicker = true
    }

    private func presentCompactPhotoPickerAfterViewUpdate() {
        Task { @MainActor in
            await Task.yield()
            showsCompactPhotoPicker = true
        }
    }

    private func discardCurrentVideoCreation() {
        discardVideoCreation()
    }

    private var discardConfirmationActionTitle: String {
        presentation.hasUnsavedLocalVideo ? L10n.string("create.discard.local") : L10n.string("create.discard.current")
    }

    private var discardConfirmationMessage: String {
        if presentation.hasUnsavedLocalVideo {
            return L10n.string("create.discard.localMessage")
        }

        return L10n.string("create.discard.currentMessage")
    }

    private var hasMediaSelection: Bool {
        presentation.mediaSummary.effectiveMediaCount > 0
            || !presentation.mediaSummary.syncedMediaAssets.isEmpty
    }

    private var hasFinalVideoState: Bool {
        presentation.finalRenderSummary.renderPlan != nil
            || presentation.finalRenderSummary.latestFinalJob != nil
            || presentation.finalRenderSummary.finalExport != nil
            || presentation.finalRenderSummary.pendingGalleryVideo != nil
    }

    private var showsFinalVideoCompletion: Bool {
        presentation.finalRenderSummary.finalExport != nil
            || presentation.finalRenderSummary.pendingGalleryVideo != nil
    }

    private var showsFinalVideoRecovery: Bool {
        guard presentation.finalRenderSummary.finalExport == nil,
              presentation.finalRenderSummary.pendingGalleryVideo == nil else { return false }
        return presentation.finalRenderSummary.latestFinalJob?.isTerminalFailure == true
    }

    private var showsWorkflowDashboard: Bool {
        hasMediaSelection || hasFinalVideoState
    }

    private var showsPrimaryActionBar: Bool {
        if showsFinalVideoCompletion {
            return false
        }
        return (showsFinalVideoCompletion
            || showsFinalVideoRecovery
            || presentation.finalRenderSummary.latestFinalJob != nil
            || primaryActionPresentation.hasFinalVideoIntent)
            && !presentation.isFinalRenderEditingLocked
    }

    private var bottomContentPadding: CGFloat {
        if showsFinalVideoCompletion {
            return 54
        }
        if showsFinalVideoRecovery {
            return 190
        }
        if presentation.isFinalRenderEditingLocked {
            return 118
        }
        return showsWorkflowDashboard ? 188 : 172
    }

    private var primaryActionBarBackdrop: some View {
        Color.clear
            .frame(height: 0)
        .allowsHitTesting(false)
    }
}

struct AnimateCreateBlockingPreparationView: View {
    let presentation: AnimateCreateWorkflowPresentation
    let isPreparingVideoDirectionAction: Bool
    let isPreparingFinalPlan: Bool

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 42)

            AnimateCreateRenderProgressScene(
                status: realtimeStatus,
                sourceImage: sourceImage,
                generatedImageLocalRelativePath: presentation.finalRenderSummary.generatedImagePreviewLocalRelativePath,
                fallbackIconName: iconName,
                tint: tint,
                isAnimating: isAnimating
            )

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)

                Text(message)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 24)
            }

            if let realtimeStatus {
                HStack(spacing: 7) {
                    ForEach(realtimeStatus.steps) { step in
                        Circle()
                            .fill(dotColor(for: step.state))
                            .frame(width: step.state == .current ? 8 : 6, height: step.state == .current ? 8 : 6)
                    }
                }
                .padding(.top, 4)
                .accessibilityHidden(true)
            } else {
                ProgressView()
                    .tint(tint)
                    .controlSize(.regular)
                    .padding(.top, 4)
            }

            Spacer(minLength: 120)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AnimateTheme.shellBackground.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }

    private var title: String {
        realtimeStatus?.title ?? mode.title
    }

    private var message: String {
        realtimeStatus?.detail ?? mode.message(itemCount: mediaProgress?.totalCount)
    }

    private var iconName: String {
        realtimeStatus?.systemImage ?? mode.iconName
    }

    private var tint: Color {
        realtimeStatus == nil ? mode.tint : AVBrandColor.accent
    }

    private var progressFraction: Double? {
        realtimeStatus?.progressFraction ?? mediaProgress?.fractionCompleted
    }

    private var progressTitle: String {
        if let progressFraction = realtimeStatus?.progressFraction {
            return "\(Int((progressFraction * 100).rounded()))%"
        }
        return mediaProgress?.title ?? L10n.string("create.media.progress.reading")
    }

    private var mediaProgress: AnimateMediaImportProgress? {
        presentation.mediaSummary.importProgress
    }

    private var sourceImage: UIImage? {
        presentation.mediaSummary.selectedMedia.first(where: \.selected)
            .flatMap { UIImage(data: $0.sourceImageDataForEditing) }
    }

    private var realtimeStatus: AnimateRenderRealtimePresentation? {
        guard presentation.finalRenderSummary.latestFinalJob?.isActiveRender == true else { return nil }
        return presentation.finalRenderSummary.realtimeStatus
    }

    private func dotColor(for state: AnimateRenderRealtimePresentation.Step.State) -> Color {
        switch state {
        case .done, .current:
            return AVBrandColor.accent
        case .failed:
            return .orange
        case .pending:
            return AVBrandColor.textSecondary.opacity(0.30)
        }
    }

    private var mode: PreparationMode {
        if presentation.isCreatingVideo {
            return .prepareVideoSetup
        }
        if isPreparingFinalPlan {
            return .prepareFinalPlan
        }
        if presentation.finalRenderSummary.isGenerating {
            return .createVideo
        }
        if presentation.finalRenderSummary.latestFinalJob?.isActiveRender == true {
            return .createVideo
        }
        if presentation.videoDirectionSummary.isPlanning {
            return .prepareStory
        }
        if isPreparingVideoDirectionAction {
            return .prepareFinalPlan
        }
        return .importMedia
    }

    private enum PreparationMode {
        case prepareVideoSetup
        case importMedia
        case prepareStory
        case uploadForVideo
        case prepareFinalPlan
        case createVideo

        var title: String {
            switch self {
            case .prepareVideoSetup:
                return L10n.string("create.preparation.prepareVideo.title")
            case .importMedia:
                return L10n.string("create.preparation.importMedia.title")
            case .prepareStory:
                return L10n.string("create.preparation.prepareStory.title")
            case .uploadForVideo:
                return L10n.string("create.preparation.uploadForVideo.title")
            case .prepareFinalPlan:
                return L10n.string("create.preparation.prepareFinalPlan.title")
            case .createVideo:
                return L10n.string("create.preparation.createVideo.title")
            }
        }

        var iconName: String {
            switch self {
            case .prepareVideoSetup:
                return "rectangle.stack.badge.plus"
            case .importMedia:
                return "photo.on.rectangle.angled"
            case .prepareStory:
                return "list.bullet.rectangle.portrait.fill"
            case .uploadForVideo:
                return "icloud.and.arrow.up.fill"
            case .prepareFinalPlan:
                return "creditcard.fill"
            case .createVideo:
                return "video.fill"
            }
        }

        var tint: Color {
            switch self {
            case .prepareVideoSetup, .importMedia, .prepareStory:
                return AVBrandColor.accent
            case .uploadForVideo, .prepareFinalPlan:
                return AVBrandColor.textSecondary
            case .createVideo:
                return AVBrandColor.textPrimary
            }
        }

        func message(itemCount: Int?) -> String {
            switch self {
            case .prepareVideoSetup:
                return L10n.string("create.preparation.prepareVideo.detail")
            case .importMedia:
                if let itemCount, itemCount > 0 {
                    let itemWord = itemCount == 1
                        ? L10n.string("media.item.singular")
                        : L10n.string("media.item.plural")
                    return L10n.string("create.preparation.importMedia.detailWithCount", itemCount, itemWord)
                }
                return L10n.string("create.preparation.importMedia.detail")
            case .prepareStory:
                return L10n.string("create.preparation.prepareStory.detail")
            case .uploadForVideo:
                if let itemCount, itemCount > 0 {
                    let itemWord = itemCount == 1
                        ? L10n.string("media.item.singular")
                        : L10n.string("media.item.plural")
                    return L10n.string("create.preparation.uploadForVideo.detailWithCount", itemCount, itemWord)
                }
                return L10n.string("create.preparation.uploadForVideo.detail")
            case .prepareFinalPlan:
                return L10n.string("create.preparation.prepareFinalPlan.detail")
            case .createVideo:
                return L10n.string("create.preparation.createVideo.detail")
            }
        }
    }
}

private struct AnimateCreateRenderProgressScene: View {
    let status: AnimateRenderRealtimePresentation?
    let sourceImage: UIImage?
    let generatedImageLocalRelativePath: String?
    let fallbackIconName: String
    let tint: Color
    let isAnimating: Bool

    @State private var generatedImage: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            tint.opacity(0.12),
                            Color.white.opacity(0.88),
                            AVBrandColor.neutral100.opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 246, height: 310)
                .shadow(color: AVBrandColor.textPrimary.opacity(0.08), radius: 24, y: 14)

            switch visualStage {
            case .sourcePhoto:
                photoLayer(image: sourceImage, isStyled: false)
                    .overlay(alignment: .bottomTrailing) {
                        aviGuideBadge(systemImage: "wand.and.stars")
                    }
                    .transition(.asymmetric(insertion: .scale.combined(with: .opacity), removal: .opacity))
            case .styledImage:
                photoLayer(image: styledPreviewImage, isStyled: true)
                    .overlay(alignment: .bottomTrailing) {
                        aviGuideBadge(systemImage: "sparkles")
                    }
                    .transition(.blurReplace)
            case .voiceover:
                photoLayer(image: styledPreviewImage, isStyled: true)
                    .overlay(alignment: .bottom) {
                        voiceoverWaves
                            .padding(.bottom, 26)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        aviGuideBadge(systemImage: "waveform")
                    }
                    .transition(.blurReplace)
            case .animatingVideo:
                photoLayer(image: styledPreviewImage, isStyled: true)
                    .overlay {
                        videoMotionOverlay
                    }
                    .overlay(alignment: .bottomTrailing) {
                        aviGuideBadge(systemImage: "play.fill")
                    }
                    .transition(.blurReplace)
            case .finishing, .completed:
                finishingCollage
                    .overlay(alignment: .bottomTrailing) {
                        aviGuideBadge(systemImage: "checkmark")
                    }
                    .transition(.scale.combined(with: .opacity))
            case .failed:
                failedScene
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.82), value: visualStage)
        .task(id: generatedImageLocalRelativePath) {
            generatedImage = Self.loadGeneratedImage(relativePath: generatedImageLocalRelativePath)
        }
        .accessibilityHidden(true)
    }

    private var visualStage: AnimateRenderRealtimePresentation.VisualStage {
        status?.visualStage ?? .sourcePhoto
    }

    private var styledPreviewImage: UIImage? {
        generatedImage ?? sourceImage
    }

    private func photoLayer(image: UIImage?, isStyled: Bool) -> some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .saturation(isStyled && generatedImage == nil ? 1.18 : 1)
                    .contrast(isStyled && generatedImage == nil ? 1.08 : 1)
                    .brightness(isStyled && generatedImage == nil ? 0.03 : 0)
                    .overlay {
                        if isStyled && generatedImage == nil {
                            LinearGradient(
                                colors: [
                                    AVBrandColor.accent.opacity(0.22),
                                    Color.clear,
                                    Color.white.opacity(0.18)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .blendMode(.softLight)
                        }
                    }
            } else {
                fallbackImage
            }
        }
        .frame(width: isStyled ? 198 : 182, height: isStyled ? 252 : 238)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 2)
        }
        .rotationEffect(.degrees(isStyled ? -2 : 2))
        .scaleEffect(isAnimating ? (isStyled ? 1.025 : 1.015) : (isStyled ? 0.99 : 0.985))
        .shadow(color: AVBrandColor.textPrimary.opacity(0.16), radius: 18, y: 10)
        .overlay(alignment: .topTrailing) {
            if isStyled {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(AVBrandColor.accent, in: Circle())
                    .offset(x: 12, y: -12)
            }
        }
    }

    private var fallbackImage: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.10))
                .frame(width: 126, height: 126)

            Image("AviFullBody")
                .resizable()
                .scaledToFit()
                .frame(width: 86, height: 86)

            Image(systemName: fallbackIconName)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(tint, in: Circle())
                .offset(x: 54, y: 48)
        }
    }

    private func aviGuideBadge(systemImage: String) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Image("AviFullBody")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .padding(8)
                .background(.white.opacity(0.92), in: Circle())
                .shadow(color: AVBrandColor.textPrimary.opacity(0.16), radius: 14, y: 8)
                .offset(x: 28, y: 24)

            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(AVBrandColor.accent, in: Circle())
                .offset(x: 30, y: 22)
        }
    }

    private var voiceoverWaves: some View {
        HStack(spacing: 5) {
            ForEach(0..<7, id: \.self) { index in
                Capsule()
                    .fill(.white.opacity(0.92))
                    .frame(width: 6, height: isAnimating ? CGFloat(16 + (index % 3) * 9) : CGFloat(10 + ((index + 1) % 3) * 8))
                    .animation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true).delay(Double(index) * 0.06), value: isAnimating)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.black.opacity(0.30), in: Capsule())
    }

    private var videoMotionOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.76), lineWidth: 2)
                .scaleEffect(isAnimating ? 1.04 : 0.96)
                .opacity(isAnimating ? 0.30 : 0.70)

            Image(systemName: "play.fill")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .background(.black.opacity(0.28), in: Circle())
        }
    }

    private var finishingCollage: some View {
        ZStack {
            photoLayer(image: sourceImage, isStyled: false)
                .frame(width: 142, height: 194)
                .offset(x: -42, y: -26)
                .rotationEffect(.degrees(-8))

            photoLayer(image: styledPreviewImage, isStyled: true)
                .frame(width: 154, height: 206)
                .offset(x: 34, y: 10)
                .rotationEffect(.degrees(6))

            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 38, weight: .black))
                .foregroundStyle(AVBrandColor.accent)
                .frame(width: 58, height: 58)
                .background(.white, in: Circle())
                .offset(x: 76, y: 118)
        }
        .frame(width: 230, height: 284)
    }

    private static func loadGeneratedImage(relativePath: String?) -> UIImage? {
        guard let relativePath, !relativePath.isEmpty else { return nil }
        let url = AnimateGalleryStore().localFileURL(relativePath: relativePath)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    private var failedScene: some View {
        VStack(spacing: 14) {
            fallbackImage
                .frame(width: 150, height: 150)

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(.orange)
        }
    }
}

private struct AnimateCreateFinalVideoReadyScene: View {
    let presentation: AnimateCreateWorkflowPresentation
    let viewInGallery: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 22)

            Button(action: viewInGallery) {
                AnimateCreateFinalVideoPreview(record: presentation.finalRenderSummary.pendingGalleryVideo)
                    .frame(maxWidth: 300)
                    .aspectRatio(0.78, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(alignment: .center) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 26, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 66, height: 66)
                            .background(.black.opacity(0.42), in: Circle())
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AVBrandColor.borderSubtle.opacity(0.58), lineWidth: 1)
                    }
                    .shadow(color: AVBrandColor.ink.opacity(0.12), radius: 20, y: 10)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 22)
            .accessibilityLabel(L10n.string("create.final.viewInGallery"))

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)

                Text(message)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 24)
            }

            Button(action: viewInGallery) {
                Label(L10n.string("create.final.viewInGallery"), systemImage: "rectangle.stack.badge.play.fill")
                    .font(.system(size: 15, weight: .black))
                    .frame(maxWidth: 260)
                    .frame(height: 48)
            }
            .buttonStyle(AnimateCreateFinalVideoButtonStyle())

            Spacer(minLength: 86)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AnimateTheme.shellBackground.ignoresSafeArea())
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title). \(message)")
    }

    private var title: String {
        presentation.finalRenderSummary.pendingGalleryVideo != nil
            ? L10n.string("create.final.readyToFinish.title")
            : L10n.string("create.final.readyToDownload.title")
    }

    private var message: String {
        if presentation.finalRenderSummary.pendingGalleryVideo != nil {
            return L10n.string("create.final.readyToFinish.detail")
        }
        if presentation.finalRenderSummary.canRetryFinalVideoDownload {
            return L10n.string("create.final.readyToDownload.retryDetail")
        }
        return L10n.string("create.final.readyToDownload.detail")
    }

}

private struct AnimateCreateFinalVideoPreview: View {
    let record: AnimateGalleryVideoRecord?
    @State private var videoThumbnail: UIImage?
    @State private var fallbackImage: UIImage?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AVBrandColor.accent.opacity(0.16),
                    Color.white.opacity(0.88),
                    AVBrandColor.neutral100
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let videoThumbnail {
                Image(uiImage: videoThumbnail)
                    .resizable()
                    .scaledToFill()
            } else if let fallbackImage {
                Image(uiImage: fallbackImage)
                    .resizable()
                    .scaledToFill()
            } else {
                VStack(spacing: 12) {
                    Image("AviFullBody")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 104, height: 104)

                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 34, weight: .black))
                        .foregroundStyle(AVBrandColor.accent)
                }
            }
        }
        .task(id: record?.id) {
            await loadPreview()
        }
    }

    private func loadPreview() async {
        guard let record else { return }
        let store = AnimateGalleryStore()
        let videoURL = store.localFileURL(for: record)
        if store.localFileExists(for: record) {
            videoThumbnail = await Self.loadVideoThumbnail(url: videoURL)
        }
        if videoThumbnail == nil,
           let generatedPath = record.generatedImageLocalRelativePath {
            fallbackImage = Self.loadImage(url: store.localFileURL(relativePath: generatedPath))
        }
        if videoThumbnail == nil,
           fallbackImage == nil,
           let sourcePath = record.sourceImageLocalRelativePath {
            fallbackImage = Self.loadImage(url: store.localFileURL(relativePath: sourcePath))
        }
    }

    private static func loadVideoThumbnail(url: URL) async -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 900, height: 900)

        guard let cgImage = try? await generator.image(at: .zero).image else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }

    private static func loadImage(url: URL) -> UIImage? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}

private struct AnimateCreateFinalVideoRecoveryScene: View {
    let presentation: AnimateCreateWorkflowPresentation
    let retryVideoCreation: () -> Void
    let choosePhoto: () -> Void
    let discardVideoCreation: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 42)

            ZStack {
                Circle()
                    .fill(AVBrandColor.textSecondary.opacity(0.10))
                    .frame(width: 128, height: 128)

                Circle()
                    .stroke(AVBrandColor.textSecondary.opacity(0.18), lineWidth: 2)
                    .frame(width: 156, height: 156)

                Image("AviFullBody")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 86, height: 86)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(AVBrandColor.textSecondary, in: Circle())
                    .offset(x: 54, y: 48)
                    .shadow(color: AVBrandColor.textSecondary.opacity(0.22), radius: 10, y: 4)
            }

            VStack(spacing: 8) {
                Text(L10n.string("create.final.recovery.title"))
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)

                Text(recoveryMessage)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 10) {
                if presentation.finalRenderSummary.latestFinalJob?.canRetry != false {
                    Button(action: retryVideoCreation) {
                        Label(L10n.string("create.final.retrySetup"), systemImage: "arrow.clockwise")
                            .font(.system(size: 14, weight: .black))
                            .frame(maxWidth: 240)
                            .frame(height: 44)
                    }
                    .buttonStyle(AnimateCreateFinalVideoButtonStyle())
                }

                Button(action: choosePhoto) {
                    Label(L10n.string("create.media.choose"), systemImage: "photo.badge.plus")
                        .font(.system(size: 14, weight: .black))
                        .frame(maxWidth: 240)
                        .frame(height: 44)
                }
                .buttonStyle(AnimateCreateSoftActionButtonStyle())

                Button(role: .destructive, action: discardVideoCreation) {
                    Label(L10n.string("create.final.recovery.discard"), systemImage: "trash")
                        .font(.system(size: 14, weight: .black))
                        .frame(maxWidth: 240)
                        .frame(height: 44)
                }
                .buttonStyle(AnimateCreateSoftActionButtonStyle())
            }

            Spacer(minLength: 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AnimateTheme.shellBackground.ignoresSafeArea())
        .accessibilityElement(children: .contain)
    }

    private var recoveryMessage: String {
        presentation.finalRenderSummary.realtimeStatus?.detail
            ?? presentation.finalRenderSummary.statusMessage
            ?? L10n.string("create.final.recovery.detail")
    }
}

private struct AnimateCreateVideoDirectionCard: View {
    let presentation: AnimateCreateWorkflowPresentation
    @Binding var form: AnimateVideoSetupForm
    @Binding var pickerItems: [PhotosPickerItem]
    let selectedStyle: AnimateVideoCreationStyle
    let selectedMusicPreset: AnimateVideoMusicPreset
    let selectedLook: AnimateVideoLook?
    let autoStyleSuggestion: AnimateMediaAutoStyleSuggestion?
    let canUndoAutoStyleSuggestion: Bool
    let styles: [AnimateVideoCreationStyle]
    let useAutoStyleSuggestion: () -> Void
    let undoAutoStyleSuggestion: () -> Void
    let selectStyle: (AnimateVideoCreationStyle) -> Void
    let selectLook: (AnimateVideoLook) -> Void
    let selectMovementDirection: (AnimateVideoMovementDirection) -> Void
    let selectVisualDirection: (AnimateVisualDirectionMode, String?) -> Void
    let updateAnimationDirection: (String) -> Void
    let editMedia: () -> Void
    let choosePhoto: () -> Void
    let isPhotoPickerPresented: Bool
    let removeMedia: (AnimateSelectedMedia) -> Void
    let updateMediaPhotoData: (AnimateSelectedMedia, Data) -> Void
    let restoreOriginalPhotoData: (AnimateSelectedMedia) -> Void
    let changeTheme: () -> Void
    let changeLook: () -> Void
    let updateMessage: (String) -> Void
    let continueGuidedFlowRequest: Int
    @Binding var isGuidedFlowComplete: Bool
    @Binding var mediaPendingReplacement: AnimateSelectedMedia?
    let suppressAutoGuidedSheet: Bool
    let discardVideoCreation: () -> Void

    @State private var guideState = AnimateCreateVideoSetupGuideState()
    @State private var activeGuidedSheet: GuidedStep?
    @State private var guidedLookFamily: AnimateVideoLookFamily?
    @State private var adjustingInlineMedia: AnimateSelectedMedia?
    @State private var shouldReturnToPhotoFrameAfterPicker = false
    @State private var handledContinueGuidedFlowRequest = 0

    private let minimumMessageCharacterCount = 3

    var body: some View {
        AVAppShellCard {
            VStack(alignment: .leading, spacing: 11) {
                HStack(alignment: .center, spacing: 14) {
                    AnimateSharedMediaSummaryStack(
                        localMedia: presentation.mediaSummary.selectedMedia,
                        syncedMedia: mediaPresentation.syncedMediaAssets
                    )
                    .frame(width: 82, height: 82)
                    .scaleEffect(0.88)

                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 9) {
                            Image(systemName: setupCardIconName)
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(iconColor, in: Circle())

                            Text(setupCardTitle)
                                .font(.system(size: 20, weight: .black))
                                .foregroundStyle(AVBrandColor.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Text(setupCardStatusMessage)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AVBrandColor.textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                }

                if isEffectiveGuidedFlowComplete {
                    guidedSummary
                } else {
                    guidedPendingSummary
                }

                if presentation.videoDirectionSummary.isPlanning {
                    ProgressView()
                        .tint(AVBrandColor.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

            }
        }
        .sheet(item: $activeGuidedSheet) { sheetStep in
            AnimateCreateGuidedStepSheet(
                footer: { continueButton },
                content: {
                    guidedStepContent(sheetStep)
                }
            )
            .presentationDetents(guidedSheetDetents(for: sheetStep))
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(item: $adjustingInlineMedia) { media in
            AnimateCreatePhotoAdjustView(
                media: media,
                save: { adjustedData in
                    updateMediaPhotoData(media, adjustedData)
                    adjustingInlineMedia = nil
                    guideState.step = .photoFrame
                    activeGuidedSheet = .photoFrame
                },
                continueWithOriginal: {
                    adjustingInlineMedia = nil
                    guideState.step = .photoFrame
                    activeGuidedSheet = .photoFrame
                },
                changePhoto: {
                    adjustingInlineMedia = nil
                    activeGuidedSheet = .photoFrame
                },
                cancel: {
                    adjustingInlineMedia = nil
                    activeGuidedSheet = .photoFrame
                }
            )
        }
        .onAppear {
            resetGuidedFlowIfPhotoIsMissing()
            guard !presentation.finalRenderSummary.isPreparingPlan,
                  !isEffectiveGuidedFlowComplete,
                  !suppressAutoGuidedSheet,
                  activeGuidedSheet == nil else { return }
            activeGuidedSheet = effectiveGuideStep
            updateGuidedLookFamilyForCurrentStep()
        }
        .onChange(of: activeGuidedSheet) { _, _ in
            updateGuidedLookFamilyForCurrentStep()
        }
        .onChange(of: selectedLook) { _, _ in
            updateGuidedLookFamilyForCurrentStep()
        }
        .onChange(of: continueGuidedFlowRequest) { _, request in
            guard request > handledContinueGuidedFlowRequest else { return }
            handledContinueGuidedFlowRequest = request
            continueStep()
        }
        .onChange(of: isPhotoPickerPresented) { _, isPresented in
            guard !isPresented,
                  shouldReturnToPhotoFrameAfterPicker,
                  activeGuidedSheet == nil else { return }
            isGuidedFlowComplete = false
            guideState.step = .photoFrame
            activeGuidedSheet = .photoFrame
        }
        .onChange(of: presentation.mediaSummary.selectedMedia) { _, newMedia in
            handlePhotoPickerResult(newMedia)
            resetGuidedFlowIfPhotoIsMissing()
        }
    }

    private var guidedProgressHeader: some View {
        HStack(spacing: 8) {
            ForEach(activeSteps) { item in
                Capsule()
                    .fill(guideState.step == item ? AVBrandColor.accent : AVBrandColor.mutedSurface)
                    .frame(height: 5)
            }
        }
        .accessibilityHidden(true)
    }

    private func guidedSheetDetents(for _: GuidedStep) -> Set<PresentationDetent> {
        [.large]
    }

    private var guidedSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            stepHeader(
                L10n.string("create.guided.summary.title"),
                L10n.string("create.guided.summary.detail")
            )

            AnimateCreateVideoDirectionDecisionSummary(
                isUserAdjusted: isUserAdjustedFromAvi,
                title: decisionSummaryTitle,
                detail: decisionSummaryDetail,
                aviSuggestionDetail: aviSuggestionSummaryDetail
            )

            summaryRows

            summaryCreateVideoAction
        }
    }

    private var guidedPendingSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            stepHeader(
                L10n.string("create.guided.summary.title"),
                L10n.string("create.guided.summary.detail")
            )

            summaryRows

        }
    }

    private var summaryCreateVideoAction: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(AVBrandColor.accent)
                    .frame(width: 32, height: 32)
                    .background(AVBrandColor.accent.opacity(0.14), in: Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.string("create.guided.summary.createVideo.title"))
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(L10n.string("create.guided.summary.createVideo.detail"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AVBrandColor.glassStroke.opacity(0.82), lineWidth: 1)
        }
        .shadow(color: AVBrandColor.glassShadow.opacity(0.7), radius: 12, y: 3)
    }

    private func summaryEditRow(title: String, detail: String, icon: String, editStep: GuidedStep) -> some View {
        Button {
            guideState.step = editStep
            activeGuidedSheet = editStep
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(AVBrandColor.accent)
                    .frame(width: 30, height: 30)
                    .background(AVBrandColor.accent.opacity(0.10), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)
                    Text(detail)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(AVBrandColor.textSecondary.opacity(0.7))
            }
            .padding(10)
            .background(AVBrandColor.mutedSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func guidedStepContent(_ sheetStep: GuidedStep) -> some View {
        switch sheetStep {
        case .photoFrame:
            VStack(alignment: .leading, spacing: 10) {
                stepHeader(L10n.string("create.guided.photoFrame.title"), L10n.string("create.guided.photoFrame.detail"))
                AnimateCreateGuidedPhotoFrameStep(
                    media: selectedPhotoMedia,
                    startsWithSourcePhoto: $form.startsWithSourcePhoto,
                    pickerItems: $pickerItems,
                    isImporting: presentation.mediaSummary.isImporting,
                    choosePhoto: choosePhoto,
                    adjustFrame: {
                        if let selectedPhotoMedia {
                            activeGuidedSheet = nil
                            adjustingInlineMedia = selectedPhotoMedia
                        }
                    },
                    preparePhotoReplacement: preparePhotoReplacement,
                    restoreOriginal: {
                        if let selectedPhotoMedia {
                            restoreOriginalPhotoData(selectedPhotoMedia)
                            isGuidedFlowComplete = false
                            guideState.step = .photoFrame
                            activeGuidedSheet = .photoFrame
                        }
                    }
                )
            }
        case .look:
            VStack(alignment: .leading, spacing: 10) {
                if let family = activeGuidedLookFamily {
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                            guidedLookFamily = nil
                        }
                    } label: {
                        Label(L10n.string("create.look.family.back"), systemImage: "chevron.left.circle.fill")
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(AVBrandColor.textSecondary)
                    }
                    .buttonStyle(.plain)

                    stepHeader(family.title, family.subtitle)

                    AnimateCreateLookFamilyNavigator(
                        family: family,
                        familyIndex: guidedLookFamilyIndex ?? 0,
                        familyCount: AnimateVideoLook.families.count,
                        previous: selectPreviousGuidedLookFamily,
                        next: selectNextGuidedLookFamily
                    )

                    VStack(spacing: 12) {
                        AnimateCreateLookFamilyRail(
                            families: AnimateVideoLook.families,
                            selectedFamily: family,
                            setupLook: selectedLook,
                            selectFamily: selectGuidedLookFamily
                        )

                        AnimateCreateTwoColumnGrid(items: family.looks, verticalSpacing: 10, itemHeight: 92) { look in
                            AnimateCreateGuidedLookTile(
                                look: look,
                                isSelected: selectedLook == look,
                                select: {
                                    selectLook(look)
                                }
                            )
                        }
                    }
                    .contentShape(Rectangle())
                    .gesture(guidedLookFamilySwipeGesture)
                } else {
                    stepHeader(L10n.string("create.guided.look.title"), L10n.string("create.guided.look.detail"))
                    AnimateCreateTwoColumnGrid(items: AnimateVideoLook.families, verticalSpacing: 10, itemHeight: 104) { family in
                        AnimateCreateLookFamilyTile(
                            family: family,
                            isSelected: family.looks.contains(where: { $0 == selectedLook }),
                            select: {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                                    guidedLookFamily = family
                                }
                            }
                        )
                    }
                    if selectedLook != nil {
                        selectedLookStrip
                    }
                    guidedMotionSelector
                }
            }
            .onAppear {
                if guidedLookFamily == nil, selectedLook != nil {
                    guidedLookFamily = AnimateVideoLook.family(containing: selectedLook)
                }
            }
        case .movement:
            VStack(alignment: .leading, spacing: 10) {
                stepHeader(L10n.string("create.guided.movement.title"), L10n.string("create.guided.movement.detail"))
                AnimateCreateGuidedTemplateMenu(
                    title: L10n.string("create.guided.direction.template"),
                    selectedTitle: selectedAnimationDirectionPreset.title,
                    selectedDetail: selectedAnimationDirectionPreset.detail,
                    options: AnimationDirectionPreset.menuOptions,
                    select: applyAnimationDirectionPreset
                )
                Text(L10n.string("create.guided.direction.tip"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AVBrandColor.textSecondary)
            }
        case .scriptIdea:
            VStack(alignment: .leading, spacing: 10) {
                stepHeader(L10n.string("create.guided.script.title"), L10n.string("create.guided.script.detail"))
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 2), spacing: 8) {
                    AnimateCreateGuidedMessageModeTile(
                        title: L10n.string("create.guided.script.none"),
                        detail: L10n.string("create.guided.script.none.preview"),
                        systemImage: "sparkles",
                        isSelected: guideState.selectedScriptIdea == .none && !hasMessage,
                        select: {
                            guideState.selectScriptIdea(.none)
                            form.hasMessage = false
                            form.voiceEnabled = false
                            updateMessage("")
                        }
                    )
                    AnimateCreateGuidedMessageModeTile(
                        title: L10n.string("create.guided.script.message"),
                        detail: L10n.string("create.guided.script.custom.preview"),
                        systemImage: "text.bubble.fill",
                        isSelected: wantsMessage,
                        select: {
                            guideState.selectScriptIdea(.custom)
                            form.hasMessage = hasMessage
                            form.voiceEnabled = false
                        }
                    )
                }

                if wantsMessage {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(L10n.string("create.guided.script.message"))
                                .font(.system(size: 12, weight: .black))
                            Spacer()
                            if hasMessage {
                                Button {
                                    guideState.selectScriptIdea(.none)
                                    form.hasMessage = false
                                    form.voiceEnabled = false
                                    updateMessage("")
                                } label: {
                                    Label(L10n.string("create.guided.message.clear"), systemImage: "xmark.circle.fill")
                                        .font(.system(size: 12, weight: .black))
                                        .labelStyle(.titleAndIcon)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(AVBrandColor.textSecondary)
                            }
                            Text("\(form.details.count)/\(AnimateVideoSetupLimits.messageCharacterLimit)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AVBrandColor.textSecondary)
                        }
                        TextEditor(text: Binding(
                            get: { form.details },
                            set: {
                                guideState.selectedScriptIdea = .custom
                                let hasText = !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                form.hasMessage = hasText
                                form.voiceEnabled = false
                                updateMessage($0)
                            }
                        ))
                        .font(.system(size: 15, weight: .semibold))
                        .frame(minHeight: 160)
                        .padding(10)
                        .background(AVBrandColor.cardSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(AVBrandColor.borderSubtle.opacity(0.7), lineWidth: 1)
                        }
                        Text(L10n.string("create.guided.script.tip"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AVBrandColor.textSecondary)
                        if !canContinueMessageStep {
                            Text(L10n.string("create.guided.message.minimum", minimumMessageCharacterCount))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(AVBrandColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private var activeGuidedLookFamily: AnimateVideoLookFamily? {
        guidedLookFamily
    }

    private var guidedLookFamilyIndex: Int? {
        guard let guidedLookFamily else { return nil }
        return AnimateVideoLook.families.firstIndex(where: { $0.id == guidedLookFamily.id })
    }

    private var guidedLookFamilySwipeGesture: some Gesture {
        DragGesture(minimumDistance: 28)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > abs(vertical), abs(horizontal) > 44 else { return }

                if horizontal < 0 {
                    selectNextGuidedLookFamily()
                } else {
                    selectPreviousGuidedLookFamily()
                }
            }
    }

    private var selectedLookStrip: some View {
        HStack(spacing: 9) {
            Image(systemName: selectedLook?.systemImage ?? "paintbrush.pointed.fill")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(AVBrandColor.accent)
                .frame(width: 28, height: 28)
                .background(AVBrandColor.accent.opacity(0.10), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedLook.map { L10n.string("create.guided.look.selected", $0.title) } ?? L10n.string("create.guided.look.noneSelected.title"))
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)
                Text(selectedLook?.subtitle ?? L10n.string("create.guided.look.noneSelected.detail"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .background(AVBrandColor.mutedSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var continueButton: some View {
        Button(action: continueStep) {
            Text(continueButtonTitle)
                .font(.system(size: 15, weight: .black))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
        }
        .disabled(isContinueDisabled)
        .buttonStyle(AnimateCreateSoftActionButtonStyle())
        .opacity(isContinueDisabled ? 0.62 : 1)
    }

    private var isContinueDisabled: Bool {
        switch effectiveGuideStep {
        case .photoFrame:
            return selectedPhotoMedia == nil || presentation.mediaSummary.isImporting
        case .look:
            return selectedLook == nil
        case .movement:
            return false
        case .scriptIdea:
            if guideState.step == .scriptIdea, wantsMessage {
                return !canContinueMessageStep
            }
            return false
        }
    }

    private func stepHeader(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 20, weight: .black))
                .foregroundStyle(AVBrandColor.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(detail)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AVBrandColor.textSecondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private var activeSteps: [GuidedStep] {
        [.photoFrame, .look, .scriptIdea]
    }

    @ViewBuilder
    private var summaryRows: some View {
        VStack(spacing: 8) {
            summaryEditRow(
                title: L10n.string("create.guided.summary.photoFrame"),
                detail: photoFrameSummaryDetail,
                icon: "photo.fill",
                editStep: .photoFrame
            )
            if selectedPhotoMedia != nil {
                summaryEditRow(
                    title: L10n.string("create.guided.summary.look"),
                    detail: selectedLookTitle,
                    icon: "paintbrush.pointed.fill",
                    editStep: .look
                )
                summaryEditRow(
                    title: L10n.string("create.guided.summary.message"),
                    detail: hasMessage ? form.details : L10n.string("create.guided.script.none"),
                    icon: "text.bubble.fill",
                    editStep: .scriptIdea
                )
            }
        }
    }

    private var hasMessage: Bool {
        !form.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var wantsMessage: Bool {
        guideState.selectedScriptIdea != .none || hasMessage
    }

    private var selectedLookTitle: String {
        selectedLook?.title ?? L10n.string("create.guided.look.noneSelected.title")
    }

    private var guidedMotionSelector: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Text(L10n.string("create.guided.motion.title"))
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)
                Text(selectedAnimationDirectionPreset.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AVBrandColor.textSecondary)
                Spacer()
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
                ForEach(AnimationDirectionPreset.motionOptions) { preset in
                    AnimateCreateGuidedMotionTile(
                        preset: preset,
                        isSelected: selectedAnimationDirectionPreset == preset,
                        select: { applyAnimationDirectionPreset(preset) }
                    )
                }
            }
        }
        .padding(.top, 2)
    }

    private var photoFrameSummaryDetail: String {
        guard let selectedPhotoMedia else {
            return L10n.string("create.guided.photoFrame.empty")
        }
        return selectedPhotoMedia.hasFrameAdjustment
            ? L10n.string("create.mediaAdjust.frameApplied")
            : L10n.string("create.guided.photoFrame.ready")
    }

    private var animationSummaryDetail: String {
        switch form.visualDirectionMode {
        case .none:
            return L10n.string("create.guided.direction.none")
        case .template:
            return selectedAnimationDirectionPreset.title
        case .custom:
            let trimmed = form.animationDirection.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? L10n.string("create.guided.direction.none") : trimmed
        }
    }

    private var selectedPhotoMedia: AnimateSelectedMedia? {
        presentation.mediaSummary.selectedMedia.first(where: { isRenderablePhotoMedia($0) && $0.selected })
            ?? presentation.mediaSummary.selectedMedia.first(where: isRenderablePhotoMedia)
    }

    private func isRenderablePhotoMedia(_ media: AnimateSelectedMedia) -> Bool {
        (media.kind == "photo" || media.kind == "image")
            && UIImage(data: media.data) != nil
    }

    private var canContinueMessageStep: Bool {
        form.details.trimmingCharacters(in: .whitespacesAndNewlines).count >= minimumMessageCharacterCount
    }

    private var selectedScriptIdea: ScriptIdea {
        if form.details.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .none
        }
        return guideState.selectedScriptIdea == .none ? .custom : guideState.selectedScriptIdea
    }

    private func continueStep() {
        let result = guideState.continueStep(
            hasSelectedLook: selectedLook != nil,
            hasSelectedPhoto: selectedPhotoMedia != nil,
            hasMessage: hasMessage,
            canContinueMessageStep: canContinueMessageStep
        )
        isGuidedFlowComplete = guideState.isComplete
        activeGuidedSheet = result.activeSheet
        if result.clearsMessage {
            updateMessage("")
        }
    }

    private var effectiveGuideStep: GuidedStep {
        selectedPhotoMedia == nil ? .photoFrame : guideState.step
    }

    private var isEffectiveGuidedFlowComplete: Bool {
        selectedPhotoMedia != nil && isGuidedFlowComplete
    }

    private func resetGuidedFlowIfPhotoIsMissing() {
        guard selectedPhotoMedia == nil else { return }
        isGuidedFlowComplete = false
        guideState.step = .photoFrame
        if activeGuidedSheet != nil {
            activeGuidedSheet = .photoFrame
        }
    }

    private func preparePhotoReplacement() {
        shouldReturnToPhotoFrameAfterPicker = true
        if let selectedPhotoMedia {
            mediaPendingReplacement = selectedPhotoMedia
        }
    }

    private func handlePhotoPickerResult(_ media: [AnimateSelectedMedia]) {
        guard shouldReturnToPhotoFrameAfterPicker else { return }
        let photos = media.filter { $0.kind == "photo" || $0.kind == "image" }

        if let previous = mediaPendingReplacement {
            let replacementPhotos = photos.filter { $0.id != previous.id }
            guard let replacement = replacementPhotos.last ?? photos.last else { return }
            shouldReturnToPhotoFrameAfterPicker = false
            mediaPendingReplacement = nil
            isGuidedFlowComplete = false
            guideState.step = .photoFrame
            for photo in photos where photo.id != replacement.id {
                removeMedia(photo)
            }
            Task { @MainActor in
                await Task.yield()
                activeGuidedSheet = .photoFrame
            }
            return
        }

        guard !photos.isEmpty else { return }
        shouldReturnToPhotoFrameAfterPicker = false
        isGuidedFlowComplete = false
        guideState.step = .photoFrame
        activeGuidedSheet = .photoFrame
    }

    private func updateGuidedLookFamilyForCurrentStep() {
        guard activeGuidedSheet == .look, guidedLookFamily == nil, let selectedLook else { return }
        guidedLookFamily = AnimateVideoLook.family(containing: selectedLook)
    }

    private func selectGuidedLookFamily(_ family: AnimateVideoLookFamily) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
            guidedLookFamily = family
        }
    }

    private func selectPreviousGuidedLookFamily() {
        guard let index = guidedLookFamilyIndex else { return }
        let previousIndex = index == 0 ? AnimateVideoLook.families.count - 1 : index - 1
        selectGuidedLookFamily(AnimateVideoLook.families[previousIndex])
    }

    private func selectNextGuidedLookFamily() {
        guard let index = guidedLookFamilyIndex else { return }
        let nextIndex = index == AnimateVideoLook.families.count - 1 ? 0 : index + 1
        selectGuidedLookFamily(AnimateVideoLook.families[nextIndex])
    }

    private var continueButtonTitle: String {
        switch effectiveGuideStep {
        case .photoFrame:
            return selectedPhotoMedia == nil
                ? L10n.string("create.media.choose")
                : L10n.string("create.guided.continue.look")
        case .look:
            return selectedLook == nil
                ? L10n.string("create.guided.look.noneSelected.title")
                : L10n.string("create.guided.continue.message")
        case .scriptIdea:
            return L10n.string("create.guided.continue.finish")
        case .movement:
            return L10n.string("create.guided.continue.finish")
        }
    }

    private func applyScriptIdea(_ idea: ScriptIdea) {
        if let style = styles.first(where: { $0.id == idea.styleID }) {
            selectStyle(style)
        }
        if idea != .custom {
            updateMessage(idea.defaultMessage)
        }
        let hasText = !(idea == .custom ? form.details : idea.defaultMessage)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
        form.hasMessage = hasText
        form.voiceEnabled = false
        form.occasion = idea.title
    }

    private func applyAnimationDirectionPreset(_ preset: AnimationDirectionPreset) {
        selectMovementDirection(preset.movementDirection)
        switch preset {
        case .none:
            updateAnimationDirection("")
            selectVisualDirection(.none, nil)
        case .custom:
            let trimmed = form.animationDirection.trimmingCharacters(in: .whitespacesAndNewlines)
            selectVisualDirection(trimmed.isEmpty ? .none : .custom, nil)
        default:
            updateAnimationDirection("")
            selectVisualDirection(.template, preset.rawValue)
        }
    }

    private var selectedAnimationDirectionPreset: AnimationDirectionPreset {
        switch form.visualDirectionMode {
        case .none:
            return .none
        case .template:
            return AnimationDirectionPreset(rawValue: form.visualDirectionTemplateId ?? "") ?? .none
        case .custom:
            return form.animationDirection.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .none : .custom
        }
    }

    private var isUserAdjustedFromAvi: Bool {
        guard let autoStyleSuggestion else { return false }
        return selectedStyle.id != autoStyleSuggestion.styleID
            || selectedMusicPreset != autoStyleSuggestion.musicPreset
    }

    private var showsUseAviSuggestion: Bool {
        autoStyleSuggestion != nil && isUserAdjustedFromAvi
    }

    private var decisionSummaryTitle: String {
        L10n.string("create.videoDirection.summary.userTitle")
    }

    private var decisionSummaryDetail: String {
        return L10n.string(
            "create.videoDirection.summary.userDetail",
            selectedStyle.title,
            selectedMusicPreset.title,
            selectedLookTitle
        )
    }

    private var aviSuggestionSummaryDetail: String? {
        guard isUserAdjustedFromAvi,
              let autoStyleSuggestion else { return nil }
        let styleTitle = styles.first(where: { $0.id == autoStyleSuggestion.styleID })?.title
            ?? L10n.string("create.options.anotherTheme")
        return L10n.string(
            "create.videoDirection.summary.aviProposalDetail",
            styleTitle,
            autoStyleSuggestion.musicPreset.title,
            selectedLookTitle
        )
    }

    private var mediaPresentation: AnimateCreateMediaPresentation {
        AnimateCreateMediaPresentation(
            activeVideoId: presentation.activeVideoId,
            template: presentation.template,
            summary: presentation.mediaSummary,
            canAddMedia: presentation.canAddMedia,
            availabilityMessage: presentation.mediaAvailabilityMessage
        )
    }

    private var iconColor: Color {
        if selectedPhotoMedia == nil {
            return AVBrandColor.accent
        }
        if selectedLook == nil {
            return AVBrandColor.textPrimary
        }
        return presentation.videoDirectionSummary.hasScenes ? AVBrandColor.accent : AVBrandColor.textPrimary
    }

    private var setupCardIconName: String {
        if selectedPhotoMedia == nil {
            return "photo.fill"
        }
        if selectedLook == nil {
            return "paintbrush.pointed.fill"
        }
        if !isEffectiveGuidedFlowComplete {
            return "text.bubble.fill"
        }
        return videoDirection.iconName
    }

    private var setupCardTitle: String {
        if selectedPhotoMedia == nil {
            return L10n.string("create.guided.photoFrame.title")
        }
        if selectedLook == nil {
            return L10n.string("create.guided.look.title")
        }
        if !isEffectiveGuidedFlowComplete {
            return L10n.string("create.guided.script.title")
        }
        return L10n.string("create.storyDirection.cardTitle")
    }

    private var setupCardStatusMessage: String {
        if selectedPhotoMedia == nil {
            return L10n.string("create.guided.photoFrame.empty")
        }
        if selectedLook == nil {
            return L10n.string("create.guided.look.noneSelected.title")
        }
        if !isEffectiveGuidedFlowComplete {
            return L10n.string("create.guided.script.detail")
        }
        return videoDirection.statusMessage
    }

    private var mediaDetail: String {
        return L10n.string("create.mediaCard.selectionMessage")
    }


    private var discardActionTitle: String {
        presentation.hasUnsavedLocalVideo ? L10n.string("create.discard.closeDraft") : L10n.string("create.discard.current")
    }

    private var discardActionIconName: String {
        presentation.hasUnsavedLocalVideo ? "xmark.circle" : "trash"
    }

    private var canShowDiscardAction: Bool {
        presentation.finalRenderSummary.latestFinalJob?.isActiveRender != true
    }

    private var videoDirection: AnimateCreateVideoDirectionPresentation {
        AnimateCreateVideoDirectionPresentation(
            mediaSummary: presentation.mediaSummary,
            videoDirectionSummary: presentation.videoDirectionSummary,
            selectedDuration: .auto,
            renderPlan: presentation.finalRenderSummary.renderPlan?.plan,
            canRefreshVideoDirection: presentation.canPrepareVideoDirection,
            availabilityMessage: presentation.videoDirectionAvailabilityMessage
        )
    }

    private var primaryActionPresentation: AnimateCreatePrimaryActionPresentation {
        AnimateCreatePrimaryActionPresentation(workflow: presentation)
    }

}

private struct AnimateCreateGuidedStepSheet<Content: View, Footer: View>: View {
    @ViewBuilder let footer: () -> Footer
    @ViewBuilder let content: () -> Content

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    content()
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 104)
            }
            .background(AnimateTheme.shellBackground.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 0) {
                    Divider()
                        .opacity(0.45)
                    footer()
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 12)
                        .background(.ultraThinMaterial)
                }
            }
        }
    }
}

private struct AnimateCreateVideoDirectionDecisionSummary: View {
    let isUserAdjusted: Bool
    let title: String
    let detail: String
    let aviSuggestionDetail: String?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: isUserAdjusted ? "slider.horizontal.3" : "wand.and.stars")
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(AVBrandColor.accent)
                .frame(width: 28, height: 28)
                .background(AVBrandColor.accent.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)

                Text(detail)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                if let aviSuggestionDetail {
                    Divider()
                        .padding(.vertical, 2)

                    Text(L10n.string("create.videoDirection.summary.aviProposalTitle"))
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(AVBrandColor.accent)

                    Text(aviSuggestionDetail)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(AVBrandColor.accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct AnimateCreateVideoSetupGuideState: Equatable {
    struct ContinueResult: Equatable {
        var activeSheet: GuidedStep?
        var clearsMessage = false
    }

    var step: GuidedStep = .photoFrame
    var selectedScriptIdea: ScriptIdea = .none
    var isComplete = false

    mutating func selectScriptIdea(_ idea: ScriptIdea) {
        selectedScriptIdea = idea
        if isComplete {
            isComplete = false
        }
    }

    mutating func continueStep(
        hasSelectedLook: Bool,
        hasSelectedPhoto: Bool,
        hasMessage: Bool,
        canContinueMessageStep: Bool
    ) -> ContinueResult {
        switch step {
        case .photoFrame:
            guard hasSelectedPhoto else {
                return ContinueResult(activeSheet: .photoFrame)
            }
            step = .look
            isComplete = false
            return ContinueResult(activeSheet: .look)
        case .look:
            guard hasSelectedLook else {
                return ContinueResult(activeSheet: .look)
            }
            step = .scriptIdea
            isComplete = false
            return ContinueResult(activeSheet: .scriptIdea)
        case .movement:
            step = .scriptIdea
            isComplete = false
            return ContinueResult(activeSheet: .scriptIdea)
        case .scriptIdea:
            if !hasMessage {
                completeWithoutMessage()
                return ContinueResult(activeSheet: nil, clearsMessage: true)
            }
            if hasMessage && canContinueMessageStep {
                isComplete = true
                return ContinueResult(activeSheet: nil)
            }
            isComplete = false
            return ContinueResult(activeSheet: .scriptIdea)
        }
    }

    mutating func completeWithoutMessage() {
        step = .scriptIdea
        isComplete = true
    }
}

private struct AnimateCreateGuidedPhotoFrameStep: View {
    let media: AnimateSelectedMedia?
    @Binding var startsWithSourcePhoto: Bool
    @Binding var pickerItems: [PhotosPickerItem]
    let isImporting: Bool
    let choosePhoto: () -> Void
    let adjustFrame: () -> Void
    let preparePhotoReplacement: () -> Void
    let restoreOriginal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            photoActions
            if hasRenderableMedia {
                sourcePhotoTransitionToggle
            }
            photoPreview
        }
    }

    @ViewBuilder
    private var photoActions: some View {
        if !hasRenderableMedia {
            Button(action: choosePhoto) {
                Label(L10n.string("create.media.choose"), systemImage: "photo.badge.plus")
                    .font(.system(size: 14, weight: .black))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .disabled(isImporting)
            .buttonStyle(AnimateCreateSoftActionButtonStyle())
        } else {
            HStack(spacing: 12) {
                Button(action: adjustFrame) {
                    Label(L10n.string("create.mediaAdjust.adjustFrame"), systemImage: "crop")
                }
                .buttonStyle(AnimateCreatePhotoFrameSecondaryButtonStyle())

                PhotosPicker(selection: $pickerItems, maxSelectionCount: 1, matching: .images) {
                    Label(L10n.string("create.mediaAdjust.changePhoto"), systemImage: "photo.on.rectangle")
                }
                .simultaneousGesture(TapGesture().onEnded(preparePhotoReplacement))
                .disabled(isImporting)
                .buttonStyle(AnimateCreatePhotoFrameSecondaryButtonStyle())
            }
            .frame(maxWidth: .infinity)

            if media?.hasFrameAdjustment == true {
                Button(action: restoreOriginal) {
                    Label(L10n.string("create.mediaAdjust.restoreOriginal"), systemImage: "arrow.uturn.backward")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(AVBrandColor.mutedSurface.opacity(0.56), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var sourcePhotoTransitionToggle: some View {
        Toggle(isOn: $startsWithSourcePhoto) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.string("create.mediaTransition.sourcePhoto.title"))
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)
                Text(L10n.string(startsWithSourcePhoto ? "create.mediaTransition.sourcePhoto.enabledDetail" : "create.mediaTransition.sourcePhoto.disabledDetail"))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .toggleStyle(.switch)
        .tint(AVBrandColor.accent)
        .padding(12)
        .background(AVBrandColor.mutedSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private var photoPreview: some View {
        if let media, let image = UIImage(data: media.data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(maxHeight: 420)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AVBrandColor.borderSubtle.opacity(0.7), lineWidth: 1)
                }
                .overlay(alignment: .topTrailing) {
                    if media.hasFrameAdjustment {
                        Text(L10n.string("create.mediaAdjust.frameApplied"))
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(AVBrandColor.textPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial, in: Capsule())
                            .padding(8)
                    }
                }
                .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 12) {
                Image(systemName: isImporting ? "photo.badge.clock" : "photo.badge.plus")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(AVBrandColor.accent)
                Text(photoPreviewFallbackText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 260)
            .background(AVBrandColor.mutedSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var photoPreviewFallbackText: String {
        if isImporting {
            return L10n.string("create.mediaCard.import.readingSelected")
        }
        if !hasRenderableMedia {
            return L10n.string("create.guided.photoFrame.empty")
        }
        return L10n.string("create.guided.photoFrame.ready")
    }

    private var hasRenderableMedia: Bool {
        guard let media else { return false }
        return UIImage(data: media.data) != nil
    }

}

private struct AnimateCreatePhotoFrameSecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(isEnabled ? AVBrandColor.textPrimary : AVBrandColor.textSecondary.opacity(0.55))
            .labelStyle(.titleAndIcon)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(background(configuration: configuration), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AVBrandColor.borderSubtle.opacity(isEnabled ? 0.46 : 0.24), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }

    private func background(configuration: Configuration) -> Color {
        if !isEnabled {
            return AVBrandColor.mutedSurface.opacity(0.62)
        }
        return configuration.isPressed ? AVBrandColor.mutedSurface.opacity(0.88) : .white.opacity(0.72)
    }
}

protocol AnimateCreateGuidedTemplateOption: Identifiable {
    var title: String { get }
    var detail: String { get }
    var systemImage: String { get }
}

private struct AnimateCreateGuidedTemplateMenu<Option: AnimateCreateGuidedTemplateOption>: View {
    let title: String
    let selectedTitle: String
    let selectedDetail: String
    let options: [Option]
    let select: (Option) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(AVBrandColor.textPrimary)

            Menu {
                ForEach(options) { option in
                    Button {
                        select(option)
                    } label: {
                        Label(option.title, systemImage: option.systemImage)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(selectedTitle)
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(AVBrandColor.textPrimary)
                            .lineLimit(1)
                        Text(selectedDetail)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AVBrandColor.textSecondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(AVBrandColor.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AVBrandColor.cardSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AVBrandColor.borderSubtle.opacity(0.72), lineWidth: 1)
                }
            }
        }
    }
}

enum GuidedStep: String, CaseIterable, Identifiable {
    case photoFrame
    case look
    case movement
    case scriptIdea

    var id: String { rawValue }

    var title: String {
        switch self {
        case .photoFrame: L10n.string("create.guided.photoFrame.tab")
        case .look: L10n.string("create.guided.look.tab")
        case .movement: L10n.string("create.guided.movement.tab")
        case .scriptIdea: L10n.string("create.guided.script.tab")
        }
    }
}

enum AnimationDirectionPreset: String, CaseIterable, Identifiable, AnimateCreateGuidedTemplateOption {
    case none
    case gentleReveal
    case playful
    case subjectWave
    case environmentMagic
    case cameraPush
    case cinematic
    case celebration
    case custom

    var id: String { rawValue }

    static var menuOptions: [AnimationDirectionPreset] {
        motionOptions
    }

    static var motionOptions: [AnimationDirectionPreset] {
        [.none, .celebration, .gentleReveal, .playful, .cinematic]
    }

    var title: String {
        switch self {
        case .none: L10n.string("create.guided.direction.none")
        case .gentleReveal: L10n.string("create.guided.direction.gentleReveal.title")
        case .playful: L10n.string("create.guided.direction.playful.title")
        case .subjectWave: L10n.string("create.guided.direction.subjectWave.title")
        case .environmentMagic: L10n.string("create.guided.direction.environmentMagic.title")
        case .cameraPush: L10n.string("create.guided.direction.cameraPush.title")
        case .cinematic: L10n.string("create.guided.direction.cinematic.title")
        case .celebration: L10n.string("create.guided.direction.celebration.title")
        case .custom: L10n.string("create.guided.direction.custom.title")
        }
    }

    var detail: String {
        switch self {
        case .none: L10n.string("create.guided.direction.none.detail")
        case .gentleReveal: L10n.string("create.guided.direction.gentleReveal.detail")
        case .playful: L10n.string("create.guided.direction.playful.detail")
        case .subjectWave: L10n.string("create.guided.direction.subjectWave.detail")
        case .environmentMagic: L10n.string("create.guided.direction.environmentMagic.detail")
        case .cameraPush: L10n.string("create.guided.direction.cameraPush.detail")
        case .cinematic: L10n.string("create.guided.direction.cinematic.detail")
        case .celebration: L10n.string("create.guided.direction.celebration.detail")
        case .custom: L10n.string("create.guided.direction.custom.detail")
        }
    }

    var promptText: String {
        switch self {
        case .none, .custom: ""
        case .gentleReveal: L10n.string("create.guided.direction.gentleReveal.prompt")
        case .playful: L10n.string("create.guided.direction.playful.prompt")
        case .subjectWave: L10n.string("create.guided.direction.subjectWave.prompt")
        case .environmentMagic: L10n.string("create.guided.direction.environmentMagic.prompt")
        case .cameraPush: L10n.string("create.guided.direction.cameraPush.prompt")
        case .cinematic: L10n.string("create.guided.direction.cinematic.prompt")
        case .celebration: L10n.string("create.guided.direction.celebration.prompt")
        }
    }

    var systemImage: String {
        switch self {
        case .none: "sparkles.slash"
        case .gentleReveal: "heart.fill"
        case .playful: "face.smiling.fill"
        case .subjectWave: "hand.wave.fill"
        case .environmentMagic: "sparkles"
        case .cameraPush: "camera.viewfinder"
        case .cinematic: "movieclapper.fill"
        case .celebration: "party.popper.fill"
        case .custom: "slider.horizontal.3"
        }
    }

    var movementDirection: AnimateVideoMovementDirection {
        switch self {
        case .none, .gentleReveal:
            return .subtleFaithful
        case .playful:
            return .livingPortrait
        case .subjectWave:
            return .livingPortrait
        case .environmentMagic:
            return .livingBackground
        case .cameraPush, .cinematic:
            return .cinematic
        case .celebration:
            return .celebration
        case .custom:
            return .custom
        }
    }
}

enum ScriptIdea: String, CaseIterable, Identifiable, AnimateCreateGuidedTemplateOption {
    case none
    case custom
    case birthday
    case congratulations
    case love
    case missYou
    case holiday
    case motivation
    case funny

    var id: String { rawValue }

    static var menuOptions: [ScriptIdea] {
        [.none, .birthday, .congratulations, .love, .missYou, .holiday, .motivation, .funny]
    }

    var title: String {
        switch self {
        case .none: L10n.string("create.guided.script.none")
        case .custom: L10n.string("create.guided.script.custom")
        case .birthday: L10n.string("create.guided.script.birthday")
        case .congratulations: L10n.string("create.guided.script.congratulations")
        case .love: L10n.string("create.guided.script.love")
        case .missYou: L10n.string("create.guided.script.missYou")
        case .holiday: L10n.string("create.guided.script.holiday")
        case .motivation: L10n.string("create.guided.script.motivation")
        case .funny: L10n.string("create.guided.script.funny")
        }
    }

    var systemImage: String {
        switch self {
        case .none: "speaker.slash.fill"
        case .custom: "slider.horizontal.3"
        case .birthday: "gift.fill"
        case .congratulations: "party.popper.fill"
        case .love: "heart.fill"
        case .missYou: "paperplane.fill"
        case .holiday: "sparkles"
        case .motivation: "bolt.heart.fill"
        case .funny: "face.smiling.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .none: AVBrandColor.textSecondary
        case .custom: AVBrandColor.accent
        case .birthday: .pink
        case .congratulations: .orange
        case .love: .red
        case .missYou: .blue
        case .holiday: .purple
        case .motivation: .teal
        case .funny: AVBrandColor.accent
        }
    }

    var defaultMessage: String {
        switch self {
        case .none, .custom: ""
        case .birthday: L10n.string("create.guided.script.birthday.message")
        case .congratulations: L10n.string("create.guided.script.congratulations.message")
        case .love: L10n.string("create.guided.script.love.message")
        case .missYou: L10n.string("create.guided.script.missYou.message")
        case .holiday: L10n.string("create.guided.script.holiday.message")
        case .motivation: L10n.string("create.guided.script.motivation.message")
        case .funny: L10n.string("create.guided.script.funny.message")
        }
    }

    var previewText: String {
        switch self {
        case .none: L10n.string("create.guided.script.none.preview")
        case .custom: L10n.string("create.guided.script.custom.preview")
        default: defaultMessage
        }
    }

    var detail: String {
        previewText
    }

    var styleID: AnimateVideoCreationStyleID {
        switch self {
        case .none, .custom, .motivation:
            return .celebration
        case .birthday:
            return .birthday
        case .congratulations:
            return .milestone
        case .love, .missYou:
            return .favoritePeople
        case .holiday:
            return .familyScenes
        case .funny:
            return .softRoast
        }
    }
}

private struct AnimateCreateGuidedLookTile: View {
    let look: AnimateVideoLook
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        GeometryReader { proxy in
            Button(action: select) {
                tileContent(width: proxy.size.width)
            }
            .buttonStyle(.plain)
        }
        .frame(height: 92)
    }

    private func tileContent(width: CGFloat) -> some View {
            ZStack(alignment: .bottomLeading) {
                Image(look.assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: 92)
                    .clipped()

                LinearGradient(
                    colors: [
                        .black.opacity(0.02),
                        .black.opacity(0.58),
                        .black.opacity(0.78)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Text(look.title)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
                    .shadow(color: .black.opacity(0.45), radius: 4, y: 1)
                    .padding(9)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(.white, AVBrandColor.accent)
                        .padding(7)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            .frame(width: width, height: 92)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? AVBrandColor.accent : AVBrandColor.borderSubtle.opacity(0.58), lineWidth: isSelected ? 2 : 1)
            }
            .shadow(color: AVBrandColor.ink.opacity(isSelected ? 0.14 : 0.08), radius: isSelected ? 8 : 4, y: isSelected ? 4 : 2)
    }
}

private struct AnimateCreateGuidedMessageModeTile: View {
    let title: String
    let detail: String
    let systemImage: String
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(isSelected ? AVBrandColor.accent : AVBrandColor.textSecondary)
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(isSelected ? AVBrandColor.accent : AVBrandColor.textSecondary)
                }
                Text(title)
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(detail)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
            .background(isSelected ? AVBrandColor.accent.opacity(0.08) : AVBrandColor.cardSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? AVBrandColor.accent : AVBrandColor.borderSubtle.opacity(0.75), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AnimateCreateGuidedMotionTile: View {
    let preset: AnimationDirectionPreset
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack(spacing: 6) {
                Image(systemName: preset.systemImage)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(isSelected ? AVBrandColor.accent : AVBrandColor.textSecondary)
                Text(preset.title)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 9)
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .background(isSelected ? AVBrandColor.accent.opacity(0.08) : AVBrandColor.cardSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? AVBrandColor.accent : AVBrandColor.borderSubtle.opacity(0.75), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct AnimateCreateLockedFinalRenderScene: View {
    let presentation: AnimateCreateWorkflowPresentation

    @State private var pulse = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 28)

            VStack(spacing: 14) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .stroke(AVBrandColor.accent.opacity(0.20), lineWidth: 2)
                        .frame(width: 132, height: 132)
                        .scaleEffect(pulse ? 1.10 : 0.94)
                        .opacity(pulse ? 0.16 : 0.82)
                        .animation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true), value: pulse)

                    Image("AviFullBody")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .padding(14)
                        .background(AVBrandColor.accent.opacity(0.10), in: Circle())
                        .accessibilityHidden(true)

                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(AVBrandColor.textPrimary, in: Circle())
                        .overlay(Circle().stroke(AVBrandColor.cardSurface, lineWidth: 3))
                        .symbolEffect(.rotate, options: .repeating, isActive: isRendering)
                }

                VStack(spacing: 7) {
                    Text(statusTitle)
                        .font(.system(size: 30, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.70)

                    Text(detail)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    if isRendering {
                        HStack(spacing: 7) {
                            ProgressView()
                                .controlSize(.mini)
                                .tint(AVBrandColor.accent)

                            Text(L10n.string("create.workflowContent.waitingForProvider"))
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(AVBrandColor.textSecondary)
                        }
                    }

                }
                .frame(maxWidth: .infinity)
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    AnimateCreateLockedRenderMetric(
                        title: L10n.string("create.final.confirmSheet.cost"),
                        value: AnimateCreditCopy.countTitle(presentation.lockedFinalRenderCreditCost),
                        systemImage: "creditcard.fill"
                    )
                    AnimateCreateLockedRenderMetric(
                        title: L10n.string("create.final.confirmSheet.media"),
                        value: mediaCountTitle,
                        systemImage: "photo.stack.fill"
                    )
                }

                AnimateCreateLockedFinalRenderNotice()

                Text(L10n.string("create.workflowContent.renderMayTakeMinutes"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(AVBrandColor.cardSurface.opacity(0.98), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AVBrandColor.borderSubtle.opacity(0.82), lineWidth: 1)
            )

            Spacer(minLength: 76)
        }
        .frame(maxWidth: .infinity, minHeight: 660)
        .padding(.horizontal, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(L10n.string("create.workflowContent.finalVideoInProgressTitle")). \(detail)")
        .onAppear {
            pulse = true
        }
    }

    private var statusTitle: String {
        presentation.finalRenderSummary.realtimeStatus?.title
            ?? L10n.string("create.render.status.working")
    }

    private var detail: String {
        presentation.finalRenderSummary.realtimeStatus?.detail
            ?? L10n.string("create.workflowContent.editingLocked")
    }

    private var systemImage: String {
        presentation.finalRenderSummary.realtimeStatus?.systemImage
            ?? "lock.fill"
    }

    private var isRendering: Bool {
        presentation.finalRenderSummary.realtimeStatus?.isActive ?? true
    }

    private var mediaCountTitle: String {
        presentation.lockedFinalRenderMediaCountTitle
    }

}

private struct AnimateCreateLockedRenderMetric: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(AVBrandColor.accent)
                .frame(width: 24, height: 24)
                .background(AVBrandColor.accent.opacity(0.11), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .black))
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .lineLimit(1)

                Text(value)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AVBrandColor.cardSurface.opacity(0.82), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}

private struct AnimateCreateLockedFinalRenderNotice: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(AVBrandColor.textSecondary)
                .frame(width: 24, height: 24)
                .background(AVBrandColor.neutral100, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.string("create.workflowContent.editingLocked"))
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(L10n.string("workflow.final.creatingVideo"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(11)
        .background(AVBrandColor.neutral100.opacity(0.62), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct AnimateCreateVideoHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.string("create.video.title"))
                .font(.system(size: 30, weight: .black))
                .foregroundStyle(AVBrandColor.textPrimary)

            Text(L10n.string("create.video.subtitle"))
                .font(AVBrandTypography.body)
                .foregroundStyle(AVBrandColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AnimateCreateCompactAviGuide: View {
    let presentation: AnimateCreateWorkflowPresentation
    let isVideoSetupGuideComplete: Bool

    var body: some View {
        AVAppShellCard {
            HStack(alignment: .center, spacing: 14) {
                Image("AviFullBody")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .padding(5)
                    .background(AVBrandColor.accent.opacity(0.10), in: Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)

                    Text(message)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }

    private var title: String {
        if presentation.finalRenderSummary.finalExport != nil {
            return L10n.string("create.aviStatus.ready.title")
        }
        if let realtimeStatus = presentation.finalRenderSummary.realtimeStatus {
            return realtimeStatus.title
        }
        if presentation.videoDirectionSummary.isPlanning {
            return L10n.string("create.aviStatus.preparing.title")
        }
        if presentation.finalRenderSummary.latestFinalJob != nil {
            return L10n.string("create.aviStatus.working.title")
        }
        if isReadyToReviewCredits {
            return L10n.string("create.aviStatus.storyReady.title")
        }
        if hasSelectedMedia, presentation.selectedLook != nil, !isVideoSetupGuideComplete {
            return L10n.string("create.guided.movement.title")
        }
        if hasSelectedMedia {
            return L10n.string("create.aviStatus.goodSelection.title")
        }
        return L10n.string("create.aviStatus.startMedia.title")
    }

    private var message: String {
        if presentation.finalRenderSummary.finalExport != nil {
            return L10n.string("create.aviStatus.exportReady.detail")
        }
        if presentation.videoDirectionSummary.isPlanning {
            return presentation.videoDirectionSummary.statusMessage ?? L10n.string("create.aviStatus.preparing.detail")
        }
        if let realtimeStatus = presentation.finalRenderSummary.realtimeStatus {
            return realtimeStatus.detail
        }
        if isReadyToReviewCredits {
            return L10n.string("create.aviStatus.storyReady.detail")
        }
        if hasSelectedMedia, presentation.selectedLook != nil, !isVideoSetupGuideComplete {
            return L10n.string("create.guided.movement.detail")
        }
        if hasSelectedMedia {
            return L10n.string("create.aviStatus.goodSelection.detail")
        }
        return L10n.string("create.aviStatus.startMedia.detail")
    }

    private var hasSelectedMedia: Bool {
        presentation.mediaSummary.selectedMedia.contains { media in
            (media.kind == "photo" || media.kind == "image")
                && UIImage(data: media.data) != nil
        }
    }

    private var isReadyToReviewCredits: Bool {
        hasSelectedMedia
            && presentation.selectedLook != nil
            && (
                presentation.finalRenderSummary.renderPlan != nil
                    || presentation.finalRenderSummary.videoQuote != nil
                    || isVideoSetupGuideComplete
            )
    }
}

private struct AnimateCreatePrimaryActionBar: View {
    let presentation: AnimateCreateWorkflowPresentation
    let startSignInFlow: () -> Void
    let openCredits: () -> Void
    let prepareVideoDirection: () -> Void
    let generateFinalRender: () -> Void
    let continueFromCompletedVideoSetupGuide: () -> Void
    let continueVideoSetup: () -> Void
    let choosePhoto: () -> Void
    let isVideoSetupGuideComplete: Bool
    let openCreateVideoConfirmation: () -> Void
    let retryFinalVideoDownload: () -> Void
    let finishFinalVideoToGallery: () -> Void

    @ViewBuilder
    var body: some View {
        if showsFinalVideoDock {
            AnimateCreateFinalVideoActionDock(
                presentation: presentation,
                downloadTitle: finalVideoDownloadButtonTitle,
                download: retryFinalVideoDownload,
                finish: finishFinalVideoToGallery
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        } else {
            VStack(alignment: .leading, spacing: 10) {
                if presentation.finalRenderSummary.finalExport == nil,
                   let realtimeStatus = presentation.finalRenderSummary.realtimeStatus {
                    AnimateCreateRealtimeRenderStatusPanel(status: realtimeStatus)
                }

                HStack(alignment: .center, spacing: 10) {
                    ZStack {
                        Image(systemName: primaryActionPresentation.primaryHeaderIconName)
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(primaryHeaderColor, in: Circle())
                            .opacity(presentation.finalRenderSummary.isPreparingPlan ? 0 : 1)

                        if presentation.finalRenderSummary.isPreparingPlan {
                            ProgressView()
                                .tint(primaryHeaderColor)
                                .controlSize(.small)
                        }
                    }
                    .frame(width: 32, height: 32)

                    VStack(alignment: .leading, spacing: 3) {
                        if showsPrimaryHeaderTitle {
                            Text(primaryTitle)
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(AVBrandColor.textPrimary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Text(primaryStatusMessage)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(statusColor)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                }

                if primaryActionPresentation.showsPrimaryActionButton {
                    Button(action: primaryAction) {
                        HStack(spacing: 8) {
                            if presentation.finalRenderSummary.isPreparingPlan {
                                ProgressView()
                                    .tint(.white)
                                    .controlSize(.small)
                            } else {
                                Image(systemName: primaryButtonIconName)
                            }

                            Text(primaryButtonTitle)
                        }
                        .font(.system(size: 15, weight: .black))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                    }
                    .disabled(!canRunPrimaryAction)
                    .buttonStyle(AnimateCreateFinalVideoButtonStyle())
                }

                if let uploadProgress = presentation.mediaSummary.importProgress,
                   presentation.mediaSummary.isImporting {
                    ProgressView(value: uploadProgress.fractionCompleted ?? 0)
                        .tint(AVBrandColor.accent)
                        .accessibilityLabel(L10n.string("create.workflowContent.uploadingMedia"))
                        .accessibilityValue(uploadProgress.title)
                }

                if presentation.finalRenderSummary.pendingGalleryVideo != nil {
                    VStack(spacing: 10) {
                        Button(action: finishFinalVideoToGallery) {
                            Label(L10n.string("create.final.finishGallery"), systemImage: "checkmark.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(AnimateCreateSoftActionButtonStyle())
                    }
                    .font(.system(size: 14, weight: .black))
                } else if presentation.finalRenderSummary.finalExport != nil {
                    VStack(spacing: 10) {
                        Button(action: retryFinalVideoDownload) {
                            Label(finalVideoDownloadButtonTitle, systemImage: "arrow.down.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(AnimateCreateSoftActionButtonStyle())
                    }
                    .font(.system(size: 14, weight: .black))
                } else if presentation.finalRenderSummary.canRetryFinalVideoDownload {
                    Button(action: retryFinalVideoDownload) {
                        Label(L10n.string("create.workflowContent.retryFinalDownload"), systemImage: "arrow.down.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(AnimateCreateSoftActionButtonStyle())
                    .font(.system(size: 14, weight: .black))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AVBrandColor.borderSubtle.opacity(0.56), lineWidth: 1)
            }
        }
    }

    private var showsFinalVideoDock: Bool {
        presentation.finalRenderSummary.finalExport != nil
            || presentation.finalRenderSummary.pendingGalleryVideo != nil
    }

    private var primaryActionPresentation: AnimateCreatePrimaryActionPresentation {
        AnimateCreatePrimaryActionPresentation(workflow: presentation)
    }

    private var finalVideoDownloadButtonTitle: String {
        presentation.finalRenderSummary.canRetryFinalVideoDownload
            ? L10n.string("create.workflowContent.retryFinalDownload")
            : L10n.string("create.final.downloadVideo")
    }

    private var statusColor: Color {
        if presentation.finalRenderSummary.finalExport != nil {
            return AVBrandColor.accent
        }
        return AVBrandColor.textSecondary
    }

    private var primaryTitle: String {
        guard hasRenderablePhoto else {
            return L10n.string("create.guided.photoFrame.title")
        }
        guard primaryActionPresentation.hasSelectedVideoLook else {
            return L10n.string("create.guided.look.noneSelected.title")
        }
        guard isVideoSetupGuideComplete else {
            return L10n.string("create.guided.movement.title")
        }
        return guideIsReadyToPrepareDirection ? L10n.string("create.primary.continueWithVideo") : primaryActionPresentation.title
    }

    private var primaryButtonTitle: String {
        guard hasRenderablePhoto else {
            return L10n.string("create.media.choose")
        }
        guard primaryActionPresentation.hasSelectedVideoLook else {
            return L10n.string("create.guided.look.noneSelected.title")
        }
        guard isVideoSetupGuideComplete else {
            return L10n.string("create.guided.continue.movement")
        }
        return guideIsReadyToPrepareDirection ? L10n.string("create.primary.continueWithVideo") : primaryActionPresentation.buttonTitle
    }

    private var primaryButtonIconName: String {
        guard hasRenderablePhoto else {
            return "photo.badge.plus"
        }
        guard primaryActionPresentation.hasSelectedVideoLook else {
            return "paintbrush.pointed.fill"
        }
        guard isVideoSetupGuideComplete else {
            return "camera.aperture"
        }
        return guideIsReadyToPrepareDirection ? "video.fill" : primaryActionPresentation.buttonIconName
    }

    private var primaryStatusMessage: String {
        if presentation.finalRenderSummary.latestFinalJob?.isTerminalFailure == true {
            return L10n.string("create.final.recovery.retryHint")
        }
        guard hasRenderablePhoto else {
            return L10n.string("create.guided.photoFrame.empty")
        }
        guard primaryActionPresentation.hasSelectedVideoLook else {
            return L10n.string("create.guided.look.noneSelected.detail")
        }
        guard isVideoSetupGuideComplete else {
            return L10n.string("create.guided.movement.detail")
        }
        return guideIsReadyToPrepareDirection
            ? L10n.string("create.primary.continuePreflight")
            : primaryActionPresentation.statusMessage ?? L10n.string("create.primary.creditPreflight")
    }

    private var guideIsReadyToPrepareDirection: Bool {
        hasRenderablePhoto
            && primaryActionPresentation.hasFinalVideoIntent
            && !primaryActionPresentation.hasCompletedVideoDirection
            && primaryActionPresentation.hasSelectedVideoLook
            && isVideoSetupGuideComplete
    }

    private var canRunPrimaryAction: Bool {
        hasRenderablePhoto ? primaryActionPresentation.canRunPrimaryAction : true
    }

    private var hasRenderablePhoto: Bool {
        presentation.mediaSummary.selectedMedia.contains { media in
            (media.kind == "photo" || media.kind == "image")
                && UIImage(data: media.data) != nil
        }
    }

    private var primaryHeaderColor: Color {
        if presentation.finalRenderSummary.pendingGalleryVideo != nil {
            return AVBrandColor.accent
        }
        if presentation.finalRenderSummary.finalExport != nil {
            return AVBrandColor.accent
        }
        if presentation.finalRenderSummary.latestFinalJob != nil || primaryActionPresentation.isBusy {
            return AVBrandColor.textSecondary
        }
        return AVBrandColor.textPrimary
    }

    private var showsPrimaryHeaderTitle: Bool {
        primaryTitle != primaryButtonTitle
    }

    private func primaryAction() {
        guard hasRenderablePhoto else {
            choosePhoto()
            return
        }
        if presentation.finalRenderSummary.pendingGalleryVideo != nil {
            return
        }
        if presentation.finalRenderSummary.finalExport != nil {
            return
        }
        if primaryActionPresentation.hasRetryableFinalRenderJob {
            generateFinalRender()
        } else if presentation.finalRenderSummary.latestFinalJob != nil {
            return
        } else if !primaryActionPresentation.hasSelectedVideoLook || !isVideoSetupGuideComplete {
            continueVideoSetup()
        } else if primaryActionPresentation.hasFinalVideoIntent {
            if primaryActionPresentation.needsSignInForVideoDirection
                || primaryActionPresentation.needsSignInForFinalRender {
                startSignInFlow()
            } else if !primaryActionPresentation.hasCompletedVideoDirection {
                if guideIsReadyToPrepareDirection {
                    continueFromCompletedVideoSetupGuide()
                } else {
                    continueVideoSetup()
                }
            } else if primaryActionPresentation.needsCreditsForPreparedPlan {
                openCreateVideoConfirmation()
            } else if primaryActionPresentation.finalVideoAction.hasRenderPlan {
                openCreateVideoConfirmation()
            } else {
                generateFinalRender()
            }
        } else if primaryActionPresentation.needsSignInForVideoDirection {
            startSignInFlow()
        }
    }
}

private struct AnimateCreateFinalVideoActionDock: View {
    let presentation: AnimateCreateWorkflowPresentation
    let downloadTitle: String
    let download: () -> Void
    let finish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: action) {
                Label(buttonTitle, systemImage: buttonIconName)
                    .font(.system(size: 16, weight: .black))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
            }
            .buttonStyle(AnimateCreateFinalVideoButtonStyle())
        }
        .padding(10)
        .background {
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.56),
                            AVBrandColor.accent.opacity(0.10),
                            AVBrandColor.accent.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            Capsule(style: .continuous)
                .stroke(AVBrandColor.glassStroke.opacity(0.78), lineWidth: 1)
        }
        .shadow(color: AVBrandColor.glassShadow.opacity(0.82), radius: 20, y: 8)
        .accessibilityElement(children: .contain)
    }

    private var isReadyToFinish: Bool {
        presentation.finalRenderSummary.pendingGalleryVideo != nil
    }

    private var buttonTitle: String {
        isReadyToFinish ? L10n.string("create.final.viewInGallery") : downloadTitle
    }

    private var buttonIconName: String {
        isReadyToFinish ? "checkmark.circle.fill" : "arrow.down.to.line.compact"
    }

    private var action: () -> Void {
        isReadyToFinish ? finish : download
    }
}

private struct AnimateCreateFinalVideoButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isEnabled ? Color(red: 0.37, green: 0.74, blue: 0.24) : Color(red: 0.88, green: 0.90, blue: 0.86))
            }
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .brightness(configuration.isPressed && isEnabled ? -0.04 : 0)
    }
}

private struct AnimateCreateFinalVideoConfirmationSheet: View {
    let action: AnimateCreateFinalVideoActionPresentation
    let mediaSummary: AnimateCreateMediaSummary
    let isPreparingPlan: Bool
    let confirm: (Bool) -> Void
    let openCredits: () -> Void
    let cancel: () -> Void
    @State private var removesWatermark: Bool
    @State private var isSubmitting = false

    init(
        action: AnimateCreateFinalVideoActionPresentation,
        mediaSummary: AnimateCreateMediaSummary,
        isPreparingPlan: Bool,
        confirm: @escaping (Bool) -> Void,
        openCredits: @escaping () -> Void,
        cancel: @escaping () -> Void
    ) {
        self.action = action
        self.mediaSummary = mediaSummary
        self.isPreparingPlan = isPreparingPlan
        self.confirm = confirm
        self.openCredits = openCredits
        self.cancel = cancel
        _removesWatermark = State(initialValue: action.summary.renderPlan?.watermark?.selectedRemoveWatermark ?? false)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            sheetContent
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 18)
        }
        .presentationBackground(AnimateTheme.shellBackground)
    }

    private var sheetContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            if showsPlanPreparation {
                checkingCostContent
            } else {
            VStack(spacing: 8) {
                AnimateCreateConfirmationMetric(
                    title: L10n.string("create.final.confirmSheet.cost"),
                    value: selectedCreditCostTitle,
                    systemImage: "creditcard.fill"
                )
                AnimateCreateConfirmationMetric(
                    title: L10n.string("create.final.confirmSheet.media"),
                    value: mediaUsageTitle,
                    systemImage: "photo.stack"
                )
                AnimateCreateConfirmationMetric(
                    title: L10n.string("create.final.confirmSheet.duration"),
                    value: durationTitle,
                    systemImage: "timer"
                )
                AnimateCreateConfirmationMetric(
                    title: L10n.string("create.final.confirmSheet.watermark"),
                    value: watermarkTitle,
                    systemImage: "seal"
                )
            }

            costDetails

            watermarkControl

            Text(confirmationMessage)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AVBrandColor.textSecondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                primaryActionButton

                Button(action: cancel) {
                    Text(L10n.string("create.action.notNow"))
                        .font(.system(size: 14, weight: .black))
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                }
                .buttonStyle(AnimateCreateNeutralInlineButtonStyle())
            }
            }
        }
    }

    private var checkingCostContent: some View {
        VStack(spacing: 14) {
            VStack(spacing: 12) {
                checkingCostThumbnail

                VStack(spacing: 5) {
                    Text(L10n.string("create.final.checkingCost"))
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(L10n.string("workflow.final.checkingPlan"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ProgressView()
                    .tint(AVBrandColor.accent)
                    .controlSize(.regular)
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(AVBrandColor.mutedSurface.opacity(0.62), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(AVBrandColor.accent)
                    .frame(width: 30, height: 30)
                    .background(AVBrandColor.accent.opacity(0.10), in: Circle())

                Text(L10n.string("create.final.costDetails.chargedOnCompletion"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.64), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AVBrandColor.borderSubtle.opacity(0.42), lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private var checkingCostThumbnail: some View {
        ZStack(alignment: .bottomTrailing) {
            Circle()
                .fill(AVBrandColor.accent.opacity(0.10))
                .frame(width: 68, height: 68)

            Image("AviFullBody")
                .resizable()
                .scaledToFit()
                .frame(width: 58, height: 58)
                .offset(y: 2)

            Image(systemName: "creditcard.fill")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(AVBrandColor.textPrimary, in: Circle())
                .overlay {
                    Circle()
                        .stroke(.white.opacity(0.9), lineWidth: 1)
                }
        }
        .frame(width: 68, height: 68)
        .shadow(color: AVBrandColor.ink.opacity(0.08), radius: 8, x: 0, y: 4)
    }

    private var primaryActionButton: some View {
        Button(action: runPrimaryAction) {
            HStack(spacing: 8) {
                if isSubmitting {
                    ProgressView()
                        .controlSize(.small)
                        .tint(AVBrandColor.textPrimary)
                } else {
                    Image(systemName: primaryActionIconName)
                }

                Text(isSubmitting ? L10n.string("workflow.final.creatingVideo") : primaryActionTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .font(.system(size: 15, weight: .black))
            .foregroundStyle(AVBrandColor.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(AVBrandColor.accent.opacity(0.1), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(AVBrandColor.accent.opacity(0.24), lineWidth: 1)
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isSubmitting)
        .accessibilityLabel(primaryActionTitle)
    }

    private func runPrimaryAction() {
        guard !isSubmitting else { return }
        isSubmitting = true
        if canAffordSelectedCost {
            confirm(removesWatermark)
        } else {
            openCredits()
        }
    }

    private var costDetails: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.string("create.final.costDetails.title"))
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(AVBrandColor.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: 7) {
                AnimateCreateCostDetailRow(
                    title: L10n.string("create.final.costDetails.video"),
                    detail: durationTitle,
                    value: AnimateCreditCopy.countTitle(plan?.creditCost ?? action.totalCreditCost)
                )

                AnimateCreateCostDetailRow(
                    title: L10n.string("create.final.costDetails.watermark"),
                    detail: watermarkCostDetail,
                    value: watermarkCostTitle
                )

                Divider()
                    .overlay(AVBrandColor.textSecondary.opacity(0.14))

                AnimateCreateCostDetailRow(
                    title: L10n.string("create.final.costDetails.total"),
                    detail: L10n.string("create.final.costDetails.chargedOnCompletion"),
                    value: selectedCreditCostTitle,
                    isTotal: true
                )
            }
            .padding(12)
            .background(AVBrandColor.mutedSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: showsPlanPreparation ? "creditcard.fill" : "video.fill")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(AVBrandColor.textPrimary, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(showsPlanPreparation ? L10n.string("create.final.checkingCost") : L10n.string("create.final.confirmSheet.title"))
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(showsPlanPreparation ? L10n.string("workflow.final.checkingPlan") : L10n.string("create.final.confirmSheet.detail"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var plan: AnimateRenderPlan? {
        action.summary.renderPlan?.plan
    }

    private var showsPlanPreparation: Bool {
        isPreparingPlan || !action.canShowConfirmationSheet
    }

    private var watermark: AnimateRenderWatermarkPlan? {
        action.summary.renderPlan?.watermark
    }

    private var selectedCreditCost: Int {
        if let videoQuote = action.summary.videoQuote {
            if removesWatermark,
               !videoQuote.branding.removalIncluded,
               !videoQuote.branding.removalRequested {
                return videoQuote.baseCreditCost + brandingRemovalOptionCreditCost
            }
            return videoQuote.totalCreditCost
        }
        let baseCost = plan?.creditCost ?? action.totalCreditCost
        guard removesWatermark,
              watermark?.userHasWatermarkFree != true else {
            return plan?.totalCreditCost ?? action.totalCreditCost
        }
        return baseCost + brandingRemovalOptionCreditCost
    }

    private var brandingRemovalOptionCreditCost: Int {
        if let videoQuote = action.summary.videoQuote {
            if videoQuote.branding.removalIncluded {
                return 0
            }
            if videoQuote.brandingRemovalCreditCost > 0 {
                return videoQuote.brandingRemovalCreditCost
            }
        }
        if watermark?.userHasWatermarkFree == true {
            return 0
        }
        if let nonProRemovalCreditCost = watermark?.nonProRemovalCreditCost,
           nonProRemovalCreditCost > 0 {
            return nonProRemovalCreditCost
        }
        return max(1, action.balance.watermarkRemovalCreditCost)
    }

    private var selectedCreditCostTitle: String {
        AnimateCreditCopy.countTitle(selectedCreditCost)
    }

    private var confirmationActionTitle: String {
        L10n.string("create.final.createWithCost", selectedCreditCostTitle)
    }

    private var primaryActionTitle: String {
        canAffordSelectedCost ? confirmationActionTitle : L10n.string("credits.get.title")
    }

    private var primaryActionIconName: String {
        canAffordSelectedCost ? "video.fill" : "plus.circle.fill"
    }

    private var confirmationMessage: String {
        if canAffordSelectedCost {
            return L10n.string("create.final.confirmMessage", selectedCreditCostTitle)
        }
        let missingCredits = max(0, selectedCreditCost - action.balance.spendable)
        return AnimateCreateAvailabilityCopy.finalRenderInsufficientCredits(missingCredits: missingCredits)
    }

    private var canAffordSelectedCost: Bool {
        action.balance.spendable >= selectedCreditCost
    }

    @ViewBuilder
    private var watermarkControl: some View {
        if let videoQuote = action.summary.videoQuote {
            if videoQuote.branding.removalAvailable && !videoQuote.branding.removalIncluded {
                Toggle(isOn: $removesWatermark) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.string(
                            "create.final.watermark.remove",
                            AnimateCreditCopy.countTitle(brandingRemovalOptionCreditCost)
                        ))
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)

                        Text(L10n.string("create.final.watermark.removeDetail"))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(AVBrandColor.textSecondary)
                    }
                }
                .toggleStyle(.switch)
            }
        } else if watermark?.userHasWatermarkFree == true {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(AVBrandColor.accent)
                Text(L10n.string("create.final.watermark.proIncluded"))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AVBrandColor.textSecondary)
            }
        } else if watermark != nil {
            Toggle(isOn: $removesWatermark) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.string(
                        "create.final.watermark.remove",
                        AnimateCreditCopy.countTitle(brandingRemovalOptionCreditCost)
                    ))
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)

                    Text(L10n.string("create.final.watermark.removeDetail"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(AVBrandColor.textSecondary)
                }
            }
            .toggleStyle(.switch)
        }
    }

    private var watermarkTitle: String {
        if let videoQuote = action.summary.videoQuote {
            if videoQuote.branding.removalIncluded || videoQuote.branding.removalRequested || removesWatermark {
                return L10n.string("create.final.watermark.none")
            }
            return videoQuote.branding.included
                ? L10n.string("create.final.watermark.included")
                : L10n.string("create.final.watermark.none")
        }
        if watermark?.userHasWatermarkFree == true || removesWatermark {
            return L10n.string("create.final.watermark.none")
        }
        return L10n.string("create.final.watermark.included")
    }

    private var watermarkCostTitle: String {
        if let videoQuote = action.summary.videoQuote {
            if videoQuote.branding.removalIncluded {
                return L10n.string("create.final.costDetails.includedWithPro")
            }
            if videoQuote.branding.removalRequested || removesWatermark {
                return AnimateCreditCopy.countTitle(brandingRemovalOptionCreditCost)
            }
            return L10n.string("create.final.costDetails.noExtraCost")
        }
        if watermark?.userHasWatermarkFree == true {
            return L10n.string("create.final.costDetails.includedWithPro")
        }
        if removesWatermark {
            return AnimateCreditCopy.countTitle(brandingRemovalOptionCreditCost)
        }
        return L10n.string("create.final.costDetails.noExtraCost")
    }

    private var watermarkCostDetail: String {
        if let videoQuote = action.summary.videoQuote {
            if videoQuote.branding.removalIncluded {
                return L10n.string("create.final.watermark.proIncluded")
            }
            if videoQuote.branding.removalRequested || removesWatermark {
                return L10n.string("create.final.watermark.removeDetail")
            }
            return L10n.string("create.final.costDetails.watermarkIncluded")
        }
        if watermark?.userHasWatermarkFree == true {
            return L10n.string("create.final.watermark.proIncluded")
        }
        if removesWatermark {
            return L10n.string("create.final.watermark.removeDetail")
        }
        return L10n.string("create.final.costDetails.watermarkIncluded")
    }

    private var mediaUsageTitle: String {
        guard let plan else {
            return L10n.string("create.final.confirmSheet.mediaPending")
        }
        let currentMediaCount = mediaSummary.effectiveMediaCount
        if currentMediaCount > 0, currentMediaCount != plan.plannedAssetCount {
            return L10n.string("create.workflowContent.assetUsageItems", currentMediaCount, currentMediaCount)
        }
        if plan.rejectedAssetCount > 0 {
            return L10n.string("create.workflowContent.assetUsageSkipped", plan.usedAssetCount, plan.rejectedAssetCount)
        }
        return L10n.string("create.workflowContent.assetUsageItems", plan.usedAssetCount, plan.plannedAssetCount)
    }

    private var durationTitle: String {
        guard let plan else {
            return L10n.string("create.workflowContent.beforeVideo")
        }
        if let minimumDurationMs = plan.minimumDurationMs,
           minimumDurationMs > 0,
           minimumDurationMs < plan.targetDurationMs {
            return L10n.string(
                "create.final.confirmSheet.durationRange",
                minimumDurationMs / 1000,
                plan.targetDurationMs / 1000
            )
        }
        return L10n.string("create.final.confirmSheet.upToSeconds", plan.targetDurationMs / 1000)
    }
}

private struct AnimateCreateCostDetailRow: View {
    let title: String
    let detail: String
    let value: String
    var isTotal = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: isTotal ? 13 : 12, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)

                Text(detail)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 10)

            Text(value)
                .font(.system(size: isTotal ? 13 : 12, weight: .black))
                .foregroundStyle(AVBrandColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
    }
}

private struct AnimateCreateConfirmationMetric: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(AVBrandColor.accent)
                .frame(width: 22, height: 22)
                .background(AVBrandColor.accent.opacity(0.10), in: Circle())

            Text(title)
                .font(.system(size: 11, weight: .black))
                .foregroundStyle(AVBrandColor.textSecondary)

            Spacer(minLength: 10)

            Text(value)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(AVBrandColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 8)
        .background(AVBrandColor.mutedSurface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct AnimateCreateRealtimeRenderStatusPanel: View {
    let status: AnimateRenderRealtimePresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 9) {
                Image(systemName: status.systemImage)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(iconColor)
                    .frame(width: 24, height: 24)
                    .background(iconColor.opacity(0.12), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(status.title)
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)

                    Text(status.detail)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if status.isActive && !status.canEditSetup {
                Label(L10n.string("create.workflowContent.editingLocked"), systemImage: "lock.fill")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AVBrandColor.neutral100.opacity(0.70), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var iconColor: Color {
        status.isActive ? AVBrandColor.accent : AVBrandColor.textSecondary
    }
}

private struct AnimateCreateTwoColumnGrid<Item: Identifiable, Content: View>: View {
    let items: [Item]
    var horizontalSpacing: CGFloat = 12
    var verticalSpacing: CGFloat = 12
    var itemHeight: CGFloat = 106
    let content: (Item) -> Content

    var body: some View {
        LazyVGrid(columns: columns, alignment: .center, spacing: verticalSpacing) {
            ForEach(items) { item in
                content(item)
                    .frame(width: itemWidth, height: itemHeight)
                    .clipped()
            }
        }
        .frame(width: gridWidth, alignment: .center)
        .frame(maxWidth: .infinity)
    }

    private var gridWidth: CGFloat {
        max(280, UIScreen.main.bounds.width - 40)
    }

    private var itemWidth: CGFloat {
        floor((gridWidth - horizontalSpacing) / 2)
    }

    private var columns: [GridItem] {
        [
            GridItem(.fixed(itemWidth), spacing: horizontalSpacing, alignment: .top),
            GridItem(.fixed(itemWidth), spacing: 0, alignment: .top)
        ]
    }
}

private struct AnimateCreateLookChooserPage: View {
    let selectedLook: AnimateVideoLook?
    let selectLook: (AnimateVideoLook) -> Void
    let dismiss: () -> Void

    @State private var setupLook: AnimateVideoLook?
    @State private var selectedFamily: AnimateVideoLookFamily?

    private var families: [AnimateVideoLookFamily] {
        AnimateVideoLook.families
    }

    private var selectedFamilyIndex: Int? {
        guard let selectedFamily else { return nil }
        return families.firstIndex(where: { $0.id == selectedFamily.id })
    }

    init(
        selectedLook: AnimateVideoLook?,
        selectLook: @escaping (AnimateVideoLook) -> Void,
        dismiss: @escaping () -> Void
    ) {
        self.selectedLook = selectedLook
        self.selectLook = selectLook
        self.dismiss = dismiss
        _setupLook = State(initialValue: selectedLook)
        _selectedFamily = State(initialValue: selectedLook.map { AnimateVideoLook.family(containing: $0) })
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                AnimateCreateChooserHeader(
                    title: L10n.string("create.selector.look.title"),
                    dismiss: dismiss
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 14)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        AVAppShellCard {
                            HStack(spacing: 12) {
                                Image("AviFullBody")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 42, height: 42)
                                    .padding(4)
                                    .background(AVBrandColor.accent.opacity(0.10), in: Circle())
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(L10n.string("create.selector.look.intro.title"))
                                        .font(.system(size: 14, weight: .black))
                                        .foregroundStyle(AVBrandColor.textPrimary)

                                    Text(L10n.string("create.selector.look.intro.detail"))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AVBrandColor.textSecondary)
                                        .lineLimit(2)
                                }

                                Spacer(minLength: 0)
                            }
                        }

                        if let selectedFamily {
                            Button {
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
                                    self.selectedFamily = nil
                                }
                            } label: {
                                Label(L10n.string("create.look.family.back"), systemImage: "chevron.left.circle.fill")
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundStyle(AVBrandColor.textSecondary)
                            }
                            .buttonStyle(.plain)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(selectedFamily.title)
                                    .font(.system(size: 20, weight: .black))
                                    .foregroundStyle(AVBrandColor.textPrimary)
                                Text(selectedFamily.subtitle)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(AVBrandColor.textSecondary)
                            }

                            AnimateCreateLookFamilyNavigator(
                                family: selectedFamily,
                                familyIndex: selectedFamilyIndex ?? 0,
                                familyCount: families.count,
                                previous: selectPreviousFamily,
                                next: selectNextFamily
                            )

                            VStack(spacing: 14) {
                                AnimateCreateLookFamilyRail(
                                    families: families,
                                    selectedFamily: selectedFamily,
                                    setupLook: setupLook,
                                    selectFamily: selectFamily
                                )

                                AnimateCreateTwoColumnGrid(items: selectedFamily.looks) { look in
                                    AnimateCreateLookImageTile(
                                        look: look,
                                        isSelected: setupLook == look,
                                        selectLook: { setupLook = look }
                                    )
                                }
                            }
                            .contentShape(Rectangle())
                            .gesture(familySwipeGesture)
                        } else {
                            AnimateCreateTwoColumnGrid(items: families, itemHeight: 118) { family in
                                AnimateCreateLookFamilyTile(
                                    family: family,
                                    isSelected: family.looks.contains(where: { $0 == setupLook }),
                                    select: {
                                        selectFamily(family)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .safeAreaPadding(.bottom, 200)
                }
                .scrollIndicators(.hidden)
            }

            AnimateCreateFixedFooterAction(
                title: L10n.string("common.done"),
                systemImage: "checkmark.circle.fill",
                action: applySelection
            )
            .disabled(setupLook == nil)
            .opacity(setupLook == nil ? 0.62 : 1)
            .padding(.horizontal, 20)
            .padding(.bottom, 96)
        }
        .background(AnimateTheme.shellBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func applySelection() {
        guard let setupLook else { return }
        selectLook(setupLook)
        dismiss()
    }

    private var familySwipeGesture: some Gesture {
        DragGesture(minimumDistance: 28)
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > abs(vertical), abs(horizontal) > 44 else { return }

                if horizontal < 0 {
                    selectNextFamily()
                } else {
                    selectPreviousFamily()
                }
            }
    }

    private func selectFamily(_ family: AnimateVideoLookFamily) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.88)) {
            selectedFamily = family
            if setupLook.map({ family.looks.contains($0) }) != true {
                setupLook = family.looks.first
            }
        }
    }

    private func selectPreviousFamily() {
        guard let index = selectedFamilyIndex else { return }
        let previousIndex = index == 0 ? families.count - 1 : index - 1
        selectFamily(families[previousIndex])
    }

    private func selectNextFamily() {
        guard let index = selectedFamilyIndex else { return }
        let nextIndex = index == families.count - 1 ? 0 : index + 1
        selectFamily(families[nextIndex])
    }
}

private struct AnimateCreateLookFamilyNavigator: View {
    let family: AnimateVideoLookFamily
    let familyIndex: Int
    let familyCount: Int
    let previous: () -> Void
    let next: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            navigationButton(
                systemImage: "chevron.left",
                accessibilityLabel: L10n.string("create.images.looks.previousPage"),
                action: previous
            )

            VStack(spacing: 2) {
                Text(family.title)
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)
                    .lineLimit(1)

                Text("\(familyIndex + 1) / \(familyCount)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AVBrandColor.textSecondary)
            }
            .frame(maxWidth: .infinity)

            navigationButton(
                systemImage: "chevron.right",
                accessibilityLabel: L10n.string("create.images.looks.nextPage"),
                action: next
            )
        }
        .padding(10)
        .background(AVBrandColor.cardSurface.opacity(0.72), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AVBrandColor.borderSubtle.opacity(0.5), lineWidth: 1)
        }
    }

    private func navigationButton(
        systemImage: String,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .black))
                .foregroundStyle(AVBrandColor.textPrimary)
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.92), in: Circle())
                .shadow(color: AVBrandColor.ink.opacity(0.06), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct AnimateCreateLookFamilyRail: View {
    let families: [AnimateVideoLookFamily]
    let selectedFamily: AnimateVideoLookFamily
    let setupLook: AnimateVideoLook?
    let selectFamily: (AnimateVideoLookFamily) -> Void

    var body: some View {
        HStack(spacing: 0) {
            let indexedFamilies = Array(families.enumerated())
            ForEach(indexedFamilies, id: \.element.id) { index, family in
                familyButton(family)

                if index < indexedFamilies.count - 1 {
                    Spacer(minLength: 10)
                }
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 4)
    }

    private func familyButton(_ family: AnimateVideoLookFamily) -> some View {
        Button {
            selectFamily(family)
        } label: {
            Image(systemName: family.systemImage)
                .font(.system(size: 13, weight: .black))
                .foregroundStyle(iconColor(for: family))
                .frame(width: 34, height: 34)
                .background(backgroundColor(for: family), in: Circle())
                .overlay {
                    Circle()
                        .stroke(borderColor(for: family), lineWidth: selectedFamily.id == family.id ? 2 : 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.string("create.look.family.accessibility", family.title))
    }

    private func iconColor(for family: AnimateVideoLookFamily) -> Color {
        selectedFamily.id == family.id ? AVBrandColor.textInverse : AVBrandColor.textSecondary
    }

    private func backgroundColor(for family: AnimateVideoLookFamily) -> Color {
        if selectedFamily.id == family.id {
            return AVBrandColor.accent
        }

        if family.looks.contains(where: { $0 == setupLook }) {
            return AVBrandColor.accent.opacity(0.14)
        }

        return AVBrandColor.cardSurface.opacity(0.82)
    }

    private func borderColor(for family: AnimateVideoLookFamily) -> Color {
        if selectedFamily.id == family.id {
            return AVBrandColor.accent.opacity(0.55)
        }

        if family.looks.contains(where: { $0 == setupLook }) {
            return AVBrandColor.accent.opacity(0.34)
        }

        return AVBrandColor.borderSubtle.opacity(0.68)
    }
}

private struct AnimateCreateLookFamilyTile: View {
    let family: AnimateVideoLookFamily
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        GeometryReader { proxy in
            Button(action: select) {
                ZStack(alignment: .bottomLeading) {
                    Image(family.heroAssetName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()

                    LinearGradient(
                        colors: [.black.opacity(0.04), .black.opacity(0.50), .black.opacity(0.82)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundStyle(.white, AVBrandColor.accent)
                                    .accessibilityHidden(true)
                            } else {
                                Image(systemName: family.systemImage)
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundStyle(.white)
                                    .accessibilityHidden(true)
                            }

                            Text(family.title)
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.72)
                        }

                        Text(family.subtitle)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.84))
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isSelected ? AVBrandColor.accent : AVBrandColor.borderSubtle.opacity(0.7), lineWidth: isSelected ? 2 : 1)
                }
                .shadow(color: AVBrandColor.ink.opacity(isSelected ? 0.12 : 0.05), radius: isSelected ? 8 : 4, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.string("create.look.family.accessibility", family.title))
        }
    }
}

private struct AnimateCreateLookImageTile: View {
    let look: AnimateVideoLook
    let isSelected: Bool
    let selectLook: () -> Void

    private let tileHeight: CGFloat = 112

    var body: some View {
        GeometryReader { proxy in
            Button(action: selectLook) {
                tileContent(width: proxy.size.width)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.string("create.selector.look.accessibility", look.title))
        }
        .frame(height: tileHeight)
    }

    private func tileContent(width: CGFloat) -> some View {
            ZStack(alignment: .bottomLeading) {
                Image(look.assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: tileHeight)
                    .clipped()

                LinearGradient(
                    colors: [.black.opacity(0.02), .black.opacity(0.28), .black.opacity(0.80)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(.white, AVBrandColor.accent)
                                .accessibilityHidden(true)
                        }

                        Text(look.title)
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }

                    Text(look.subtitle)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: width, height: tileHeight)
            .background(AVBrandColor.neutral100, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? AVBrandColor.accent : AVBrandColor.borderSubtle.opacity(0.7), lineWidth: isSelected ? 2 : 1)
            }
            .shadow(color: AVBrandColor.ink.opacity(isSelected ? 0.12 : 0.05), radius: isSelected ? 8 : 4, x: 0, y: 3)
    }
}

private struct AnimateCreateVisualOptionChooserPage<Content: View>: View {
    let title: String
    let introTitle: String
    let introDetail: String
    let dismiss: () -> Void
    let confirm: () -> Void
    let content: () -> Content

    init(
        title: String,
        introTitle: String,
        introDetail: String,
        dismiss: @escaping () -> Void,
        confirm: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.introTitle = introTitle
        self.introDetail = introDetail
        self.dismiss = dismiss
        self.confirm = confirm
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                AnimateCreateChooserHeader(title: title, dismiss: dismiss)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 14)

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        AVAppShellCard {
                            HStack(spacing: 12) {
                                Image("AviFullBody")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 42, height: 42)
                                    .padding(4)
                                    .background(AVBrandColor.accent.opacity(0.10), in: Circle())
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(introTitle)
                                        .font(.system(size: 14, weight: .black))
                                        .foregroundStyle(AVBrandColor.textPrimary)

                                    Text(introDetail)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AVBrandColor.textSecondary)
                                        .lineLimit(2)
                                }

                                Spacer(minLength: 0)
                            }
                        }

                        content()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .safeAreaPadding(.bottom, 200)
                }
                .scrollIndicators(.hidden)
            }

            AnimateCreateFixedFooterAction(
                title: L10n.string("common.done"),
                systemImage: "checkmark.circle.fill",
                action: confirm
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 96)
        }
        .background(AnimateTheme.shellBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct AnimateCreateVisualOptionTile: View {
    let title: String
    let detail: String
    let assetName: String
    let isSelected: Bool
    let select: () -> Void

    private let tileHeight: CGFloat = 106

    var body: some View {
        GeometryReader { proxy in
            Button(action: select) {
                tileContent(width: proxy.size.width)
            }
            .buttonStyle(.plain)
        }
        .frame(height: tileHeight)
    }

    private func tileContent(width: CGFloat) -> some View {
            ZStack(alignment: .bottomLeading) {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: tileHeight)
                    .clipped()

                LinearGradient(
                    colors: [.black.opacity(0.02), .black.opacity(0.28), .black.opacity(0.80)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(.white, AVBrandColor.accent)
                                .accessibilityHidden(true)
                        }

                        Text(title)
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }

                    Text(detail)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.84))
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: width, height: tileHeight)
            .background(AVBrandColor.neutral100, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? AVBrandColor.accent : AVBrandColor.borderSubtle.opacity(0.7), lineWidth: isSelected ? 2 : 1)
            }
            .shadow(color: AVBrandColor.ink.opacity(isSelected ? 0.12 : 0.05), radius: isSelected ? 8 : 4, x: 0, y: 3)
    }
}

private struct AnimateCreateThemeChooserPage: View {
    let styles: [AnimateVideoCreationStyle]
    let selectedStyle: AnimateVideoCreationStyle
    let selectStyle: (AnimateVideoCreationStyle) -> Void
    let dismiss: () -> Void

    @State private var setupStyleID: AnimateVideoCreationStyleID

    init(
        styles: [AnimateVideoCreationStyle],
        selectedStyle: AnimateVideoCreationStyle,
        selectStyle: @escaping (AnimateVideoCreationStyle) -> Void,
        dismiss: @escaping () -> Void
    ) {
        self.styles = styles
        self.selectedStyle = selectedStyle
        self.selectStyle = selectStyle
        self.dismiss = dismiss
        _setupStyleID = State(initialValue: selectedStyle.id)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                AnimateCreateThemeChooserHeader(
                    dismiss: dismiss
                )
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 14)

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        AVAppShellCard {
                            HStack(spacing: 12) {
                                Image("AviFullBody")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 42, height: 42)
                                    .padding(4)
                                    .background(AVBrandColor.accent.opacity(0.10), in: Circle())
                                    .accessibilityHidden(true)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(L10n.string("create.selector.theme.intro.title"))
                                        .font(.system(size: 14, weight: .black))
                                        .foregroundStyle(AVBrandColor.textPrimary)

                                    Text(L10n.string("create.selector.theme.intro.detail"))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AVBrandColor.textSecondary)
                                        .lineLimit(2)
                                }

                                Spacer(minLength: 0)
                            }
                        }

                        AnimateCreateTwoColumnGrid(items: styles) { style in
                            AnimateCreateThemeImageTile(
                                style: style,
                                isSelected: setupStyleID == style.id,
                                selectStyle: { setupStyleID = style.id }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .safeAreaPadding(.bottom, 200)
                }
                .scrollIndicators(.hidden)
            }

            AnimateCreateFixedFooterAction(
                title: L10n.string("common.done"),
                systemImage: "checkmark.circle.fill",
                action: applySelection
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 96)
        }
        .background(AnimateTheme.shellBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func applySelection() {
        guard let style = styles.first(where: { $0.id == setupStyleID }) else {
            dismiss()
            return
        }
        selectStyle(style)
        dismiss()
    }
}

private struct AnimateCreateThemeChooserHeader: View {
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: dismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.92), in: Circle())
                    .shadow(color: AVBrandColor.ink.opacity(0.08), radius: 10, x: 0, y: 4)
                    .contentShape(Circle())
            }
            .accessibilityLabel(L10n.string("common.back"))

            Text(L10n.string("create.selector.theme.title"))
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(AVBrandColor.textPrimary)
                .frame(maxWidth: .infinity)

            Color.clear
                .frame(width: 44, height: 44)
        }
    }
}

private struct AnimateCreateChooserHeader: View {
    let title: String
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: dismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.92), in: Circle())
                    .shadow(color: AVBrandColor.ink.opacity(0.08), radius: 10, x: 0, y: 4)
                    .contentShape(Circle())
            }
            .accessibilityLabel(L10n.string("common.back"))

            Text(title)
                .font(.system(size: 18, weight: .black))
                .foregroundStyle(AVBrandColor.textPrimary)
                .frame(maxWidth: .infinity)

            Color.clear
                .frame(width: 44, height: 44)
        }
    }
}

private struct AnimateCreateThemeImageTile: View {
    let style: AnimateVideoCreationStyle
    let isSelected: Bool
    let selectStyle: () -> Void

    private let tileHeight: CGFloat = 112

    var body: some View {
        GeometryReader { proxy in
            Button(action: selectStyle) {
                tileContent(width: proxy.size.width)
            }
            .buttonStyle(.plain)
            .disabled(!style.isEnabled)
            .accessibilityLabel(accessibilityLabel)
        }
        .frame(height: tileHeight)
    }

    private var accessibilityLabel: String {
        if style.isEnabled {
            return L10n.string("create.selector.theme.accessibility", style.title)
        }
        return L10n.string("create.selector.theme.accessibilitySoon", style.title)
    }

    private func tileContent(width: CGFloat) -> some View {
            ZStack(alignment: .bottomLeading) {
                Image(style.assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: tileHeight)
                    .clipped()
                    .saturation(style.isEnabled ? 1 : 0.2)
                    .opacity(style.isEnabled ? 1 : 0.52)

                LinearGradient(
                    colors: [.black.opacity(0.02), .black.opacity(0.28), .black.opacity(0.80)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(.white, AVBrandColor.accent)
                                .accessibilityHidden(true)
                        }

                        Text(style.title)
                            .font(.system(size: 13, weight: .black))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)

                        if !style.isEnabled {
                            Text(L10n.string("common.soon"))
                                .font(.system(size: 9, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.white.opacity(0.24), in: Capsule())
                        }
                    }

                    Text(style.subtitle)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.82))
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 11)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: width, height: tileHeight)
            .background(AVBrandColor.neutral100, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? AVBrandColor.accent : AVBrandColor.borderSubtle.opacity(0.7), lineWidth: isSelected ? 2 : 1)
            }
            .shadow(color: AVBrandColor.ink.opacity(isSelected ? 0.12 : 0.05), radius: isSelected ? 8 : 4, x: 0, y: 3)
    }
}
