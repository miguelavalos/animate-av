import AVAppShellFoundation
import AVBrandFoundation
import SwiftUI

struct AnimateInProgressScreen: View {
    @EnvironmentObject private var viewModel: AnimateInProgressViewModel
    @EnvironmentObject private var createViewModel: AnimateCreateViewModel
    @State private var momentPendingDeletion: AnimateVideo?
    @State private var momentPendingRename: AnimateVideo?
    @SceneStorage("animate.inProgress.selectedAssetKind") private var selectedAssetKindRaw = AnimateInProgressAssetKind.videos.rawValue
    let balance: AnimateCreditBalance
    let creditBalanceLoadState: AnimateCreditBalanceLoadState
    let continueVideo: (AnimateContinuationRequest) -> Void
    let startMoment: () -> Void
    let startSignInFlow: () -> Void
    let openCredits: () -> Void
    let retryCredits: () -> Void

    private var presentation: AnimateInProgressPresentation {
        AnimateInProgressPresentation.make(
            isSignedIn: viewModel.isSignedIn,
            videosSummary: viewModel.videoMomentsSummary,
            momentPendingDeletion: momentPendingDeletion
        )
    }

    private var imagesPresentation: AnimateInProgressPresentation {
        AnimateInProgressPresentation.make(
            isSignedIn: viewModel.isSignedIn,
            videosSummary: viewModel.imageMomentsSummary,
            momentPendingDeletion: nil
        )
    }

    init(
        balance: AnimateCreditBalance = .empty,
        creditBalanceLoadState: AnimateCreditBalanceLoadState = .loaded,
        continueVideo: @escaping (AnimateContinuationRequest) -> Void = { _ in },
        startMoment: @escaping () -> Void = {},
        startSignInFlow: @escaping () -> Void = {},
        openCredits: @escaping () -> Void = {},
        retryCredits: @escaping () -> Void = {}
    ) {
        self.balance = balance
        self.creditBalanceLoadState = creditBalanceLoadState
        self.continueVideo = continueVideo
        self.startMoment = startMoment
        self.startSignInFlow = startSignInFlow
        self.openCredits = openCredits
        self.retryCredits = retryCredits
    }

    var body: some View {
        AVAppShellScrollableScreenScaffold {
            AnimateTheme.shellBackground
        } content: {
            AnimateInProgressAssetKindPicker(selectedAssetKind: selectedAssetKindBinding)

            switch selectedAssetKind {
            case .videos:
                if createViewModel.hasLocalAnimateWorkspace {
                    MomentsCurrentCreationCard(
                        selectedCount: createViewModel.mediaSelectedCount,
                        continueCreation: startMoment
                    )
                }

                AnimateInProgressCard(
                    presentation: presentation,
                    balance: balance,
                    creditBalanceLoadState: creditBalanceLoadState,
                    videosSummary: viewModel.videoMomentsSummary,
                    selectedMomentId: viewModel.selectedMomentId,
                    isLoadingAnimateWorkspace: viewModel.isLoadingAnimateWorkspace,
                    activeWorkspace: viewModel.activeWorkspace,
                    isDeletingVideo: viewModel.isDeletingVideo,
                    statusMessage: viewModel.statusMessage,
                    localMediaForMoment: localMediaForMoment(_:),
                    selectMoment: viewModel.selectMoment,
                    continueVideo: continueVideo,
                    requestRenameMoment: { momentPendingRename = $0 },
                    startMoment: startMoment,
                    startSignInFlow: startSignInFlow,
                    openCredits: openCredits,
                    retryCredits: retryCredits
                )
            case .images:
                AnimateInProgressImagesCard(
                    presentation: imagesPresentation,
                    videosSummary: viewModel.imageMomentsSummary,
                    startSignInFlow: startSignInFlow,
                    startImages: startMoment
                )
            }
        }
        .confirmationDialog(
            L10n.string("inProgress.deleteVideo.title"),
            isPresented: deletionConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(L10n.string("inProgress.deleteVideo.button"), role: .destructive) {
                confirmVideoDeletion()
            }
            Button(L10n.string("common.cancel"), role: .cancel) {
                cancelVideoDeletion()
            }
        } message: {
            Text(presentation.deletionMessage)
        }
        .sheet(item: $momentPendingRename) { moment in
            AnimateInProgressRenameSheet(moment: moment) { title in
                viewModel.renameVideo(moment, title: title)
            }
            .presentationDetents([.height(230)])
        }
    }

