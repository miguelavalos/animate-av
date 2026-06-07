import AVAppShellFoundation
import AVBrandFoundation
import PhotosUI
import SwiftUI

struct MomentsCreateWorkflowContent: View {
    @ObservedObject var viewModel: MomentsCreateViewModel
    @Binding var pickerItems: [PhotosPickerItem]
    let startSignInFlow: () -> Void
    let openCredits: () -> Void
    let finishFinalVideoToGallery: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.workflowPresentation.showsMediaFirstWorkspace {
                MomentsCreateMediaFirstWorkspace(
                    form: $viewModel.form,
                    selectedStyle: viewModel.selectedCreationStyle,
                    autoStyleSuggestion: viewModel.autoStyleSuggestion,
                    canUndoAutoStyleSuggestion: viewModel.canUndoAutoStyleSuggestion,
                    styles: viewModel.creationStyles,
                    selectedMusicPreset: viewModel.selectedMusicPreset,
                    presentation: viewModel.workflowPresentation,
                    isPreparingStory: viewModel.isPreparingStory,
                    pickerItems: $pickerItems,
                    importPickerItems: viewModel.importPickerItems,
                    importLatestPhotos: viewModel.importLatestPhotos,
                    importPhotoAlbum: viewModel.importPhotoAlbum,
                    removeMedia: viewModel.removeMedia,
                    moveMedia: viewModel.moveMedia,
                    reorderMedia: viewModel.reorderMedia,
                    restoreLocalMediaForEditing: viewModel.restoreLocalMediaForEditing,
                    autoPickStrongMoments: viewModel.autoPickStrongMoments,
                    selectStyle: viewModel.selectCreationStyle,
                    selectLook: viewModel.selectLook,
                    selectDuration: viewModel.selectDuration,
                    selectMusicPreset: viewModel.selectMusicPreset,
                    useAutoStyleSuggestion: viewModel.useAutoStyleSuggestion,
                    undoAutoStyleSuggestion: viewModel.undoAutoStyleSuggestion,
                    openPickerRequest: 0,
                    openAlbumRequest: viewModel.albumPickerOpenRequest,
                    consumeOpenPickerRequest: {},
                    consumeOpenAlbumRequest: viewModel.consumeAlbumPickerOpenRequest,
                    discardMoment: viewModel.discardMoment,
                    startSignInFlow: startSignInFlow,
                    openCredits: openCredits,
                    prepareFinalRenderPlan: viewModel.prepareFinalVideoPlanFromCurrentSelection,
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

private struct MomentsCreateMediaFirstWorkspace: View {
    @Binding var form: MomentSetupForm
    let selectedStyle: MomentCreationStyle
    let autoStyleSuggestion: MomentsMediaAutoStyleSuggestion?
    let canUndoAutoStyleSuggestion: Bool
    let styles: [MomentCreationStyle]
    let selectedMusicPreset: MomentMusicPreset
    let presentation: MomentsCreateWorkflowPresentation
    let isPreparingStory: Bool
    @Binding var pickerItems: [PhotosPickerItem]
    let importPickerItems: ([PhotosPickerItem]) -> Void
    let importLatestPhotos: () -> Void
    let importPhotoAlbum: (String) -> Void
    let removeMedia: (MomentsSelectedMedia) -> Void
    let moveMedia: (MomentsSelectedMedia, MomentsSelectedMedia) -> Void
    let reorderMedia: ([MomentsSelectedMedia]) -> Void
    let restoreLocalMediaForEditing: () -> Void
    let autoPickStrongMoments: () -> Void
    let selectStyle: (MomentCreationStyle) -> Void
    let selectLook: (MomentLook) -> Void
    let selectDuration: (MomentDuration) -> Void
    let selectMusicPreset: (MomentMusicPreset) -> Void
    let useAutoStyleSuggestion: () -> Void
    let undoAutoStyleSuggestion: () -> Void
    let openPickerRequest: Int
    let openAlbumRequest: Int
    let consumeOpenPickerRequest: () -> Void
    let consumeOpenAlbumRequest: () -> Void
    let discardMoment: () -> Void
    let startSignInFlow: () -> Void
    let openCredits: () -> Void
    let prepareFinalRenderPlan: (Bool) -> Void
    let submitFinalVideoConfirmation: (Bool) -> Void
    let retryFinalVideoDownload: () -> Void
    let finishFinalVideoToGallery: () -> Void

    @State private var showsThemeChooser = false
    @State private var showsLookChooser = false
    @State private var showsLengthChooser = false
    @State private var showsMoodChooser = false
    @State private var showsAviNoteEditor = false
    @State private var showsCreateVideoConfirmation = false
    @State private var waitsForFinalRenderPlan = false
    @State private var showsDiscardMomentConfirmation = false
    @State private var showsCompactPhotoPicker = false
    @State private var showsCompactAlbumPicker = false
    @State private var showsCompactMediaManager = false
    @State private var handledOpenPickerRequest = 0
    @State private var handledOpenAlbumRequest = 0

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: showsWorkflowDashboard ? 10 : 12) {
                    if showsFinalVideoCompletion {
                        MomentsCreateFinalVideoReadyScene(presentation: presentation)
                            .padding(.top, 28)
                    } else if showsFinalVideoRecovery {
                        MomentsCreateFinalVideoRecoveryScene(
                            presentation: presentation,
                            discardMoment: { showsDiscardMomentConfirmation = true }
                        )
                        .padding(.top, 28)
                    } else if presentation.isFinalRenderEditingLocked {
                        MomentsCreateLockedFinalRenderScene(presentation: presentation)
                            .padding(.top, 28)
                    } else {
                        MomentsCreateCompactAviGuide(
                            presentation: presentation
                        )
                    }

                    if showsFinalVideoCompletion || presentation.isFinalRenderEditingLocked {
                        EmptyView()
                    } else if hasMediaSelection {
                        MomentsCreateStoryDecisionCard(
                            presentation: presentation,
                            selectedDuration: form.duration,
                            selectedLook: form.look,
                            note: form.details,
                            selectedStyle: selectedStyle,
                            selectedMusicPreset: selectedMusicPreset,
                            autoStyleSuggestion: autoStyleSuggestion,
                            canUndoAutoStyleSuggestion: canUndoAutoStyleSuggestion,
                            styles: styles,
                            useAutoStyleSuggestion: useAutoStyleSuggestion,
                            undoAutoStyleSuggestion: undoAutoStyleSuggestion,
                            editMedia: { showsCompactMediaManager = true },
                            changeTheme: { showsThemeChooser = true },
                            changeLook: { showsLookChooser = true },
                            changeMood: { showsMoodChooser = true },
                            changeLength: { showsLengthChooser = true },
                            editNote: { showsAviNoteEditor = true },
                            discardMoment: { showsDiscardMomentConfirmation = true }
                        )
                    } else if hasFinalVideoState {
                        EmptyView()
                    } else {
                        MomentsCreateMediaCard(
                            presentation: mediaPresentation,
                            choosePhotos: presentCompactPhotoPicker,
                            chooseAlbum: presentCompactAlbumPicker
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, bottomContentPadding)
            }
            .scrollIndicators(.hidden)

            if showsPrimaryActionBar {
                MomentsCreatePrimaryActionBar(
                    presentation: presentation,
                    startSignInFlow: startSignInFlow,
                    openCredits: openCredits,
                    generateFinalRender: primaryFinalRenderAction,
                    openCreateVideoConfirmation: { showsCreateVideoConfirmation = true },
                    retryFinalVideoDownload: retryFinalVideoDownload,
                    finishFinalVideoToGallery: finishFinalVideoToGallery
                )
                .padding(.horizontal, 2)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
        .animation(.spring(response: 0.38, dampingFraction: 0.86), value: presentation.storySummary.hasScenes)
        .photosPicker(
            isPresented: $showsCompactPhotoPicker,
            selection: $pickerItems,
            maxSelectionCount: mediaPresentation.remainingSlots,
            matching: .any(of: [.images, .videos])
        )
        .onChange(of: pickerItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            importPickerItems(newItems)
            pickerItems = []
        }
        .navigationDestination(isPresented: $showsCompactMediaManager) {
            MomentsCreateMediaManagerSheet(
                selectedMedia: presentation.mediaSummary.selectedMedia,
                syncedMediaAssets: mediaPresentation.syncedMediaAssets,
                canAddMedia: presentation.canAddMedia,
                isImporting: presentation.mediaSummary.isImporting,
                importProgress: presentation.mediaSummary.importProgress,
                removeMedia: removeMedia,
                moveMedia: moveMedia,
                reorderMedia: reorderMedia,
                restoreLocalMediaForEditing: restoreLocalMediaForEditing,
                chooseManually: {
                    presentCompactPhotoPicker()
                },
                chooseAlbum: {
                    presentCompactAlbumPicker()
                },
                importLatestPhotos: importLatestPhotos,
                smartOrder: autoPickStrongMoments
            )
        }
        .sheet(isPresented: $showsCompactAlbumPicker) {
            MomentsCreateAlbumPickerSheet(
                remainingSlots: mediaPresentation.remainingSlots,
                selectAlbum: { album in
                    showsCompactAlbumPicker = false
                    importPhotoAlbum(album.id)
                }
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showsCreateVideoConfirmation) {
            MomentsCreateFinalVideoConfirmationSheet(
                action: finalVideoAction,
                mediaSummary: presentation.mediaSummary,
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
        }
        .onChange(of: presentation.finalRenderSummary.renderPlan?.planId) { _, _ in
            guard waitsForFinalRenderPlan,
                  presentation.finalRenderSummary.latestFinalJob == nil,
                  finalVideoAction.canShowConfirmationSheet else { return }
            waitsForFinalRenderPlan = false
            showsCreateVideoConfirmation = true
        }
        .onChange(of: presentation.finalRenderSummary.latestFinalJob?.id) { _, jobId in
            if jobId != nil {
                waitsForFinalRenderPlan = false
                showsCreateVideoConfirmation = false
            }
        }
        .onChange(of: presentation.finalRenderSummary.isGenerating) { _, isGenerating in
            guard waitsForFinalRenderPlan, !isGenerating, presentation.finalRenderSummary.renderPlan == nil else { return }
            waitsForFinalRenderPlan = false
        }
        .onAppear {
            openCompactPickerIfRequested(openPickerRequest)
            openCompactAlbumIfRequested(openAlbumRequest)
        }
        .onChange(of: openPickerRequest) { _, newValue in
            openCompactPickerIfRequested(newValue)
        }
        .onChange(of: openAlbumRequest) { _, newValue in
            openCompactAlbumIfRequested(newValue)
        }
        .alert(L10n.string("create.discard.confirmTitle"), isPresented: $showsDiscardMomentConfirmation) {
            Button(L10n.string("create.discard.keep"), role: .cancel) {}
            Button(discardConfirmationActionTitle, role: .destructive) {
                discardCurrentMoment()
            }
        } message: {
            Text(discardConfirmationMessage)
        }
        .navigationDestination(isPresented: $showsThemeChooser) {
            MomentsCreateThemeChooserPage(
                styles: styles,
                selectedStyle: selectedStyle,
                selectStyle: selectStyle,
                dismiss: { showsThemeChooser = false }
            )
            .id(selectedStyle.id)
        }
        .navigationDestination(isPresented: $showsLookChooser) {
            MomentsCreateLookChooserPage(
                selectedLook: form.look,
                selectLook: {
                    selectLook($0)
                    showsLookChooser = false
                },
                dismiss: { showsLookChooser = false }
            )
            .id(form.look.rawValue)
        }
        .navigationDestination(isPresented: $showsLengthChooser) {
            MomentsCreateLengthChooserPage(
                selectedDuration: form.duration,
                selectDuration: {
                    selectDuration($0)
                    showsLengthChooser = false
                },
                dismiss: { showsLengthChooser = false }
            )
            .id(form.duration.rawValue)
        }
        .navigationDestination(isPresented: $showsMoodChooser) {
            MomentsCreateMoodChooserPage(
                allowedMusic: selectedStyle.allowedMusic,
                selectedMusicPreset: selectedMusicPreset,
                selectMusicPreset: {
                    selectMusicPreset($0)
                    showsMoodChooser = false
                },
                dismiss: { showsMoodChooser = false }
            )
            .id(selectedMusicPreset.rawValue)
        }
        .navigationDestination(isPresented: $showsAviNoteEditor) {
            MomentsCreateAviNoteEditorPage(
                text: $form.details,
                dismiss: { showsAviNoteEditor = false }
            )
        }
    }

    private var mediaPresentation: MomentsCreateMediaPresentation {
        MomentsCreateMediaPresentation(
            activeMomentId: presentation.activeMomentId,
            template: presentation.template,
            summary: presentation.mediaSummary,
            canAddMedia: presentation.canAddMedia,
            availabilityMessage: presentation.mediaAvailabilityMessage
        )
    }

    private var finalVideoAction: MomentsCreateFinalVideoActionPresentation {
        MomentsCreateFinalVideoActionPresentation(
            summary: presentation.finalRenderSummary,
            template: presentation.template,
            balance: presentation.balance
        )
    }

    private func primaryFinalRenderAction() {
        if finalVideoAction.hasRenderPlan {
            showsCreateVideoConfirmation = true
        } else {
            waitsForFinalRenderPlan = true
            prepareFinalRenderPlan(false)
        }
    }

    private func openCompactPickerIfRequested(_ request: Int) {
        guard request > handledOpenPickerRequest,
              presentation.mediaSummary.selectedCount == 0 else { return }
        handledOpenPickerRequest = request
        consumeOpenPickerRequest()
        presentCompactPhotoPickerAfterViewUpdate()
    }

    private func openCompactAlbumIfRequested(_ request: Int) {
        guard request > handledOpenAlbumRequest,
              presentation.mediaSummary.selectedCount == 0 else { return }
        handledOpenAlbumRequest = request
        consumeOpenAlbumRequest()
        presentCompactAlbumPicker()
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

    private func presentCompactAlbumPicker() {
        showsCompactAlbumPicker = true
    }

    private func discardCurrentMoment() {
        discardMoment()
    }

    private var discardConfirmationActionTitle: String {
        presentation.hasUnsavedLocalMoment ? L10n.string("create.discard.local") : L10n.string("create.discard.current")
    }

    private var discardConfirmationMessage: String {
        if presentation.hasUnsavedLocalMoment {
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
        showsWorkflowDashboard && !presentation.isFinalRenderEditingLocked
    }

    private var bottomContentPadding: CGFloat {
        if showsFinalVideoCompletion {
            return 150
        }
        if showsFinalVideoRecovery {
            return 190
        }
        if presentation.isFinalRenderEditingLocked {
            return 118
        }
        return showsWorkflowDashboard ? 144 : 172
    }
}

struct MomentsCreateBlockingPreparationView: View {
    let presentation: MomentsCreateWorkflowPresentation
    let isPreparingStory: Bool
    let isPreparingFinalPlan: Bool

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 42)

            ZStack {
                Circle()
                    .fill(mode.tint.opacity(0.10))
                    .frame(width: 128, height: 128)

                Circle()
                    .stroke(mode.tint.opacity(0.18), lineWidth: 2)
                    .frame(width: 156, height: 156)
                    .scaleEffect(isAnimating ? 1.08 : 0.92)
                    .opacity(isAnimating ? 0.20 : 0.58)

                Image("AviFullBody")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 86, height: 86)
                    .offset(y: isAnimating ? -4 : 3)

                Image(systemName: mode.iconName)
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(mode.tint, in: Circle())
                    .offset(x: 54, y: 48)
                    .shadow(color: mode.tint.opacity(0.24), radius: 10, y: 4)
            }

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

            VStack(spacing: 8) {
                if let fractionCompleted = progress?.fractionCompleted {
                    ProgressView(value: fractionCompleted)
                        .tint(mode.tint)
                        .frame(width: 168)
                    Text(progress?.title ?? L10n.string("create.media.progress.reading"))
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundStyle(AVBrandColor.textSecondary)
                } else {
                    ProgressView()
                        .tint(mode.tint)
                        .controlSize(.regular)
                }
            }
            .padding(.top, 4)

            Spacer(minLength: 120)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MomentsTheme.shellBackground.ignoresSafeArea())
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }

    private var title: String {
        mode.title
    }

    private var message: String {
        mode.message(itemCount: progress?.totalCount)
    }

    private var progress: MomentsMediaImportProgress? {
        presentation.mediaSummary.importProgress
    }

    private var mode: PreparationMode {
        if presentation.isCreatingMoment {
            return .prepareMoment
        }
        if isPreparingFinalPlan {
            return .prepareFinalPlan
        }
        if presentation.finalRenderSummary.isGenerating {
            return .createVideo
        }
        if presentation.storySummary.isPlanning {
            return .prepareStory
        }
        if isPreparingStory {
            return .uploadForVideo
        }
        return .importMedia
    }

    private enum PreparationMode {
        case prepareMoment
        case importMedia
        case prepareStory
        case uploadForVideo
        case prepareFinalPlan
        case createVideo

        var title: String {
            switch self {
            case .prepareMoment:
                return L10n.string("create.preparation.prepareMoment.title")
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
            case .prepareMoment:
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
            case .prepareMoment, .importMedia, .prepareStory:
                return AVBrandColor.accent
            case .uploadForVideo, .prepareFinalPlan:
                return AVBrandColor.textSecondary
            case .createVideo:
                return AVBrandColor.textPrimary
            }
        }

        func message(itemCount: Int?) -> String {
            switch self {
            case .prepareMoment:
                return L10n.string("create.preparation.prepareMoment.detail")
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

private struct MomentsCreateFinalVideoReadyScene: View {
    let presentation: MomentsCreateWorkflowPresentation

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 42)

            ZStack {
                Circle()
                    .fill(AVBrandColor.accent.opacity(0.10))
                    .frame(width: 128, height: 128)

                Circle()
                    .stroke(AVBrandColor.accent.opacity(0.18), lineWidth: 2)
                    .frame(width: 156, height: 156)
                    .scaleEffect(isAnimating ? 1.08 : 0.92)
                    .opacity(isAnimating ? 0.20 : 0.58)

                Image("AviFullBody")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 86, height: 86)
                    .offset(y: isAnimating ? -4 : 3)

                Image(systemName: iconName)
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(AVBrandColor.accent, in: Circle())
                    .offset(x: 54, y: 48)
                    .shadow(color: AVBrandColor.accent.opacity(0.24), radius: 10, y: 4)
            }

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

            Spacer(minLength: 120)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MomentsTheme.shellBackground.ignoresSafeArea())
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
        .accessibilityElement(children: .combine)
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

    private var iconName: String {
        presentation.finalRenderSummary.pendingGalleryVideo != nil
            ? "checkmark.circle.fill"
            : "arrow.down.circle.fill"
    }
}

private struct MomentsCreateFinalVideoRecoveryScene: View {
    let presentation: MomentsCreateWorkflowPresentation
    let discardMoment: () -> Void

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

            Button(role: .destructive, action: discardMoment) {
                Label(L10n.string("create.final.recovery.discard"), systemImage: "trash")
                    .font(.system(size: 14, weight: .black))
                    .frame(maxWidth: 240)
                    .frame(height: 44)
            }
            .buttonStyle(MomentsCreateSoftActionButtonStyle())

            Spacer(minLength: 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MomentsTheme.shellBackground.ignoresSafeArea())
        .accessibilityElement(children: .contain)
    }

    private var recoveryMessage: String {
        presentation.finalRenderSummary.realtimeStatus?.detail
            ?? presentation.finalRenderSummary.statusMessage
            ?? L10n.string("create.final.recovery.detail")
    }
}

private struct MomentsCreateStoryReviewCard: View {
    let presentation: MomentsCreateWorkflowPresentation

    var body: some View {
        AVAppShellCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    Text(L10n.string("create.storyDirection.title"))
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)

                    Spacer(minLength: 0)

                    Text(sceneCountTitle)
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(AVBrandColor.accent)
                }

                Text(L10n.string("create.storyDirection.detail"))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AVBrandColor.textSecondary)

                VStack(alignment: .leading, spacing: 10) {
                    if presentation.storySummary.presentedScenes.isEmpty {
                        Label(L10n.string("create.storyDirection.needsStory"), systemImage: "text.bubble.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(AVBrandColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AVBrandColor.neutral100.opacity(0.68), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else {
                        ForEach(presentation.storySummary.presentedScenes) { scene in
                            MomentsCreatePresentedStorySceneRow(scene: scene)
                        }
                    }
                }

                HStack(spacing: 8) {
                    MomentsCreateOptionPill(title: "\(presentation.mediaSummary.effectiveMediaCount) items", systemImage: "photo.on.rectangle")
                    MomentsCreateOptionPill(title: "\(presentation.template.duration)", systemImage: "timer")
                }
            }
        }
    }

    private var sceneCountTitle: String {
        let count = presentation.storySummary.presentedScenes.count
        return "\(count) \(count == 1 ? "scene" : "scenes")"
    }
}

