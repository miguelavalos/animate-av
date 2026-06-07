import SwiftUI

struct MomentsInProgressListSummaryPill: View {
    let pill: InProgressMomentsSummaryPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Image(systemName: pill.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AnimateTheme.highlight)
            Text("\(pill.value)")
                .font(.subheadline.weight(.semibold))
            Text(pill.title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
        }
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .topLeading)
        .padding(10)
        .background(AnimateTheme.highlight.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

