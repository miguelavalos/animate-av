import AVAppShellFoundation
import Foundation

struct AnimateInProgressWorkspaceSummaryPresentation: Equatable {
    let tiles: [AnimateInProgressSummaryTilePresentation]

    var metrics: [AVAppShellMetric] {
        tiles.map {
            AVAppShellMetric(
                id: $0.id,
                title: $0.title,
                value: $0.value,
                systemImage: $0.systemImage
            )
        }
    }

    init(workspace: MomentWorkspace) {
        let finalExport = workspace.latestArtifact(kind: "final_export")
        let latestRenderJob = workspace.latestRenderJob()

        tiles = [
            AnimateInProgressSummaryTilePresentation(
                title: L10n.string("moment.summary.status"),
                value: MomentStatusRules.displayTitle(for: workspace.moment.status),
                systemImage: "circle.dashed"
            ),
            AnimateInProgressSummaryTilePresentation(
                title: L10n.string("moment.summary.final"),
                value: Self.summaryValue(for: finalExport),
                systemImage: "video.fill"
            ),
            AnimateInProgressSummaryTilePresentation(
                title: L10n.string("moment.summary.latestJob"),
                value: Self.latestJobValue(latestRenderJob),
                systemImage: "gearshape.2"
            )
        ]
    }

    private static func latestJobValue(_ latestRenderJob: MomentRenderJob?) -> String {
        guard let latestRenderJob else { return L10n.string("moment.progress.notStarted") }
        return "\(MomentStatusRules.displayKind(latestRenderJob.kind)) · \(MomentStatusRules.displayTitle(for: latestRenderJob.status))"
    }

    private static func summaryValue(for artifact: MomentArtifact?) -> String {
        guard let artifact else { return L10n.string("moment.progress.notReady") }
        return MomentStatusRules.displayTitle(for: artifact.status)
    }
}

struct AnimateInProgressSummaryTilePresentation: Identifiable, Equatable {
    let title: String
    let value: String
    let systemImage: String

    var id: String { title }
}
