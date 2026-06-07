import AVAppShellFoundation
import SwiftUI

struct AnimateCreateStorySceneRow: View {
    let index: Int
    let caption: String
    let narration: String

    var body: some View {
        AVAppShellInfoRow(
            title: caption,
            detail: narration,
            systemImage: "rectangle.stack.fill",
            eyebrow: L10n.string("create.story.scene", index + 1)
        )
    }
}
