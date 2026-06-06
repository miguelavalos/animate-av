import AVAppShellFoundation
import SwiftUI

struct MomentsCreateWorkspaceProgress: View {
    let summary: MomentsCreateWorkspaceSummary
    let minimumMediaCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AVAppShellSectionHeader(title: L10n.string("create.progress.title"))
            AVAppShellProgressRow(
                title: L10n.string("create.progress.media"),
                detail: summary.mediaDetail,
                systemImage: "photo.on.rectangle",
                isComplete: summary.mediaCount >= minimumMediaCount,
            )
            AVAppShellProgressRow(
                title: L10n.string("moment.progress.story"),
                detail: summary.storyDetail,
                systemImage: "text.bubble",
                isComplete: summary.sceneCount > 0,
            )
            AVAppShellProgressRow(
                title: L10n.string("moment.artifact.final.title"),
                detail: summary.hasFinalExport ? L10n.string("create.status.ready") : L10n.string("create.progress.finalNotMade"),
                systemImage: "square.and.arrow.up",
                isComplete: summary.hasFinalExport,
            )
        }
    }
}