private struct MomentsCreateStoryDecisionCard: View {
    let presentation: MomentsCreateWorkflowPresentation
    let selectedDuration: MomentDuration
    let selectedLook: MomentLook
    let note: String
    let selectedStyle: MomentCreationStyle
    let selectedMusicPreset: MomentMusicPreset
    let autoStyleSuggestion: MomentsMediaAutoStyleSuggestion?
    let canUndoAutoStyleSuggestion: Bool
    let styles: [MomentCreationStyle]
    let useAutoStyleSuggestion: () -> Void
    let undoAutoStyleSuggestion: () -> Void
    let editMedia: () -> Void
    let changeTheme: () -> Void
    let changeLook: () -> Void
    let changeMood: () -> Void
    let changeLength: () -> Void
    let editNote: () -> Void
    let discardMoment: () -> Void
    var body: some View {
        AVAppShellCard {
            VStack(alignment: .leading, spacing: 11) {
                HStack(alignment: .center, spacing: 14) {
                    MomentsSharedMediaSummaryStack(
                        localMedia: presentation.mediaSummary.selectedMedia,
                        syncedMedia: mediaPresentation.syncedMediaAssets
                    )
                    .frame(width: 82, height: 82)
                    .scaleEffect(0.88)

                    VStack(alignment: .leading, spacing: 7) {
                        HStack(spacing: 9) {
                            Image(systemName: storyDecision.iconName)
                                .font(.system(size: 14, weight: .black))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(iconColor, in: Circle())

                            Text(L10n.string("create.storyDirection.title"))
                                .font(.system(size: 20, weight: .black))
                                .foregroundStyle(AVBrandColor.textPrimary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.82)
                        }

                        Text(storyDecision.statusMessage)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AVBrandColor.textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Menu {
                        Section(L10n.string("create.storyDecision.menu.userActions")) {
                            Button(action: editMedia) {
                                Label(L10n.string("create.media.editTitle"), systemImage: "photo.stack")
                            }
                            if canShowDiscardAction {
                                Button(role: .destructive, action: discardMoment) {
                                    Label(discardActionTitle, systemImage: discardActionIconName)
                                }
                            }
                        }

                        Section(L10n.string("create.storyDecision.menu.aviActions")) {
                            if canUndoAutoStyleSuggestion {
                                Button(action: undoAutoStyleSuggestion) {
                                    Label(L10n.string("create.aviDirection.undoSuggestion"), systemImage: "arrow.uturn.backward")
                                }
                            } else if showsUseAviSuggestion {
                                Button(action: useAutoStyleSuggestion) {
                                    Label(L10n.string("create.aviDirection.useSuggestion"), systemImage: "sparkles")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(AVBrandColor.textSecondary)
                            .frame(width: 34, height: 34)
                            .background(AVBrandColor.mutedSurface.opacity(0.62), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.string("create.storyDecision.menu.accessibility"))
                }

                MomentsCreateStoryDecisionSummary(
                    isUserAdjusted: isUserAdjustedFromAvi,
                    title: decisionSummaryTitle,
                    detail: decisionSummaryDetail,
                    aviSuggestionDetail: aviSuggestionSummaryDetail
                )

                VStack(alignment: .leading, spacing: 7) {
                    Text(L10n.string("create.storyDecision.selectedSetup"))
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .textCase(.uppercase)

                    VStack(spacing: 0) {
                        MomentsCreateStoryDecisionSummaryRow(
                            title: L10n.string("create.workflowContent.mediaSelected"),
                            value: storyDecision.mediaCountTitle,
                            detail: mediaDetail,
                            systemImage: "photo.stack",
                            action: editMedia
                        )
                        MomentsCreateOptionDivider()
                        MomentsCreateStoryDecisionSummaryRow(
                            title: L10n.string("create.workflowContent.theme"),
                            value: selectedStyle.title,
                            detail: selectedStyle.subtitle,
                            systemImage: "paintpalette.fill",
                            action: changeTheme
                        )
                        MomentsCreateOptionDivider()
                        MomentsCreateStoryDecisionSummaryRow(
                            title: L10n.string("create.guide.look.title"),
                            value: selectedLook.title,
                            detail: selectedLook.subtitle,
                            systemImage: selectedLook.systemImage,
                            action: changeLook
                        )
                        MomentsCreateOptionDivider()
                        MomentsCreateStoryDecisionSummaryRow(
                            title: L10n.string("create.workflowContent.tone"),
                            value: selectedMusicPreset.title,
                            detail: L10n.string("create.guide.mood.detail"),
                            systemImage: "sparkles",
                            action: changeMood
                        )
                        MomentsCreateOptionDivider()
                        MomentsCreateStoryDecisionSummaryRow(
                            title: L10n.string("create.workflowContent.pacing"),
                            value: storyDecision.durationTitle,
                            detail: lengthDetail,
                            systemImage: "timer",
                            action: changeLength
                        )
                        MomentsCreateOptionDivider()
                        MomentsCreateStoryDecisionSummaryRow(
                            title: L10n.string("create.note.field.title"),
                            value: noteTitle,
                            detail: noteDetail,
                            systemImage: "text.bubble.fill",
                            action: editNote
                        )
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AVBrandColor.neutral100.opacity(0.58), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }

                if presentation.storySummary.hasScenes {
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(storyDecision.visibleScenes.prefix(1)) { scene in
                            MomentsCreatePresentedStorySceneRow(scene: scene)
                        }

                        if let remainingSceneTitle = storyDecision.remainingSceneTitle {
                            Text(remainingSceneTitle)
                                .font(.caption2)
                                .fontWeight(.black)
                                .foregroundStyle(AVBrandColor.textSecondary)
                        }
                    }
                } else if presentation.storySummary.isPlanning {
                    ProgressView()
                        .tint(AVBrandColor.accent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

            }
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
        isUserAdjustedFromAvi
            ? L10n.string("create.storyDecision.summary.userTitle")
            : L10n.string("create.storyDecision.summary.aviTitle")
    }

    private var decisionSummaryDetail: String {
        if isUserAdjustedFromAvi {
            return L10n.string(
                "create.storyDecision.summary.userDetail",
                selectedStyle.title,
                selectedMusicPreset.title,
                selectedLook.title,
                storyDecision.durationTitle
            )
        }

        return L10n.string(
            "create.storyDecision.summary.aviDetail",
            selectedStyle.title,
            selectedMusicPreset.title,
            selectedLook.title,
            storyDecision.durationTitle,
            mediaDetail
        )
    }

    private var aviSuggestionSummaryDetail: String? {
        guard isUserAdjustedFromAvi,
              let autoStyleSuggestion else { return nil }
        let styleTitle = styles.first(where: { $0.id == autoStyleSuggestion.styleID })?.title
            ?? L10n.string("create.options.anotherTheme")
        return L10n.string(
            "create.storyDecision.summary.aviProposalDetail",
            styleTitle,
            autoStyleSuggestion.musicPreset.title,
            selectedLook.title,
            storyDecision.durationTitle
        )
    }

    private var mediaPresentation: MomentsCreateMediaPresentation {
        MomentsCreateMediaPresentation(
            activeMomentId: presentation.activeMomentId,
            template: presentation.template,
            summary: presentation.mediaSummary,
            canAddMedia: presentation.canAddMedia,
            availabilityMessage: presentation.mediaAvailabilityMessage
        )
    }

    private var iconColor: Color {
        presentation.storySummary.hasScenes ? AVBrandColor.accent : AVBrandColor.textPrimary
    }

    private var mediaDetail: String {
        if presentation.storySummary.hasScenes {
            return sceneCountTitle
        }
        return L10n.string("create.mediaCard.selectionMessage")
    }

    private var sceneCountTitle: String {
        let count = presentation.storySummary.presentedScenes.count
        return count == 1
            ? L10n.string("create.workflowContent.sceneReady", count)
            : L10n.string("create.workflowContent.scenesReady", count)
    }

    private var lengthDetail: String {
        switch selectedDuration {
        case .auto:
            return L10n.string("create.guide.length.auto.detail")
        case .short:
            return L10n.string("create.guide.length.short.detail")
        case .standard:
            return L10n.string("create.guide.length.standard.detail")
        case .extended:
            return L10n.string("create.guide.length.extended.detail")
        }
    }

    private var noteTitle: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? L10n.string("create.note.field.subtitle")
            : L10n.string("create.note.title")
    }

    private var noteDetail: String {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L10n.string("create.note.placeholder") : trimmed
    }

    private var discardActionTitle: String {
        presentation.hasUnsavedLocalMoment ? L10n.string("create.discard.closeDraft") : L10n.string("create.discard.current")
    }

    private var discardActionIconName: String {
        presentation.hasUnsavedLocalMoment ? "xmark.circle" : "trash"
    }

    private var canShowDiscardAction: Bool {
        presentation.finalRenderSummary.latestFinalJob?.isActiveRender != true
    }

    private var storyDecision: MomentsCreateStoryDecisionPresentation {
        MomentsCreateStoryDecisionPresentation(
            mediaSummary: presentation.mediaSummary,
            storySummary: presentation.storySummary,
            selectedDuration: selectedDuration,
            renderPlan: presentation.finalRenderSummary.renderPlan?.plan,
            canRefreshStory: presentation.canPlanStory,
            availabilityMessage: presentation.storyAvailabilityMessage
        )
    }

}

private struct MomentsCreateStoryDecisionSummary: View {
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

                    Text(L10n.string("create.storyDecision.summary.aviProposalTitle"))
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

private struct MomentsCreateLockedFinalRenderScene: View {
    let presentation: MomentsCreateWorkflowPresentation

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
                    MomentsCreateLockedRenderMetric(
                        title: L10n.string("create.final.confirmSheet.cost"),
                        value: MomentsCreditCopy.countTitle(presentation.lockedFinalRenderCreditCost),
                        systemImage: "creditcard.fill"
                    )
                    MomentsCreateLockedRenderMetric(
                        title: L10n.string("create.final.confirmSheet.media"),
                        value: mediaCountTitle,
                        systemImage: "photo.stack.fill"
                    )
                }

                MomentsCreateLockedFinalRenderNotice()

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

private struct MomentsCreateLockedRenderMetric: View {
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

private struct MomentsCreateLockedFinalRenderNotice: View {
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

private struct MomentsCreatePresentedStorySceneRow: View {
    let scene: MomentsCreateStoryScenePresentation

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "rectangle.stack.fill")
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(AVBrandColor.accent)
                .frame(width: 26, height: 26)
                .background(AVBrandColor.accent.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(scene.title)
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)

                Text(scene.caption)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .lineLimit(2)

                if let detail = scene.detail, !detail.isEmpty {
                    Text(detail)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(AVBrandColor.textSecondary.opacity(0.78))
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(AVBrandColor.neutral100.opacity(0.68), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct MomentsCreateOptionPill: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(AVBrandColor.textPrimary)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(AVBrandColor.neutral100, in: Capsule())
    }
}

private struct MomentsCreateStoryDecisionSummaryRow: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 10) {
                MomentsCreateGuideFieldIcon(systemImage: systemImage)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .textCase(.uppercase)
                        .lineLimit(1)

                    Text(value)
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(detail)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(AVBrandColor.textSecondary.opacity(0.86))
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "square.and.pencil")
                    .font(.system(size: 12, weight: .black))
                    .foregroundStyle(AVBrandColor.accent)
                    .frame(width: 28, height: 28)
                    .background(AVBrandColor.accent.opacity(0.08), in: Circle())
            }
            .padding(.vertical, 9)
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct MomentsCreateCompactAviGuide: View {
    let presentation: MomentsCreateWorkflowPresentation

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
        .accessibilityLabel(L10n.string("create.workflowContent.aviAccessibility", message))
    }

    private var title: String {
        if presentation.finalRenderSummary.finalExport != nil {
            return L10n.string("create.aviStatus.ready.title")
        }
        if let realtimeStatus = presentation.finalRenderSummary.realtimeStatus {
            return realtimeStatus.title
        }
        if presentation.storySummary.isPlanning {
            return L10n.string("create.aviStatus.preparing.title")
        }
        if presentation.finalRenderSummary.latestFinalJob != nil {
            return L10n.string("create.aviStatus.working.title")
        }
        if presentation.storySummary.hasScenes
            || presentation.finalRenderSummary.renderPlan != nil
            || presentation.canPrepareFinalRenderPlan
            || presentation.canGenerateFinalRender {
            return L10n.string("create.aviStatus.storyReady.title")
        }
        if presentation.mediaSummary.selectedCount > 0 || !presentation.mediaSummary.syncedMediaAssets.isEmpty {
            return L10n.string("create.aviStatus.goodSelection.title")
        }
        return L10n.string("create.aviStatus.startMedia.title")
    }

    private var message: String {
        if presentation.finalRenderSummary.finalExport != nil {
            return L10n.string("create.aviStatus.exportReady.detail")
        }
        if presentation.storySummary.isPlanning {
            return presentation.storySummary.statusMessage ?? L10n.string("create.aviStatus.preparing.detail")
        }
        if let realtimeStatus = presentation.finalRenderSummary.realtimeStatus {
            return realtimeStatus.detail
        }
        if presentation.storySummary.hasScenes
            || presentation.finalRenderSummary.renderPlan != nil
            || presentation.canPrepareFinalRenderPlan
            || presentation.canGenerateFinalRender {
            return L10n.string("create.aviStatus.storyReady.detail")
        }
        if presentation.mediaSummary.selectedCount > 0 || !presentation.mediaSummary.syncedMediaAssets.isEmpty {
            return L10n.string("create.aviStatus.goodSelection.detail")
        }
        return L10n.string("create.aviStatus.startMedia.detail")
    }
}

private struct MomentsCreatePrimaryActionBar: View {
    let presentation: MomentsCreateWorkflowPresentation
    let startSignInFlow: () -> Void
    let openCredits: () -> Void
    let generateFinalRender: () -> Void
    let openCreateVideoConfirmation: () -> Void
    let retryFinalVideoDownload: () -> Void
    let finishFinalVideoToGallery: () -> Void

    @ViewBuilder
    var body: some View {
        if showsFinalVideoDock {
            MomentsCreateFinalVideoActionDock(
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
                    MomentsCreateRealtimeRenderStatusPanel(status: realtimeStatus)
                }

                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: primaryActionPresentation.primaryHeaderIconName)
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(primaryHeaderColor, in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(primaryActionPresentation.title)
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(AVBrandColor.textPrimary)
                            .lineLimit(1)

                        Text(primaryActionPresentation.statusMessage ?? L10n.string("create.primary.creditPreflight"))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(statusColor)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                }

                if primaryActionPresentation.showsPrimaryActionButton {
                    Button(action: primaryAction) {
                        Label(primaryActionPresentation.buttonTitle, systemImage: primaryActionPresentation.buttonIconName)
                            .font(.system(size: 15, weight: .black))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                    }
                    .disabled(!primaryActionPresentation.canRunPrimaryAction)
                    .buttonStyle(MomentsCreateSoftActionButtonStyle())
                    .opacity(primaryActionPresentation.canRunPrimaryAction ? 1 : 0.72)
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
                        .buttonStyle(MomentsCreateSoftActionButtonStyle())
                    }
                    .font(.system(size: 14, weight: .black))
                } else if presentation.finalRenderSummary.finalExport != nil {
                    VStack(spacing: 10) {
                        Button(action: retryFinalVideoDownload) {
                            Label(finalVideoDownloadButtonTitle, systemImage: "arrow.down.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(MomentsCreateSoftActionButtonStyle())
                    }
                    .font(.system(size: 14, weight: .black))
                } else if presentation.finalRenderSummary.canRetryFinalVideoDownload {
                    Button(action: retryFinalVideoDownload) {
                        Label(L10n.string("create.workflowContent.retryFinalDownload"), systemImage: "arrow.down.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(MomentsCreateSoftActionButtonStyle())
                    .font(.system(size: 14, weight: .black))
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
    }

    private var showsFinalVideoDock: Bool {
        presentation.finalRenderSummary.finalExport != nil
            || presentation.finalRenderSummary.pendingGalleryVideo != nil
    }

    private var primaryActionPresentation: MomentsCreatePrimaryActionPresentation {
        MomentsCreatePrimaryActionPresentation(workflow: presentation)
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

    private func primaryAction() {
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
        } else if primaryActionPresentation.hasFinalVideoIntent {
            if primaryActionPresentation.needsSignInForStory {
                startSignInFlow()
            } else if primaryActionPresentation.needsCreditsForPreparedPlan {
                openCreateVideoConfirmation()
            } else if primaryActionPresentation.finalVideoAction.hasRenderPlan {
                openCreateVideoConfirmation()
            } else {
                generateFinalRender()
            }
        } else if primaryActionPresentation.needsSignInForStory {
            startSignInFlow()
        }
    }
}

private struct MomentsCreateFinalVideoActionDock: View {
    let presentation: MomentsCreateWorkflowPresentation
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
            .buttonStyle(MomentsCreateFinalVideoButtonStyle())
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
        isReadyToFinish ? L10n.string("create.final.finishGallery") : downloadTitle
    }

    private var buttonIconName: String {
        isReadyToFinish ? "checkmark.circle.fill" : "arrow.down.to.line.compact"
    }

    private var action: () -> Void {
        isReadyToFinish ? finish : download
    }
}

private struct MomentsCreateFinalVideoButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .background(
                LinearGradient(
                    colors: [
                        AVBrandColor.accent.opacity(isEnabled ? 1 : 0.52),
                        AVBrandColor.accent.opacity(isEnabled ? 0.82 : 0.42)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(Color.white.opacity(configuration.isPressed ? 0.26 : 0.18), lineWidth: 1)
            }
            .shadow(color: AVBrandColor.accent.opacity(isEnabled ? 0.26 : 0), radius: 14, y: 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(isEnabled ? 1 : 0.72)
    }
}

private struct MomentsCreateFinalVideoConfirmationSheet: View {
    let action: MomentsCreateFinalVideoActionPresentation
    let mediaSummary: MomentsCreateMediaSummary
    let confirm: (Bool) -> Void
    let openCredits: () -> Void
    let cancel: () -> Void
    @State private var removesWatermark: Bool
    @State private var isSubmitting = false

    init(
        action: MomentsCreateFinalVideoActionPresentation,
        mediaSummary: MomentsCreateMediaSummary,
        confirm: @escaping (Bool) -> Void,
        openCredits: @escaping () -> Void,
        cancel: @escaping () -> Void
    ) {
        self.action = action
        self.mediaSummary = mediaSummary
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
        .presentationBackground(MomentsTheme.shellBackground)
    }

    private var sheetContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            VStack(spacing: 8) {
                MomentsCreateConfirmationMetric(
                    title: L10n.string("create.final.confirmSheet.cost"),
                    value: selectedCreditCostTitle,
                    systemImage: "creditcard.fill"
                )
                MomentsCreateConfirmationMetric(
                    title: L10n.string("create.final.confirmSheet.media"),
                    value: mediaUsageTitle,
                    systemImage: "photo.stack"
                )
                MomentsCreateConfirmationMetric(
                    title: L10n.string("create.final.confirmSheet.duration"),
                    value: durationTitle,
                    systemImage: "timer"
                )
                MomentsCreateConfirmationMetric(
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
                .buttonStyle(MomentsCreateNeutralInlineButtonStyle())
            }
        }
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
                MomentsCreateCostDetailRow(
                    title: L10n.string("create.final.costDetails.video"),
                    detail: durationTitle,
                    value: MomentsCreditCopy.countTitle(plan?.creditCost ?? action.totalCreditCost)
                )

                MomentsCreateCostDetailRow(
                    title: L10n.string("create.final.costDetails.watermark"),
                    detail: watermarkCostDetail,
                    value: watermarkCostTitle
                )

                Divider()
                    .overlay(AVBrandColor.textSecondary.opacity(0.14))

                MomentsCreateCostDetailRow(
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
            Image(systemName: "video.fill")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(AVBrandColor.textPrimary, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.string("create.final.confirmSheet.title"))
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Text(L10n.string("create.final.confirmSheet.detail"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var plan: MomentsRenderPlan? {
        action.summary.renderPlan?.plan
    }

    private var watermark: MomentsRenderWatermarkPlan? {
        action.summary.renderPlan?.watermark
    }

    private var selectedCreditCost: Int {
        if let videoQuote = action.summary.videoQuote {
            if removesWatermark,
               !videoQuote.branding.removalIncluded,
               !videoQuote.branding.removalRequested {
                return videoQuote.totalCreditCost + videoQuote.brandingRemovalCreditCost
            }
            return videoQuote.totalCreditCost
        }
        let baseCost = plan?.creditCost ?? action.totalCreditCost
        guard removesWatermark,
              watermark?.userHasWatermarkFree != true else {
            return action.totalCreditCost
        }
        return baseCost + (watermark?.nonProRemovalCreditCost ?? action.balance.watermarkRemovalCreditCost)
    }

    private var selectedCreditCostTitle: String {
        MomentsCreditCopy.countTitle(selectedCreditCost)
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
        return MomentsCreateAvailabilityCopy.finalRenderInsufficientCredits(missingCredits: missingCredits)
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
                            MomentsCreditCopy.countTitle(videoQuote.brandingRemovalCreditCost)
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
        } else if let watermark {
            Toggle(isOn: $removesWatermark) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.string(
                        "create.final.watermark.remove",
                        MomentsCreditCopy.countTitle(watermark.nonProRemovalCreditCost)
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
                return MomentsCreditCopy.countTitle(videoQuote.brandingRemovalCreditCost)
            }
            return L10n.string("create.final.costDetails.noExtraCost")
        }
        if watermark?.userHasWatermarkFree == true {
            return L10n.string("create.final.costDetails.includedWithPro")
        }
        if removesWatermark {
            return MomentsCreditCopy.countTitle(watermark?.nonProRemovalCreditCost ?? action.balance.watermarkRemovalCreditCost)
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

private struct MomentsCreateCostDetailRow: View {
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

private struct MomentsCreateConfirmationMetric: View {
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

private struct MomentsCreateRealtimeRenderStatusPanel: View {
    let status: MomentsRenderRealtimePresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
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

            if let progressFraction = status.progressFraction {
                ProgressView(value: progressFraction)
                    .tint(iconColor)
                    .accessibilityLabel(L10n.string("create.workflowContent.finalVideoProgress"))
                    .accessibilityValue("\(Int((progressFraction * 100).rounded())) percent")
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

private struct MomentsCreateGuideSummaryCard: View {
    @Binding var form: MomentSetupForm
    let style: MomentCreationStyle
    let selectedMusicPreset: MomentMusicPreset
    let changeTheme: () -> Void
    let changeLook: () -> Void
    let changeLength: () -> Void
    let changeMood: () -> Void
    let selectMusicPreset: (MomentMusicPreset) -> Void

    var body: some View {
        AVAppShellCard {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.string("create.guide.videoSetup.title"))
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)

                VStack(spacing: 0) {
                    MomentsCreateEditableOptionRow(
                        title: L10n.string("create.guide.theme.title"),
                        value: style.title,
                        detail: style.subtitle,
                        systemImage: "paintpalette.fill",
                        action: changeTheme
                    )

                    MomentsCreateOptionDivider()

                    MomentsCreateEditableOptionRow(
                        title: L10n.string("create.guide.look.title"),
                        value: form.look.title,
                        detail: form.look.subtitle,
                        systemImage: form.look.systemImage,
                        action: changeLook
                    )

                    MomentsCreateOptionDivider()

                    MomentsCreateEditableOptionRow(
                        title: L10n.string("create.guide.mood.title"),
                        value: selectedMusicPreset.title,
                        detail: L10n.string("create.guide.mood.detail"),
                        systemImage: "sparkles",
                        action: changeMood
                    )

                    MomentsCreateOptionDivider()

                    MomentsCreateEditableOptionRow(
                        title: L10n.string("create.guide.length.title"),
                        value: form.duration.title,
                        detail: lengthDetail,
                        systemImage: "timer",
                        action: changeLength
                    )
                }
            }
        }
    }

    private var lengthDetail: String {
        switch form.duration {
        case .auto:
            return L10n.string("create.guide.length.auto.detail")
        case .short:
            return L10n.string("create.guide.length.short.detail")
        case .standard:
            return L10n.string("create.guide.length.standard.detail")
        case .extended:
            return L10n.string("create.guide.length.extended.detail")
        }
    }
}

private struct MomentsCreateEditableOptionRow: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 14) {
                MomentsCreateGuideFieldIcon(systemImage: systemImage)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundStyle(AVBrandColor.textSecondary)

                    Text(value)
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)
                        .lineLimit(1)

                    Text(detail)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .lineLimit(2)
                }
                .layoutPriority(1)

                Spacer(minLength: 8)

                MomentsCreateOptionActionText()
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(RoundedRectangle(cornerRadius: AVBrandRadius.xs, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct MomentsCreateOptionActionText: View {
    var body: some View {
        Image(systemName: "square.and.pencil")
            .font(.system(size: 13, weight: .black))
            .foregroundStyle(AVBrandColor.accent)
            .frame(width: 32, height: 32)
            .background(AVBrandColor.accent.opacity(0.08), in: Circle())
    }
}

private struct MomentsCreateOptionDivider: View {
    var body: some View {
        Rectangle()
            .fill(AVBrandColor.borderSubtle.opacity(0.42))
            .frame(height: 1)
            .padding(.leading, 42)
    }
}

private struct MomentsCreateOptionsAviPanel: View {
    let selectedStyle: MomentCreationStyle
    let selectedMusicPreset: MomentMusicPreset
    let autoStyleSuggestion: MomentsMediaAutoStyleSuggestion?
    let canUndoAutoStyleSuggestion: Bool
    let useAutoStyleSuggestion: () -> Void
    let undoAutoStyleSuggestion: () -> Void

    var body: some View {
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
                    Text(L10n.string("create.aviDirection.title"))
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)

                    Text(message)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)

                    if autoStyleSuggestion != nil {
                        HStack(spacing: 8) {
                            if canUndoAutoStyleSuggestion {
                                MomentsCreateAviSuggestionButton(
                                    title: L10n.string("create.aviDirection.undoSuggestion"),
                                    systemImage: "arrow.uturn.backward",
                                    action: undoAutoStyleSuggestion
                                )
                            } else if showsUseAviSuggestion {
                                MomentsCreateAviSuggestionButton(
                                    title: L10n.string("create.aviDirection.useSuggestion"),
                                    systemImage: "sparkles",
                                    action: useAutoStyleSuggestion
                                )
                            }
                        }
                        .padding(.top, 2)
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var message: String {
        guard let autoStyleSuggestion else {
            return L10n.string("create.aviDirection.defaultMessage")
        }

        if isUsingAviSuggestion {
            return L10n.string("create.aviDirection.usingSuggestion", selectedStyle.title.lowercased())
        }

        if isUsingAviDirection {
            return L10n.string("create.aviDirection.changedMusic", selectedStyle.title.lowercased())
        }

        let suggestedTitle = suggestedStyleTitle(for: autoStyleSuggestion.styleID)
        return L10n.string("create.aviDirection.changedDirection", selectedStyle.title.lowercased(), suggestedTitle.lowercased())
    }

    private var isUsingAviSuggestion: Bool {
        guard let autoStyleSuggestion else { return false }
        return selectedStyle.id == autoStyleSuggestion.styleID
            && selectedMusicPreset == autoStyleSuggestion.musicPreset
    }

    private var isUsingAviDirection: Bool {
        guard let autoStyleSuggestion else { return false }
        return selectedStyle.id == autoStyleSuggestion.styleID
    }

    private var showsUseAviSuggestion: Bool {
        autoStyleSuggestion != nil && !isUsingAviSuggestion
    }

    private func suggestedStyleTitle(for id: MomentCreationStyleID) -> String {
        switch id {
        case .celebration: L10n.string("create.theme.celebration.title")
        case .eventRecap: L10n.string("create.theme.eventRecap.title")
        case .travel: L10n.string("create.theme.travel.title")
        case .favoritePeople: L10n.string("create.theme.favoritePeople.title")
        case .birthday: L10n.string("create.theme.birthday.title")
        case .familyMoments: L10n.string("create.theme.familyMoments.title")
        case .softRoast: L10n.string("create.theme.softRoast.title")
        case .milestone: L10n.string("create.theme.milestone.title")
        }
    }
}

private struct MomentsCreateAviSuggestionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(AVBrandColor.accent)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(AVBrandColor.accent.opacity(0.09), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct MomentsCreateAviNoteField: View {
    @Binding var text: String

    var body: some View {
        AVAppShellCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.string("create.note.title"))
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 10) {
                        MomentsCreateGuideFieldIcon(systemImage: "text.bubble.fill")

                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.string("create.note.field.title"))
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(AVBrandColor.textSecondary)
                                .textCase(.uppercase)

                            Text(L10n.string("create.note.field.subtitle"))
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(AVBrandColor.textSecondary.opacity(0.82))
                        }

                        Spacer(minLength: 0)
                    }

                    TextField(L10n.string("create.note.placeholder"), text: $text, axis: .vertical)
                        .font(AVBrandTypography.body)
                        .foregroundStyle(AVBrandColor.textPrimary)
                        .lineLimit(2...4)
                        .textInputAutocapitalization(.sentences)
                        .submitLabel(.done)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(MomentsCreateGuideFieldBackground())
            }
        }
    }
}

private struct MomentsCreateAviNoteEditorPage: View {
    @Binding var text: String
    let dismiss: () -> Void
    @State private var draftText: String

    init(text: Binding<String>, dismiss: @escaping () -> Void) {
        self._text = text
        self.dismiss = dismiss
        self._draftText = State(initialValue: text.wrappedValue)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                MomentsCreateChooserHeader(
                    title: L10n.string("create.note.field.title"),
                    dismiss: dismiss
                )
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
                                    Text(L10n.string("create.note.title"))
                                        .font(.system(size: 14, weight: .black))
                                        .foregroundStyle(AVBrandColor.textPrimary)

                                    Text(L10n.string("create.note.field.subtitle"))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AVBrandColor.textSecondary)
                                        .lineLimit(2)
                                }

                                Spacer(minLength: 0)
                            }
                        }

                        AVAppShellCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .center, spacing: 10) {
                                    MomentsCreateGuideFieldIcon(systemImage: "text.bubble.fill")

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(L10n.string("create.note.field.title"))
                                            .font(.system(size: 11, weight: .black))
                                            .foregroundStyle(AVBrandColor.textSecondary)
                                            .textCase(.uppercase)

                                        Text(L10n.string("create.note.field.subtitle"))
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(AVBrandColor.textSecondary.opacity(0.82))
                                    }

                                    Spacer(minLength: 0)
                                }

                                TextField(L10n.string("create.note.placeholder"), text: $draftText, axis: .vertical)
                                    .font(AVBrandTypography.body)
                                    .foregroundStyle(AVBrandColor.textPrimary)
                                    .lineLimit(6...10)
                                    .textInputAutocapitalization(.sentences)
                                    .submitLabel(.done)
                                    .frame(maxWidth: .infinity, minHeight: 164, alignment: .topLeading)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(MomentsCreateGuideFieldBackground())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .safeAreaPadding(.bottom, 200)
                }
                .scrollIndicators(.hidden)
            }

            MomentsCreateFixedFooterAction(
                title: L10n.string("common.done"),
                systemImage: "checkmark.circle.fill",
                action: applyChanges
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 96)
        }
        .background(MomentsTheme.shellBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func applyChanges() {
        text = draftText
        dismiss()
    }
}

private struct MomentsCreateGuideFieldIcon: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(AVBrandColor.accent)
            .frame(width: 28, height: 28)
            .background(
                AVBrandColor.accent.opacity(0.12),
                in: RoundedRectangle(cornerRadius: AVBrandRadius.xs, style: .continuous)
            )
    }
}

private struct MomentsCreateGuideFieldBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: AVBrandRadius.xs, style: .continuous)
            .fill(AVBrandColor.cardSurface.opacity(0.72))
            .overlay {
                RoundedRectangle(cornerRadius: AVBrandRadius.xs, style: .continuous)
                    .stroke(AVBrandColor.borderSubtle.opacity(0.5), lineWidth: 1)
            }
    }
}

