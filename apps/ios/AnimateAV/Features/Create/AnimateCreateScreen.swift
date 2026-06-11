import AVAppShellFoundation
import PhotosUI
import SwiftUI

struct AnimateCreateScreen: View {
    @EnvironmentObject private var viewModel: AnimateCreateViewModel
    @EnvironmentObject private var newVideoStartController: AnimateNewVideoStartController
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showsAutomaticPhotoPicker = false
    @State private var handledAutomaticPhotoPickerRequest = 0
    @State private var workflowErrorAlertMessage: String?
    let startSignInFlow: () -> Void
    let openCredits: () -> Void
    let cancelCreation: () -> Void
    let finishFinalVideoToGallery: () -> Void
    let bottomSafeAreaPadding: CGFloat

    init(
        startSignInFlow: @escaping () -> Void,
        openCredits: @escaping () -> Void,
        cancelCreation: @escaping () -> Void,
        finishFinalVideoToGallery: @escaping () -> Void,
        bottomSafeAreaPadding: CGFloat = 82
    ) {
        self.startSignInFlow = startSignInFlow
        self.openCredits = openCredits
        self.cancelCreation = cancelCreation
        self.finishFinalVideoToGallery = finishFinalVideoToGallery
        self.bottomSafeAreaPadding = bottomSafeAreaPadding
    }

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 12) {
                AnimateCreateWorkflowContent(
                    viewModel: viewModel,
                    pickerItems: $pickerItems,
                    startSignInFlow: startSignInFlow,
                    openCredits: openCredits,
                    finishFinalVideoToGallery: finishFinalVideoToGallery
                )
            }
            .safeAreaPadding(.horizontal, 20)
            .safeAreaPadding(.top, 12)
            .safeAreaPadding(.bottom, bottomSafeAreaPadding)

            if showsBlockingPreparation {
                AnimateCreateBlockingPreparationView(
                    presentation: viewModel.workflowPresentation,
                    isPreparingVideoDirectionAction: viewModel.isPreparingVideoDirectionAction,
                    isPreparingFinalPlan: viewModel.isPreparingFinalPlan
                )
                .ignoresSafeArea()
                .zIndex(10)
            }

            if viewModel.isPreparingFinalPlan {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .zIndex(8)
                    .accessibilityHidden(true)
            }
        }
        .background(AnimateTheme.shellBackground.ignoresSafeArea())
        .task {
            redirectEmptyCreateIfNeeded()
            openAutomaticPhotoPickerIfRequested(viewModel.mediaPickerOpenRequest)
        }
        .onChange(of: viewModel.workflowPresentation.showsMediaFirstWorkspace) { _, showsWorkspace in
            guard !showsWorkspace else { return }
            redirectEmptyCreateIfNeeded()
        }
        .photosPicker(
            isPresented: $showsAutomaticPhotoPicker,
            selection: $pickerItems,
            maxSelectionCount: automaticPhotoPickerSelectionLimit,
            matching: .images
        )
        .onChange(of: viewModel.mediaPickerOpenRequest) { _, request in
            openAutomaticPhotoPickerIfRequested(request)
        }
        .onChange(of: pickerItems) { _, newItems in
            guard !newItems.isEmpty else { return }
            viewModel.importPickerItems(newItems)
            pickerItems = []
        }
        .onChange(of: viewModel.workflowErrorAlertMessage) { _, message in
            workflowErrorAlertMessage = message
        }
        .alert(L10n.string("access.error.title"), isPresented: Binding(
            get: { workflowErrorAlertMessage != nil },
            set: { isPresented in
                if !isPresented {
                    workflowErrorAlertMessage = nil
                }
            }
        )) {
            Button(L10n.string("common.ok"), role: .cancel) {
                workflowErrorAlertMessage = nil
            }
        } message: {
            Text(workflowErrorAlertMessage ?? L10n.string("common.tryAgain"))
        }
    }

    private var showsBlockingPreparation: Bool {
        viewModel.workflowPresentation.showsBlockingPreparation
            || viewModel.isPreparingVideoDirectionAction
    }

    private var automaticPhotoPickerSelectionLimit: Int {
        1
    }

    private func redirectEmptyCreateIfNeeded() {
        guard !viewModel.workflowPresentation.showsMediaFirstWorkspace,
              !viewModel.isContinuingVideoCreation
        else { return }
        cancelCreation()
    }

    private func openAutomaticPhotoPickerIfRequested(_ request: Int) {
        guard request > handledAutomaticPhotoPickerRequest,
              viewModel.workflowPresentation.mediaSummary.selectedCount == 0 else { return }
        handledAutomaticPhotoPickerRequest = request
        viewModel.consumeMediaPickerOpenRequest()

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 350_000_000)
            showsAutomaticPhotoPicker = true
        }
    }
}

enum AnimateCreateAssetKind: String, CaseIterable, Identifiable {
    case video
    case images

    var id: String { rawValue }

    var title: String {
        switch self {
        case .video:
            L10n.string("create.assetKind.video")
        case .images:
            L10n.string("create.assetKind.images")
        }
    }
}

enum AnimateCreateSection: Hashable {
    case video
    case media
    case story
    case finalRender

    init(focus: AnimateContinuationFocus) {
        switch focus {
        case .video:
            self = .video
        case .media:
            self = .media
        case .story:
            self = .story
        case .finalRender:
            self = .finalRender
        }
    }
}
