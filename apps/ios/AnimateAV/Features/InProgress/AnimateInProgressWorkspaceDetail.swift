import SwiftUI

struct AnimateInProgressWorkspaceDetail: View {
    let workspace: MomentWorkspace
    let isDeletingMoment: Bool
    let continueMoment: (MomentsContinuationRequest) -> Void
    let requestDeleteMoment: (InProgressMoment) -> Void
    private var presentation: AnimateInProgressWorkspaceDetailPresentation {
        AnimateInProgressWorkspaceDetailPresentation(workspace: workspace)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(presentation.title)
                .font(.headline)

            AnimateInProgressWorkspaceHeader(workspace: workspace)
            AnimateInProgressNextActionRow(action: presentation.nextAction)
            AnimateInProgressWorkspaceSummary(workspace: workspace)
            AnimateInProgressProgressSection(workspace: workspace)

            AnimateInProgressFinalExportSection(artifacts: workspace.artifacts)

            AnimateInProgressMediaSection(mediaAssets: workspace.mediaAssets)
            AnimateInProgressStorySection(storyScenes: workspace.storyScenes)
            AnimateInProgressRenderJobsSection(renderJobs: workspace.renderJobs)
            AnimateInProgressContinueButton(action: presentation.nextAction) {
                continueMoment(presentation.continuationRequest)
            }
            if workspace.activeFinalRenderJob == nil {
                AnimateInProgressDeleteButton(isDeletingMoment: isDeletingMoment) {
                    requestDeleteMoment(workspace.moment)
                }
            }
        }
    }
}

struct AnimateInProgressLoadingDetail: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text(L10n.string("inProgress.loadingDetail"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
