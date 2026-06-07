import AVAppShellFoundation
import SwiftUI

struct AnimateInProgressListGroup: View {
    let group: AnimateInProgressListGroupPresentation
    let selectMoment: (AnimateVideo) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AVAppShellSectionHeader(title: group.title) {
                Text("\(group.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ForEach(group.rows) { row in
                AnimateInProgressListRow(row: row) {
                    selectMoment(row.moment)
                }
            }
        }
    }
}
