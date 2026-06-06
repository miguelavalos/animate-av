import AVAviFoundation
import SwiftUI

struct MomentsAviPreparationCard: View {
    let openCreate: () -> Void

    var body: some View {
        AVAviGuidanceCard(
            title: L10n.string("avi.prepare.title"),
            detail: L10n.string("avi.prepare.detail")
        ) {
            AVAviInfoRow(
                title: L10n.string("avi.prepare.occasion.title"),
                detail: L10n.string("avi.prepare.occasion.detail"),
                systemImage: "sparkles"
            )
            AVAviInfoRow(
                title: L10n.string("avi.prepare.media.title"),
                detail: L10n.string("avi.prepare.media.detail"),
                systemImage: "photo.on.rectangle"
            )
            AVAviInfoRow(
                title: L10n.string("avi.prepare.story.title"),
                detail: L10n.string("avi.prepare.story.detail"),
                systemImage: "text.bubble"
            )
            AVAviActionInfoRow(
                title: L10n.string("avi.prepare.action.title"),
                detail: L10n.string("avi.prepare.action.detail"),
                systemImage: "plus.app",
                buttonTitle: L10n.string("avi.prepare.action.button"),
                action: openCreate
            )
        }
    }
}
