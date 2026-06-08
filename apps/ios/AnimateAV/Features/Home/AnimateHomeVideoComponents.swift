import AVAppShellFoundation
import SwiftUI

struct AnimateHomeLatestVideoRow: View {
    let title: String
    let detail: String
    let openVideo: () -> Void

    var body: some View {
        AVAppShellActionRow(
            title: title,
            detail: detail,
            systemImage: "clock.badge.checkmark",
            eyebrow: L10n.string("home.latestVideo.eyebrow"),
            accessibilityIdentifier: "animate.home.latestVideo",
            action: openVideo
        )
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
