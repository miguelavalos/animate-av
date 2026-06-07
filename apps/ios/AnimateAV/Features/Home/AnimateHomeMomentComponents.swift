import AVAppShellFoundation
import SwiftUI

struct AnimateHomeLatestMomentRow: View {
    let title: String
    let detail: String
    let openMoment: () -> Void

    var body: some View {
        AVAppShellActionRow(
            title: title,
            detail: detail,
            systemImage: "clock.badge.checkmark",
            eyebrow: L10n.string("home.latestMoment.eyebrow"),
            accessibilityIdentifier: "animate.home.latestMoment",
            action: openMoment
        )
    }
}

struct AnimateHomeEmptyMomentRow: View {
    var body: some View {
        AVAppShellInfoRow(
            title: L10n.string("home.moments.emptyRow.title"),
            detail: L10n.string("home.moments.emptyRow.detail"),
            systemImage: "rectangle.stack.badge.plus",
            accessibilityIdentifier: "animate.home.moments.empty"
        )
    }
}
