import SwiftUI

struct MomentsInProgressList: View {
    let momentsSummary: InProgressMomentsSummary
    let selectedMomentId: String?
    let selectMoment: (InProgressMoment) -> Void
    private var presentation: MomentsInProgressListPresentation {
        MomentsInProgressListPresentation.make(
            momentsSummary: momentsSummary,
            selectedMomentId: selectedMomentId
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MomentsInProgressListSummaryRow(pills: presentation.summaryPills)

            ForEach(presentation.groups) { group in
                MomentsInProgressListGroup(
                    group: group,
                    selectMoment: selectMoment
                )
            }
        }
    }
}
