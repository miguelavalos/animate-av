import SwiftUI

struct AnimateInProgressListSummaryRow: View {
    let pills: [AnimateInProgressSummaryPresentation]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(pills) { pill in
                AnimateInProgressListSummaryPill(pill: pill)
            }
        }
    }
}

