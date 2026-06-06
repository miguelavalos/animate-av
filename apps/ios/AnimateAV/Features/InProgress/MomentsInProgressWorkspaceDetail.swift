import SwiftUI

struct MomentsInProgressWorkspaceDetail: View {
    let workspace: MomentWorkspace
    let isDeletingMoment: Bool
    let continueMoment: (MomentsContinuationRequest) -> Void
    let requestDeleteMoment: (InProgressMoment) -> Void
    private var presentation: MomentsInProgressWorkspaceDetailPresentation {
        MomentsInProgressWorkspaceDetailPresentation(workspace: workspace)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(presentation.title)
                .font(.headline)

            MomentsInProgressWorkspaceHeader(workspace: workspace)
            MomentsInProgressNextActionRow(action: presentation.nextAction)
            MomentsInProgressWorkspaceSummary(workspace: workspace)
            MomentsInProgressProgressSection(workspace: workspace)

            MomentsInProgressFinalExportSection(artifacts: workspace.artifacts)

            MomentsInProgressMediaSection(mediaAssets: workspace.mediaAssets)
            MomentsInProgressStorySection(storyScenes: workspace.storyScenes)
            MomentsInProgressRenderJobsSection(renderJobs: workspace.renderJobs)
            MomentsInProgressContinueButton(action: presentation.nextAction) {
                continueMoment(presentation.continuationRequest)
            }
            if workspace.activeFinalRenderJob == nil {
                MomentsInProgressDeleteButton(isDeletingMoment: isDeletingMoment) {
                    requestDeleteMoment(workspace.moment)
                }
            }
        }
    }
}

struct MomentsInProgressLoadingDetail: View {
    var body: some View {
        HStack(spacing: 10) {
            ProgressView()
            Text(L10n.string("inProgress.loadingDetail"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
