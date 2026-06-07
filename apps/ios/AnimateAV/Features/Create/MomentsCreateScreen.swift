import AVAppShellFoundation
import PhotosUI
import SwiftUI

struct MomentsCreateScreen: View {
    @EnvironmentObject private var viewModel: MomentsCreateViewModel
    @EnvironmentObject private var newMomentStartController: MomentsNewMomentStartController
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
        MomentsCreateWorkflowContent(
            viewModel: viewModel,
            pickerItems: $pickerItems,
            startSignInFlow: startSignInFlow,
            openCredits: openCredits,
            finishFinalVideoToGallery: finishFinalVideoToGallery
        )
        .background(MomentsTheme.shellBackground.ignoresSafeArea())
        .safeAreaPadding(.horizontal, 20)
        .safeAreaPadding(.top, 12)
        .safeAreaPadding(.bottom, bottomSafeAreaPadding)
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
        .fullScreenCover(
            isPresented: Binding(
                get: {
                    viewModel.workflowPresentation.showsBlockingPreparation
                        || viewModel.isPreparingStory
                        || viewModel.isPreparingFinalPlan
                },
                set: { _ in }
            )
        ) {
            MomentsCreateBlockingPreparationView(
                presentation: viewModel.workflowPresentation,
                isPreparingStory: viewModel.isPreparingStory,
                isPreparingFinalPlan: viewModel.isPreparingFinalPlan
            )
            .interactiveDismissDisabled()
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

    private var automaticPhotoPickerSelectionLimit: Int {
        max(1, viewModel.workflowPresentation.mediaSummary.remainingSlots(template: viewModel.form.template))
    }

    private func redirectEmptyCreateIfNeeded() {
        guard !viewModel.workflowPresentation.showsMediaFirstWorkspace,
              !viewModel.isContinuingMoment
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

enum MomentsCreateSection: Hashable {
    case moment
    case media
    case story
    case finalRender

    init(focus: MomentsContinuationFocus) {
        switch focus {
        case .moment:
            self = .moment
        case .media:
            self = .media
        case .story:
            self = .story
        case .finalRender:
            self = .finalRender
        }
    }
}
