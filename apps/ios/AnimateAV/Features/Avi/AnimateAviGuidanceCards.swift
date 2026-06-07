import AVAviFoundation
import SwiftUI

struct AnimateAviHelpCard: View {
    var body: some View {
        AVAviGuidanceCard(
            title: L10n.string("avi.help.title"),
            detail: L10n.string("avi.help.detail")
        ) {
            AVAviInfoRow(
                title: L10n.string("avi.help.choose.title"),
                detail: L10n.string("avi.help.choose.detail"),
                systemImage: "photo.on.rectangle"
            )
            AVAviInfoRow(
                title: L10n.string("avi.help.story.title"),
                detail: L10n.string("avi.help.story.detail"),
                systemImage: "text.bubble"
            )
            AVAviInfoRow(
                title: L10n.string("avi.help.create.title"),
                detail: L10n.string("avi.help.create.detail"),
                systemImage: "video.fill"
            )
        }
    }
}

struct AnimateAviLibraryGuidanceCard: View {
    let openGallery: () -> Void

    var body: some View {
        AVAviGuidanceCard(
            title: L10n.string("library.inProgressAndGallery.title"),
            detail: L10n.string("avi.library.detail")
        ) {
            AVAviInfoRow(
                title: L10n.string("inProgress.title"),
                detail: L10n.string("avi.library.inProgress.detail"),
                systemImage: "clock"
            )
            AVAviInfoRow(
                title: L10n.string("gallery.title"),
                detail: L10n.string("avi.library.gallery.detail"),
                systemImage: "checkmark.circle"
            )
            AVAviActionButton(
                title: L10n.string("gallery.open"),
                systemImage: "play.square.stack",
                action: openGallery
            )
        }
    }
}