    private var deletionConfirmationPresented: Binding<Bool> {
        Binding(
            get: { momentPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    momentPendingDeletion = nil
                }
            }
        )
    }

    private var selectedAssetKind: AnimateInProgressAssetKind {
        AnimateInProgressAssetKind(rawValue: selectedAssetKindRaw) ?? .videos
    }

    private var selectedAssetKindBinding: Binding<AnimateInProgressAssetKind> {
        Binding(
            get: { selectedAssetKind },
            set: { selectedAssetKindRaw = $0.rawValue }
        )
    }

    private func confirmVideoDeletion() {
        if let momentPendingDeletion {
            if createViewModel.activeMomentId == momentPendingDeletion.id {
                createViewModel.clearSessionState()
            }
            viewModel.deleteVideo(momentPendingDeletion)
        }
        momentPendingDeletion = nil
    }

    private func cancelVideoDeletion() {
        momentPendingDeletion = nil
    }

    private func localMediaForMoment(_ moment: AnimateVideo) -> [AnimateSelectedMedia] {
        if createViewModel.activeMomentId == moment.id {
            return createViewModel.selectedMedia
        }

        guard !createViewModel.selectedMedia.isEmpty,
              viewModel.videosSummary.latestAnimateVideo?.id == moment.id,
              viewModel.videoMomentsSummary.inProgressCount == 1 else {
            return []
        }

        return createViewModel.selectedMedia
    }
}

private struct AnimateInProgressAssetKindPicker: View {
    @Binding var selectedAssetKind: AnimateInProgressAssetKind

    var body: some View {
        HStack(spacing: 8) {
            ForEach(AnimateInProgressAssetKind.allCases) { kind in
                Button {
                    selectedAssetKind = kind
                } label: {
                    AnimateInProgressAssetKindPill(
                        title: kind.title,
                        isSelected: selectedAssetKind == kind
                    )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedAssetKind == kind ? .isSelected : [])
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(L10n.string("inProgress.assetKind.accessibility"))
    }
}

private struct AnimateInProgressAssetKindPill: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .black))
            .frame(maxWidth: .infinity)
            .frame(height: 38)
            .foregroundStyle(isSelected ? .white : AVBrandColor.textPrimary)
            .background(background)
            .overlay(border)
    }

    private var background: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(isSelected ? AVBrandColor.accent : AVBrandColor.elevatedSurface)
    }

    private var border: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(AVBrandColor.borderSubtle.opacity(isSelected ? 0 : 0.55), lineWidth: 1)
    }
}

private struct AnimateInProgressImagesCard: View {
    let presentation: AnimateInProgressPresentation
    let videosSummary: AnimateInProgressSummary
    let startSignInFlow: () -> Void
    let startImages: () -> Void

    var body: some View {
        AVAppShellCard {
            switch presentation.availability {
            case let .signedOut(unavailable):
                AnimateInProgressInlineEmptyState(
                    systemImage: unavailable.systemImage,
                    title: unavailable.title,
                    message: unavailable.message,
                    actionTitle: L10n.string("common.signIn"),
                    actionSystemImage: "person.crop.circle.fill",
                    action: startSignInFlow
                )
            case .empty:
                AnimateInProgressImagesEmptyState(startImages: startImages)
            case .available:
                AnimateInProgressList(
                    videosSummary: videosSummary,
                    selectedMomentId: nil,
                    selectMoment: { _ in }
                )
            }
        }
    }
}

private enum AnimateInProgressAssetKind: String, CaseIterable, Identifiable {
    case videos
    case images

    var id: String { rawValue }

    var title: String {
        switch self {
        case .videos:
            L10n.string("inProgress.assetKind.videos")
        case .images:
            L10n.string("inProgress.assetKind.images")
        }
    }
}

private struct AnimateInProgressImagesEmptyState: View {
    let startImages: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: 14) {
            Image(systemName: "photo.badge.clock")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(AVBrandColor.accent)
                .frame(width: 74, height: 74)
                .background(Circle().fill(AVBrandColor.accent.opacity(0.10)))

            VStack(spacing: 6) {
                Text(L10n.string("inProgress.images.empty.title"))
                    .font(.system(size: 20, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)

                Text(L10n.string("inProgress.images.empty.detail"))
                    .font(AVBrandTypography.body)
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: startImages) {
                Label(L10n.string("create.images.action.start"), systemImage: "photo.badge.plus")
                    .font(.system(size: 14, weight: .black))
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AVBrandRadius.card, style: .continuous)
                .fill(AVBrandColor.elevatedSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AVBrandRadius.card, style: .continuous)
                .stroke(AVBrandColor.borderSubtle.opacity(0.55), lineWidth: 1)
        )
    }
}

private struct AnimateInProgressRenameSheet: View {
    let moment: AnimateVideo
    let save: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title: String

    init(moment: AnimateVideo, save: @escaping (String) -> Void) {
        self.moment = moment
        self.save = save
        _title = State(initialValue: moment.title)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField(L10n.string("inProgress.rename.placeholder"), text: $title)
                    .textInputAutocapitalization(.words)
            }
            .navigationTitle(L10n.string("inProgress.rename.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("common.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.string("common.save")) {
                        save(title)
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
