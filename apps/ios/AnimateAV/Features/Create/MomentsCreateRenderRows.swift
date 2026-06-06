import AVAppShellFoundation
import SwiftUI

struct MomentsCreateRenderJobStatusRow: View {
    let renderJob: MomentRenderJob

    var body: some View {
        AVAppShellInfoRow(
            title: MomentStatusRules.displayTitle(for: renderJob.status),
            detail: detail,
            systemImage: systemImage,
            eyebrow: L10n.string("create.renderRows.renderJob")
        )
    }

    private var detail: String {
        if renderJob.status == "failed" {
            return MomentsRecoveryCopy.failedRenderDetail(
                userMessage: renderJob.userMessage,
                errorMessage: renderJob.errorMessage
            )
        }
        if let userMessage = renderJob.userMessage, !userMessage.isEmpty {
            return userMessage
        }

        return renderJob.model ?? L10n.string("create.renderRows.waitingStatus")
    }

    private var systemImage: String {
        switch renderJob.status {
        case "completed":
            return "checkmark.circle.fill"
        case "failed":
            return "exclamationmark.triangle.fill"
        case "running", "processing":
            return "gearshape.2.fill"
        default:
            return "clock.fill"
        }
    }
}

struct MomentsCreateArtifactStatusCard: View {
    let title: String
    let systemImage: String
    let artifact: MomentArtifact
    let detail: String?

    var body: some View {
        AVAppShellMetadataCard {
            Label(title, systemImage: systemImage)
                .font(.caption.weight(.semibold))

            if let detail, !detail.isEmpty {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                alignment: .leading,
                spacing: 8
            ) {
                AVAppShellMetadataItem(
                    title: L10n.string("create.renderRows.watermark"),
                    value: artifact.hasWatermark == true ? L10n.string("create.renderRows.included") : L10n.string("create.renderRows.none")
                )
                AVAppShellMetadataItem(
                    title: L10n.string("create.renderRows.expires"),
                    value: MomentsDateFormatting.formattedDate(milliseconds: artifact.expiresAt)
                )
            }

            AVAppShellIdentifierRow(
                title: L10n.string("create.renderRows.storageKey"),
                value: artifact.r2Key,
                lineLimit: 3
            )
        }
    }
}
