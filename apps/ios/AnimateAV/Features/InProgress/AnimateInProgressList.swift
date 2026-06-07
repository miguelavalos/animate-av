import SwiftUI

struct AnimateInProgressList: View {
    let videosSummary: AnimateInProgressSummary
    let selectedVideoId: String?
    let selectMoment: (AnimateVideo) -> Void
    private var presentation: AnimateInProgressListPresentation {
        AnimateInProgressListPresentation.make(
            videosSummary: videosSummary,
            selectedVideoId: selectedVideoId
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
