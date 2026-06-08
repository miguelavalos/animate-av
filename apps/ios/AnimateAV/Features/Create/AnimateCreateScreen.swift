import AVAppShellFoundation
import PhotosUI
import SwiftUI

struct AnimateCreateScreen: View {
    @EnvironmentObject private var viewModel: AnimateCreateViewModel
    @EnvironmentObject private var newVideoStartController: AnimateNewVideoStartController
    @SceneStorage("animate.create.selectedAssetKind") private var selectedAssetKindRaw = AnimateCreateAssetKind.video.rawValue
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var showsAutomaticPhotoPicker = false
    @State private var handledAutomaticPhotoPickerRequest = 0
    @State private var workflowErrorAlertMessage: String?
    @Binding private var requestedAssetKind: AnimateCreateAssetKind?
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
        requestedAssetKind: Binding<AnimateCreateAssetKind?> = .constant(nil),
        bottomSafeAreaPadding: CGFloat = 82
    ) {
        self.startSignInFlow = startSignInFlow
        self.openCredits = openCredits
        self.cancelCreation = cancelCreation
        self.finishFinalVideoToGallery = finishFinalVideoToGallery
        _requestedAssetKind = requestedAssetKind
        self.bottomSafeAreaPadding = bottomSafeAreaPadding
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AnimateCreateAssetKindPicker(selectedAssetKind: selectedAssetKindBinding)

            switch selectedAssetKind {
            case .video:
                AnimateCreateWorkflowContent(
                    viewModel: viewModel,
                    pickerItems: $pickerItems,
                    startSignInFlow: startSignInFlow,
                    openCredits: openCredits,
                    finishFinalVideoToGallery: finishFinalVideoToGallery
                )
            case .images:
                AnimateCreateImagesWorkspace(
                    balance: viewModel.balance,
                    creditBalanceLoadState: viewModel.creditBalanceLoadState,
                    imageGenerationAvailability: viewModel.imageGenerationAvailability,
                    isLoadingImageGenerationAvailability: viewModel.isLoadingImageGenerationAvailability,
                    isStartingImageGeneration: viewModel.isStartingImageGeneration,
                    isPurchasingImageGenerationPack: viewModel.isPurchasingImageGenerationPack,
                    imageGenerationAvailabilityMessage: viewModel.imageGenerationAvailabilityMessage,
                    refreshImageGenerationAvailability: viewModel.refreshImageGenerationAvailability,
                    startImageGeneration: viewModel.startImageGeneration,
                    purchaseImageGenerationPack: viewModel.purchaseImageGenerationPack,
                    openCredits: openCredits
                )
            }
        }
        .background(AnimateTheme.shellBackground.ignoresSafeArea())
        .safeAreaPadding(.horizontal, 20)
        .safeAreaPadding(.top, 12)
        .safeAreaPadding(.bottom, bottomSafeAreaPadding)
        .task {
            applyRequestedAssetKindIfNeeded()
            redirectEmptyCreateIfNeeded()
            openAutomaticPhotoPickerIfRequested(viewModel.mediaPickerOpenRequest)
        }
        .onChange(of: requestedAssetKind) { _, _ in
            applyRequestedAssetKindIfNeeded()
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
                        || viewModel.isPreparingVideoDirectionAction
                        || viewModel.isPreparingFinalPlan
                },
                set: { _ in }
            )
        ) {
            AnimateCreateBlockingPreparationView(
                presentation: viewModel.workflowPresentation,
                isPreparingVideoDirectionAction: viewModel.isPreparingVideoDirectionAction,
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
        1
    }

    private var selectedAssetKind: AnimateCreateAssetKind {
        AnimateCreateAssetKind(rawValue: selectedAssetKindRaw) ?? .video
    }

    private var selectedAssetKindBinding: Binding<AnimateCreateAssetKind> {
        Binding(
            get: { selectedAssetKind },
            set: { selectedAssetKindRaw = $0.rawValue }
        )
    }

    private func redirectEmptyCreateIfNeeded() {
        guard selectedAssetKind == .video,
              !viewModel.workflowPresentation.showsMediaFirstWorkspace,
              !viewModel.isContinuingVideoCreation
        else { return }
        cancelCreation()
    }

    private func applyRequestedAssetKindIfNeeded() {
        guard let requestedAssetKind else { return }
        selectedAssetKindRaw = requestedAssetKind.rawValue
        self.requestedAssetKind = nil
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

private struct AnimateCreateAssetKindPicker: View {
    @Binding var selectedAssetKind: AnimateCreateAssetKind

    var body: some View {
        HStack(spacing: 8) {
            ForEach(AnimateCreateAssetKind.allCases) { kind in
                Button {
                    selectedAssetKind = kind
                } label: {
                    AnimateCreateAssetKindPill(
                        title: kind.title,
                        isSelected: selectedAssetKind == kind
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedAssetKind == kind ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.string("create.assetKind.accessibility"))
    }
}

private struct AnimateCreateAssetKindPill: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .black))
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .foregroundStyle(isSelected ? .white : AnimateTheme.textPrimary)
            .background(background)
            .overlay(border)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(isSelected ? AnimateTheme.highlight : Color(.secondarySystemGroupedBackground))
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(AnimateTheme.highlight.opacity(isSelected ? 0 : 0.18), lineWidth: 1)
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
