import AVAppShellFoundation
import SwiftUI

struct AnimateInProgressWorkspaceHeader: View {
    let workspace: AnimateWorkspace
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
    let action: AnimateNextAction

    var body: some View {
        AVAppShellInfoRow(
            title: action.title,
            detail: action.message,
            systemImage: action.systemImage
        )
    }
}

struct AnimateInProgressContinueButton: View {
    let action: AnimateNextAction
    let continueVideo: () -> Void

    var body: some View {
        AVAppShellPrimaryButton(
            action.primaryButtonTitle,
            systemImage: "arrow.right.circle",
            action: continueVideo
        )
    }
}

struct AnimateInProgressDeleteButton: View {
    let isDeletingVideo: Bool
    let requestDeleteVideo: () -> Void

    var body: some View {
        Button(role: .destructive) {
            requestDeleteVideo()
        } label: {
            Label(isDeletingVideo ? L10n.string("inProgress.deleteVideo.deleting") : L10n.string("inProgress.deleteVideo.shortButton"), systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(isDeletingVideo)
    }
}
