import AVAppShellFoundation
import SwiftUI

struct AnimateInProgressArtifactDetail: View {
    let presentation: AnimateInProgressArtifactPresentation

    var body: some View {
        AVAppShellMetadataCard {
            HStack(alignment: .center, spacing: 8) {
                AnimateInProgressDiagnosticStatusBadge(status: presentation.status)

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
                    title: L10n.string("video.artifact.watermark"),
                    value: presentation.watermarkTitle
                )
                AVAppShellMetadataItem(
                    title: L10n.string("video.artifact.expires"),
                    value: presentation.expiresAtTitle
                )
            }

            AVAppShellIdentifierRow(
                title: L10n.string("video.artifact.storageKey"),
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

struct AnimateInProgressRenderJobRow: View {
    let presentation: AnimateInProgressRenderJobPresentation

    var body: some View {
        AVAppShellMetadataCard {
            HStack(alignment: .center, spacing: 8) {
                AnimateInProgressDiagnosticStatusBadge(status: presentation.status)

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
                    title: L10n.string("video.job.videoService"),
                    value: presentation.providerTitle
                )
                AVAppShellMetadataItem(
                    title: L10n.string("video.job.videoProfile"),
                    value: presentation.modelTitle
                )
                AVAppShellMetadataItem(
                    title: L10n.string("video.job.created"),
                    value: presentation.createdAtTitle
                )
                AVAppShellMetadataItem(
                    title: L10n.string("video.job.updated"),
                    value: presentation.updatedAtTitle
                )
            }

            AnimateInProgressRenderJobErrorBlock(
                errorCode: presentation.errorCode,
                errorMessage: presentation.errorMessage
            )

            VStack(alignment: .leading, spacing: 6) {
                AVAppShellIdentifierRow(title: L10n.string("video.job.id"), value: presentation.id)
                AVAppShellIdentifierRow(title: L10n.string("video.job.workflow"), value: presentation.workflowRunId)
                AVAppShellIdentifierRow(title: L10n.string("video.job.supportReference"), value: presentation.providerRequestId)
            }
        }
    }
}

private struct AnimateInProgressRenderJobErrorBlock: View {
    let errorCode: String?
    let errorMessage: String?

    var body: some View {
        if let errorMessage, !errorMessage.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                Text(errorCode ?? L10n.string("video.job.videoError"))
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
