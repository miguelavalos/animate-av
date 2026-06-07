import SwiftUI

struct AnimateInProgressSelectedDetail: View {
    let selectedMomentId: String?
    let isLoadingAnimateWorkspace: Bool
    let activeWorkspace: AnimateWorkspace?
    let isDeletingMoment: Bool
    let continueMoment: (AnimateContinuationRequest) -> Void
    let requestDeleteMoment: (AnimateVideo) -> Void

    var body: some View {
        if isLoadingAnimateWorkspace {
            Divider()
                .padding(.vertical, 8)
            AnimateInProgressLoadingDetail()
        } else if let activeWorkspace, selectedMomentId == activeWorkspace.moment.id {
            Divider()
                .padding(.vertical, 8)
            AnimateInProgressWorkspaceDetail(
                workspace: activeWorkspace,
                isDeletingMoment: isDeletingMoment,
                continueMoment: continueMoment,
                requestDeleteMoment: requestDeleteMoment
            )
        }
    }
}
