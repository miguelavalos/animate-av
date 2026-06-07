import SwiftUI

struct AnimateInProgressStatusMarker: View {
    let row: AnimateInProgressListRowPresentation

    var body: some View {
        Image(systemName: row.statusSystemImage)
            .font(.subheadline)
            .foregroundStyle(row.isFinished ? AnimateTheme.highlight : .secondary)
            .frame(width: 20)
    }
}

struct AnimateInProgressListMetadata: View {
    let metadata: AnimateInProgressListMetadataPresentation

    var body: some View {
        Label(metadata.text, systemImage: metadata.systemImage)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
    }
}
