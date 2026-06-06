import AVAppShellFoundation
import SwiftUI

struct MomentsInProgressProgressSection: View {
    let workspace: MomentWorkspace

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AVAppShellSectionHeader(title: L10n.string("moment.progress.title"))

            VStack(alignment: .leading, spacing: 10) {
                ForEach(MomentsInProgressProgressModel(workspace: workspace).phases) { phase in
                    MomentsInProgressProgressRow(phase: phase)
                }
            }
        }
    }
}

private struct MomentsInProgressProgressRow: View {
    let phase: MomentsInProgressProgressPhase

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

private extension MomentsInProgressProgressState {
    var tint: Color {
        switch self {
        case .complete: MomentsTheme.highlight
        case .active: .secondary
        case .waiting: .secondary.opacity(0.7)
        case .failed: .red
        }
    }
}
