import AVAviFoundation
import SwiftUI

struct AnimateAviPreparationCard: View {
    let openCreate: () -> Void

    var body: some View {
        AVAviGuidanceCard(
            title: L10n.string("avi.prepare.title"),
            detail: L10n.string("avi.prepare.detail")
        ) {
            AVAviInfoRow(
                title: L10n.string("avi.prepare.media.title"),
                detail: L10n.string("avi.prepare.media.detail"),
                systemImage: "photo.on.rectangle"
            )
            AVAviInfoRow(
                title: L10n.string("avi.prepare.look.title"),
                detail: L10n.string("avi.prepare.look.detail"),
                systemImage: "paintbrush"
            )
            AVAviInfoRow(
                title: L10n.string("avi.prepare.voice.title"),
                detail: L10n.string("avi.prepare.voice.detail"),
                systemImage: "waveform"
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
