import Foundation

struct MomentsInProgressWorkspaceDetailPresentation: Equatable {
    let title = L10n.string("moment.workspace.detailTitle")
    let nextAction: MomentNextAction
    let continuationRequest: MomentsContinuationRequest

    init(workspace: MomentWorkspace) {
        nextAction = MomentStatusRules.nextAction(for: workspace)
        continuationRequest = MomentsContinuationRequest(
            moment: workspace.moment,
            focus: nextAction.continuationFocus
        )
    }
}