private struct MomentsCreateTwoColumnGrid<Item: Identifiable, Content: View>: View {
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

private struct MomentsCreateLookChooserPage: View {
    let selectedLook: MomentLook
    let selectLook: (MomentLook) -> Void
    let dismiss: () -> Void

    @State private var setupLook: MomentLook

    init(
        selectedLook: MomentLook,
        selectLook: @escaping (MomentLook) -> Void,
        dismiss: @escaping () -> Void
    ) {
        self.selectedLook = selectedLook
        self.selectLook = selectLook
        self.dismiss = dismiss
        _setupLook = State(initialValue: selectedLook)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                MomentsCreateChooserHeader(
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

                        MomentsCreateTwoColumnGrid(items: MomentLook.selectorOrder) { look in
                            MomentsCreateLookImageTile(
                                look: look,
                                isSelected: setupLook == look,
                                selectLook: { setupLook = look }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .safeAreaPadding(.bottom, 200)
                }
                .scrollIndicators(.hidden)
            }

            MomentsCreateFixedFooterAction(
                title: L10n.string("common.done"),
                systemImage: "checkmark.circle.fill",
                action: applySelection
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 96)
        }
        .background(MomentsTheme.shellBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }

    private func applySelection() {
        selectLook(setupLook)
        dismiss()
    }
}

private struct MomentsCreateLookImageTile: View {
    let look: MomentLook
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

private struct MomentsCreateLengthChooserPage: View {
    let selectedDuration: MomentDuration
    let selectDuration: (MomentDuration) -> Void
    let dismiss: () -> Void

