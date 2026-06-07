import AVAppShellFoundation
import SwiftUI

struct AnimateInProgressProgressSection: View {
    let workspace: MomentWorkspace

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AVAppShellSectionHeader(title: L10n.string("moment.progress.title"))

            VStack(alignment: .leading, spacing: 10) {
                ForEach(AnimateInProgressProgressModel(workspace: workspace).phases) { phase in
                    AnimateInProgressProgressRow(phase: phase)
                }
            }
        }
    }
}

private struct AnimateInProgressProgressRow: View {
    let phase: AnimateInProgressProgressPhase

    var body: some View {
        AVAppShellProgressRow(
            title: phase.title,
            detail: phase.detail,
            systemImage: phase.systemImage,
            stateSystemImage: phase.state.systemImage,
            stateTint: phase.state.tint
        )
    }
}

private extension AnimateInProgressProgressState {
    var tint: Color {
        switch self {
        case .complete: AnimateTheme.highlight
        case .active: .secondary
        case .waiting: .secondary.opacity(0.7)
        case .failed: .red
        }
    }
}
