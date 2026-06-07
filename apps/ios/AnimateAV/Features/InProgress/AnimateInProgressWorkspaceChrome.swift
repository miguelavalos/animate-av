import AVAppShellFoundation
import SwiftUI

struct AnimateInProgressWorkspaceHeader: View {
    let workspace: MomentWorkspace
    private var presentation: AnimateInProgressWorkspaceHeaderPresentation {
        AnimateInProgressWorkspaceHeaderPresentation(workspace: workspace)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(presentation.title)
                .font(.subheadline.weight(.semibold))
            Text(presentation.updatedAtTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(presentation.countsTitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct AnimateInProgressNextActionRow: View {
    let action: MomentNextAction

    var body: some View {
        AVAppShellInfoRow(
            title: action.title,
            detail: action.message,
            systemImage: action.systemImage
        )
    }
}

struct AnimateInProgressContinueButton: View {
    let action: MomentNextAction
    let continueMoment: () -> Void

    var body: some View {
        AVAppShellPrimaryButton(
            action.primaryButtonTitle,
            systemImage: "arrow.right.circle",
            action: continueMoment
        )
    }
}

struct AnimateInProgressDeleteButton: View {
    let isDeletingMoment: Bool
    let requestDeleteMoment: () -> Void

    var body: some View {
        Button(role: .destructive) {
            requestDeleteMoment()
        } label: {
            Label(isDeletingMoment ? L10n.string("inProgress.deleteMoment.deleting") : L10n.string("inProgress.deleteMoment.shortButton"), systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(isDeletingMoment)
    }
}
