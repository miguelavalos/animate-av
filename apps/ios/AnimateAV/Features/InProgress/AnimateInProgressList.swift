import SwiftUI

struct AnimateInProgressList: View {
    let momentsSummary: InProgressMomentsSummary
    let selectedMomentId: String?
    let selectMoment: (InProgressMoment) -> Void
    private var presentation: AnimateInProgressListPresentation {
        AnimateInProgressListPresentation.make(
            momentsSummary: momentsSummary,
            selectedMomentId: selectedMomentId
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            AnimateInProgressListSummaryRow(pills: presentation.summaryPills)

            ForEach(presentation.groups) { group in
                AnimateInProgressListGroup(
                    group: group,
                    selectMoment: selectMoment
                )
            }
        }
    }
}