    @State private var setupDuration: MomentDuration

    init(
        selectedDuration: MomentDuration,
        selectDuration: @escaping (MomentDuration) -> Void,
        dismiss: @escaping () -> Void
    ) {
        self.selectedDuration = selectedDuration
        self.selectDuration = selectDuration
        self.dismiss = dismiss
        _setupDuration = State(initialValue: selectedDuration)
    }

    var body: some View {
        MomentsCreateVisualOptionChooserPage(
            title: L10n.string("create.selector.length.title"),
            introTitle: L10n.string("create.selector.length.intro.title"),
            introDetail: L10n.string("create.selector.length.intro.detail"),
            dismiss: dismiss,
            confirm: applySelection
        ) {
            MomentsCreateTwoColumnGrid(items: MomentDuration.allCases) { duration in
                    MomentsCreateVisualOptionTile(
                        title: duration.title,
                        detail: detail(for: duration),
                        assetName: duration.assetName,
                        isSelected: setupDuration == duration,
                        select: { setupDuration = duration }
                    )
            }
        }
    }

    private func applySelection() {
        selectDuration(setupDuration)
        dismiss()
    }

    private func detail(for duration: MomentDuration) -> String {
        switch duration {
        case .auto:
            return L10n.string("create.selector.length.auto.detail")
        case .short:
            return L10n.string("create.selector.length.short.detail")
        case .standard:
            return L10n.string("create.selector.length.standard.detail")
        case .extended:
            return L10n.string("create.selector.length.extended.detail")
        }
    }
}

private struct MomentsCreateMoodChooserPage: View {
    let allowedMusic: [MomentMusicPreset]
    let selectedMusicPreset: MomentMusicPreset
    let selectMusicPreset: (MomentMusicPreset) -> Void
    let dismiss: () -> Void

