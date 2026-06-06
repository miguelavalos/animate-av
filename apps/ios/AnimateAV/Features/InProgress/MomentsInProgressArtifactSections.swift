import AVAppShellFoundation
import SwiftUI

struct MomentsInProgressRenderJobsSection: View {
    let renderJobs: [MomentRenderJob]

    private var presentation: MomentsInProgressRenderJobsSectionPresentation {
        MomentsInProgressRenderJobsSectionPresentation(renderJobs: renderJobs)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AVAppShellSectionHeader(title: presentation.title)

            if presentation.jobs.isEmpty {
                MomentsInProgressEmptySectionRow(
                    systemImage: presentation.emptySystemImage,
                    message: presentation.emptyMessage
                )
            } else {
                ForEach(presentation.jobs) { job in
                    MomentsInProgressRenderJobRow(presentation: job)
                }
            }
        }
    }
}

struct MomentsInProgressFinalExportSection: View {
    let artifacts: [MomentArtifact]

    private var presentation: MomentsInProgressArtifactSectionPresentation {
        MomentsInProgressArtifactSectionPresentation.finalExport(artifacts: artifacts)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AVAppShellSectionHeader(title: presentation.title)

            if let artifact = presentation.artifact {
                MomentsInProgressArtifactDetail(presentation: artifact)
            } else {
                MomentsInProgressEmptySectionRow(
                    systemImage: presentation.emptySystemImage,
                    message: presentation.emptyMessage
                )
            }
        }
    }
}
