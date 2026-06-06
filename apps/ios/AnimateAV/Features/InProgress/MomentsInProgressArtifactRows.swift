import AVAppShellFoundation
import SwiftUI

struct MomentsInProgressArtifactDetail: View {
    let presentation: MomentsInProgressArtifactPresentation

    var body: some View {
        AVAppShellMetadataCard {
            HStack(alignment: .center, spacing: 8) {
                MomentsInProgressDiagnosticStatusBadge(status: presentation.status)

                Text(presentation.kindTitle)
                    .font(.caption.weight(.semibold))

                Spacer(minLength: 0)
            }

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                alignment: .leading,
                spacing: 8
            ) {
                AVAppShellMetadataItem(
                    title: L10n.string("moment.artifact.watermark"),
                    value: presentation.watermarkTitle
                )
                AVAppShellMetadataItem(
                    title: L10n.string("moment.artifact.expires"),
                    value: presentation.expiresAtTitle
                )
            }

            AVAppShellIdentifierRow(
                title: L10n.string("moment.artifact.storageKey"),
                value: presentation.storageKey,
                lineLimit: 3
            )

            Text(presentation.actionDetail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct MomentsInProgressRenderJobRow: View {
    let presentation: MomentsInProgressRenderJobPresentation

    var body: some View {
        AVAppShellMetadataCard {
            HStack(alignment: .center, spacing: 8) {
                MomentsInProgressDiagnosticStatusBadge(status: presentation.status)

                Text(presentation.kindTitle)
                    .font(.caption.weight(.semibold))

                Spacer(minLength: 0)
            }

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                alignment: .leading,
                spacing: 8
            ) {
                AVAppShellMetadataItem(
                    title: L10n.string("moment.job.videoService"),
                    value: presentation.providerTitle
                )
                AVAppShellMetadataItem(
                    title: L10n.string("moment.job.videoProfile"),
                    value: presentation.modelTitle
                )
                AVAppShellMetadataItem(
                    title: L10n.string("moment.job.created"),
                    value: presentation.createdAtTitle
                )
                AVAppShellMetadataItem(
                    title: L10n.string("moment.job.updated"),
                    value: presentation.updatedAtTitle
                )
            }

            MomentsInProgressRenderJobErrorBlock(
                errorCode: presentation.errorCode,
                errorMessage: presentation.errorMessage
            )

            VStack(alignment: .leading, spacing: 6) {
                AVAppShellIdentifierRow(title: L10n.string("moment.job.id"), value: presentation.id)
                AVAppShellIdentifierRow(title: L10n.string("moment.job.workflow"), value: presentation.workflowRunId)
                AVAppShellIdentifierRow(title: L10n.string("moment.job.supportReference"), value: presentation.providerRequestId)
            }
        }
    }
}

private struct MomentsInProgressRenderJobErrorBlock: View {
    let errorCode: String?
    let errorMessage: String?

    var body: some View {
        if let errorMessage, !errorMessage.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                Text(errorCode ?? L10n.string("moment.job.videoError"))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.red)
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(8)
            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        }
    }
}
