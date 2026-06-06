import AVAppShellFoundation
import SwiftUI

struct MomentsInProgressScreen: View {
    @EnvironmentObject private var viewModel: MomentsInProgressViewModel
    @EnvironmentObject private var createViewModel: MomentsCreateViewModel
    @State private var momentPendingDeletion: InProgressMoment?
    @State private var momentPendingRename: InProgressMoment?
    let balance: MomentsCreditBalance
    let creditBalanceLoadState: MomentsCreditBalanceLoadState
    let continueMoment: (MomentsContinuationRequest) -> Void
    let startMoment: () -> Void
    let startSignInFlow: () -> Void
    let openCredits: () -> Void
    let retryCredits: () -> Void

    private var presentation: MomentsInProgressPresentation {
        MomentsInProgressPresentation.make(
            isSignedIn: viewModel.isSignedIn,
            momentsSummary: viewModel.momentsSummary,
            momentPendingDeletion: momentPendingDeletion
        )
    }

    init(
        balance: MomentsCreditBalance = .empty,
        creditBalanceLoadState: MomentsCreditBalanceLoadState = .loaded,
        continueMoment: @escaping (MomentsContinuationRequest) -> Void = { _ in },
        startMoment: @escaping () -> Void = {},
        startSignInFlow: @escaping () -> Void = {},
        openCredits: @escaping () -> Void = {},
        retryCredits: @escaping () -> Void = {}
    ) {
        self.balance = balance
        self.creditBalanceLoadState = creditBalanceLoadState
        self.continueMoment = continueMoment
        self.startMoment = startMoment
        self.startSignInFlow = startSignInFlow
        self.openCredits = openCredits
        self.retryCredits = retryCredits
    }

    var body: some View {
        AVAppShellScrollableScreenScaffold {
            MomentsTheme.shellBackground
        } content: {
            if createViewModel.hasLocalMomentWorkspace {
                MomentsCurrentCreationCard(
                    selectedCount: createViewModel.mediaSelectedCount,
                    continueCreation: startMoment
                )
            }

            MomentsInProgressCard(
                presentation: presentation,
                balance: balance,
                creditBalanceLoadState: creditBalanceLoadState,
                momentsSummary: viewModel.momentsSummary,
                selectedMomentId: viewModel.selectedMomentId,
                isLoadingMomentWorkspace: viewModel.isLoadingMomentWorkspace,
                activeWorkspace: viewModel.activeWorkspace,
                isDeletingMoment: viewModel.isDeletingMoment,
                statusMessage: viewModel.statusMessage,
                localMediaForMoment: localMediaForMoment(_:),
                selectMoment: viewModel.selectMoment,
                continueMoment: continueMoment,
                requestRenameMoment: { momentPendingRename = $0 },
                startMoment: startMoment,
                startSignInFlow: startSignInFlow,
                openCredits: openCredits,
                retryCredits: retryCredits
            )
        }
        .confirmationDialog(
            L10n.string("inProgress.deleteMoment.title"),
            isPresented: deletionConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(L10n.string("inProgress.deleteMoment.button"), role: .destructive) {
                confirmMomentDeletion()
            }
            Button(L10n.string("common.cancel"), role: .cancel) {
                cancelMomentDeletion()
            }
        } message: {
            Text(presentation.deletionMessage)
        }
        .sheet(item: $momentPendingRename) { moment in
            MomentsInProgressRenameSheet(moment: moment) { title in
                viewModel.renameMoment(moment, title: title)
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

    private func confirmMomentDeletion() {
        if let momentPendingDeletion {
            if createViewModel.activeMomentId == momentPendingDeletion.id {
                createViewModel.clearSessionState()
            }
            viewModel.deleteMoment(momentPendingDeletion)
        }
        momentPendingDeletion = nil
    }

    private func cancelMomentDeletion() {
        momentPendingDeletion = nil
    }

    private func localMediaForMoment(_ moment: InProgressMoment) -> [MomentsSelectedMedia] {
        if createViewModel.activeMomentId == moment.id {
            return createViewModel.selectedMedia
        }

        guard !createViewModel.selectedMedia.isEmpty,
              viewModel.momentsSummary.latestInProgressMoment?.id == moment.id,
              viewModel.momentsSummary.inProgressCount == 1 else {
            return []
        }

        return createViewModel.selectedMedia
    }
}

private struct MomentsInProgressRenameSheet: View {
    let moment: InProgressMoment
    let save: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title: String

    init(moment: InProgressMoment, save: @escaping (String) -> Void) {
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
