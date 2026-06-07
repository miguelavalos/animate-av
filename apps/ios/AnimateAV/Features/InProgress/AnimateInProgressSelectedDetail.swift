import SwiftUI

struct AnimateInProgressSelectedDetail: View {
    let selectedVideoId: String?
    let isLoadingAnimateWorkspace: Bool
    let activeWorkspace: AnimateWorkspace?
    let isDeletingVideo: Bool
    let continueVideo: (AnimateContinuationRequest) -> Void
    let requestDeleteMoment: (AnimateVideo) -> Void

    var body: some View {
        if isLoadingAnimateWorkspace {
            Divider()
                .padding(.vertical, 8)
            AnimateInProgressLoadingDetail()
        } else if let activeWorkspace, selectedVideoId == activeWorkspace.video.id {
            Divider()
                .padding(.vertical, 8)
            AnimateInProgressWorkspaceDetail(
                workspace: activeWorkspace,
                isDeletingVideo: isDeletingVideo,
                continueVideo: continueVideo,
                requestDeleteMoment: requestDeleteMoment
            )
        }
    }
}