    @State private var setupMusicPreset: MomentMusicPreset

    init(
        allowedMusic: [MomentMusicPreset],
        selectedMusicPreset: MomentMusicPreset,
        selectMusicPreset: @escaping (MomentMusicPreset) -> Void,
        dismiss: @escaping () -> Void
    ) {
        self.allowedMusic = allowedMusic
        self.selectedMusicPreset = selectedMusicPreset
        self.selectMusicPreset = selectMusicPreset
        self.dismiss = dismiss
        _setupMusicPreset = State(initialValue: selectedMusicPreset)
    }

    var body: some View {
        MomentsCreateVisualOptionChooserPage(
            title: L10n.string("create.selector.mood.title"),
            introTitle: L10n.string("create.selector.mood.intro.title"),
            introDetail: L10n.string("create.selector.mood.intro.detail"),
            dismiss: dismiss,
            confirm: applySelection
        ) {
            MomentsCreateTwoColumnGrid(items: allowedMusic) { preset in
                    MomentsCreateVisualOptionTile(
                        title: preset.title,
                        detail: detail(for: preset),
                        assetName: preset.assetName,
                        isSelected: setupMusicPreset == preset,
                        select: { setupMusicPreset = preset }
                    )
            }
        }
    }

    private func applySelection() {
        selectMusicPreset(setupMusicPreset)
        dismiss()
    }

