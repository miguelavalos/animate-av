import AVAppShellFoundation
import SwiftUI

struct AnimateHomeLatestVideoRow: View {
    let title: String
    let detail: String
    let openVideo: (() -> Void)?

    var body: some View {
        if let openVideo {
            AVAppShellActionRow(
                title: title,
                detail: detail,
                systemImage: "clock.badge.checkmark",
                eyebrow: L10n.string("home.latestVideo.eyebrow"),
                accessibilityIdentifier: "animate.home.latestVideo",
                action: openVideo
            )
        } else {
            AVAppShellInfoRow(
                title: title,
                detail: detail,
                systemImage: "clock.badge.checkmark",
                accessibilityIdentifier: "animate.home.latestVideo.status"
            )
        }
    }
}

struct AnimateHomeEmptyVideoRow: View {
    var body: some View {
        AVAppShellInfoRow(
            title: L10n.string("home.videos.emptyRow.title"),
            detail: L10n.string("home.videos.emptyRow.detail"),
            systemImage: "rectangle.stack.badge.plus",
            accessibilityIdentifier: "animate.home.videos.empty"
        )
    }
}
