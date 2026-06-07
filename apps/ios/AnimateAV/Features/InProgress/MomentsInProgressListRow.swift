import SwiftUI

struct MomentsInProgressListRow: View {
    let row: MomentsInProgressListRowPresentation
    let selectMoment: () -> Void

    var body: some View {
        Button(action: selectMoment) {
            HStack(alignment: .top, spacing: 12) {
                MomentsInProgressStatusMarker(row: row)

                VStack(alignment: .leading, spacing: 8) {
                    Text(row.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        ForEach(row.metadata) { metadata in
                            MomentsInProgressListMetadata(metadata: metadata)
                        }
                    }

                    HStack(spacing: 8) {
                        Text(row.statusTitle)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(AnimateTheme.highlight)
                    }
                }

                Spacer()

                Image(systemName: row.accessorySystemImage)
                    .foregroundStyle(row.isSelected ? AnimateTheme.highlight : .secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