    private func detail(for preset: MomentMusicPreset) -> String {
        switch preset {
        case .warm:
            return L10n.string("create.selector.mood.warm.detail")
        case .fun:
            return L10n.string("create.selector.mood.fun.detail")
        case .cinematic:
            return L10n.string("create.selector.mood.cinematic.detail")
        case .calm:
            return L10n.string("create.selector.mood.calm.detail")
        case .upbeat:
            return L10n.string("create.selector.mood.upbeat.detail")
        }
    }
}

private struct MomentsCreateVisualOptionChooserPage<Content: View>: View {
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
                MomentsCreateChooserHeader(title: title, dismiss: dismiss)
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

            MomentsCreateFixedFooterAction(
                title: L10n.string("common.done"),
                systemImage: "checkmark.circle.fill",
                action: confirm
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 96)
        }
        .background(MomentsTheme.shellBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct MomentsCreateVisualOptionTile: View {
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

private struct MomentsCreateThemeChooserPage: View {
    let styles: [MomentCreationStyle]
    let selectedStyle: MomentCreationStyle
    let selectStyle: (MomentCreationStyle) -> Void
    let dismiss: () -> Void

    @State private var setupStyleID: MomentCreationStyleID

    init(
        styles: [MomentCreationStyle],
        selectedStyle: MomentCreationStyle,
        selectStyle: @escaping (MomentCreationStyle) -> Void,
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
                MomentsCreateThemeChooserHeader(
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

                        MomentsCreateTwoColumnGrid(items: styles) { style in
                            MomentsCreateThemeImageTile(
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

            MomentsCreateFixedFooterAction(
                title: L10n.string("common.done"),
                systemImage: "checkmark.circle.fill",
                action: applySelection
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 96)
        }
        .background(MomentsTheme.shellBackground.ignoresSafeArea())
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

private struct MomentsCreateThemeChooserHeader: View {
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

private struct MomentsCreateChooserHeader: View {
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

private struct MomentsCreateThemeImageTile: View {
    let style: MomentCreationStyle
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
