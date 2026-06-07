import AVAppShellFoundation
import SwiftUI

struct AnimateInProgressRenderJobsSection: View {
    let renderJobs: [MomentRenderJob]

    private var presentation: AnimateInProgressRenderJobsSectionPresentation {
        AnimateInProgressRenderJobsSectionPresentation(renderJobs: renderJobs)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AVAppShellSectionHeader(title: presentation.title)

            if presentation.jobs.isEmpty {
                AnimateInProgressEmptySectionRow(
                    systemImage: presentation.emptySystemImage,
                    message: presentation.emptyMessage
                )
            } else {
                ForEach(presentation.jobs) { job in
                    AnimateInProgressRenderJobRow(presentation: job)
                }
            }
        }
    }
}

struct AnimateInProgressFinalExportSection: View {
    let artifacts: [MomentArtifact]

    private var presentation: AnimateInProgressArtifactSectionPresentation {
        AnimateInProgressArtifactSectionPresentation.finalExport(artifacts: artifacts)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AVAppShellSectionHeader(title: presentation.title)

            if let artifact = presentation.artifact {
                AnimateInProgressArtifactDetail(presentation: artifact)
            } else {
                AnimateInProgressEmptySectionRow(
                    systemImage: presentation.emptySystemImage,
                    message: presentation.emptyMessage
                )
            }
        }
    }
}
