import AVAppShellFoundation
import SwiftUI

struct AnimateInProgressWorkspaceSummary: View {
    let workspace: AnimateWorkspace
    private var presentation: AnimateInProgressWorkspaceSummaryPresentation {
        AnimateInProgressWorkspaceSummaryPresentation(workspace: workspace)
    }

    var body: some View {
        AVAppShellMetricStrip(metrics: presentation.metrics, minTileHeight: 72)
    }
}
