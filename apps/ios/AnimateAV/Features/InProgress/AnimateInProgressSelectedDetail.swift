import SwiftUI

struct AnimateInProgressSelectedDetail: View {
    let selectedMomentId: String?
    let isLoadingMomentWorkspace: Bool
    let activeWorkspace: MomentWorkspace?
    let isDeletingMoment: Bool
    let continueMoment: (MomentsContinuationRequest) -> Void
    let requestDeleteMoment: (InProgressMoment) -> Void

    var body: some View {
        if isLoadingMomentWorkspace {
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
