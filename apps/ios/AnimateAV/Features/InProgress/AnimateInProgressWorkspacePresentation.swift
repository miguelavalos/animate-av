import Foundation

struct AnimateInProgressWorkspaceDetailPresentation: Equatable {
    let title = L10n.string("moment.workspace.detailTitle")
    let nextAction: AnimateNextAction
    let continuationRequest: AnimateContinuationRequest

    init(workspace: AnimateWorkspace) {
        nextAction = AnimateStatusRules.nextAction(for: workspace)
        continuationRequest = AnimateContinuationRequest(
            moment: workspace.moment,
            focus: nextAction.continuationFocus
        )
    }
}
