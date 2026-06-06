import AVAppShellFoundation
import SwiftUI

struct MomentsInProgressListGroup: View {
    let group: MomentsInProgressListGroupPresentation
    let selectMoment: (InProgressMoment) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AVAppShellSectionHeader(title: group.title) {
                Text("\(group.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ForEach(group.rows) { row in
                MomentsInProgressListRow(row: row) {
                    selectMoment(row.moment)
                }
            }
        }
    }
}
