import AVAppShellFoundation
import SwiftUI

struct AnimateInProgressUnavailableState: View {
    let presentation: AnimateInProgressUnavailablePresentation

    var body: some View {
        AVAppShellInlineMessage(
            title: presentation.title,
            message: presentation.message,
            systemImage: presentation.systemImage,
            imageSize: 28,
            verticalPadding: 6,
            usesAccentIcon: true
        )
    }
}

struct AnimateInProgressEmptyState: View {
    let presentation: AnimateInProgressUnavailablePresentation
    let startMoment: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AnimateInProgressUnavailableState(presentation: presentation)

            AVAppShellActionRow(
                title: L10n.string("inProgress.empty.create.title"),
                detail: L10n.string("inProgress.empty.create.detail"),
                systemImage: "plus.app.fill",
                isProminent: true,
                accessibilityIdentifier: "animate.inProgress.empty.create",
                action: startMoment
            )

            AVAppShellInlineMessage(
                title: L10n.string("inProgress.empty.whatAppears.title"),
                message: L10n.string("inProgress.empty.whatAppears.message"),
                systemImage: "checkmark.circle",
                usesAccentIcon: true
            )
        }
    }
}

struct AnimateInProgressStatusMessage: View {
    let message: String?

    var body: some View {
        if let message {
            AVAppShellInlineMessage(message: message)
                .padding(.top, 2)
        }
    }
}
