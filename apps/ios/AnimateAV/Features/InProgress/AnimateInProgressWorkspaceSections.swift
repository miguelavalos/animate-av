import AVAppShellFoundation
import SwiftUI

struct AnimateInProgressMediaSection: View {
    let mediaAssets: [AnimateMediaAsset]

    private var presentation: AnimateInProgressMediaSectionPresentation {
        AnimateInProgressMediaSectionPresentation(mediaAssets: mediaAssets)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AVAppShellSectionHeader(title: presentation.title)

            if presentation.mediaAssets.isEmpty {
                AnimateInProgressEmptySectionRow(
                    systemImage: presentation.emptySystemImage,
                    message: presentation.emptyMessage
                )
            } else {
                AnimateSharedSyncedMediaGrid(mediaAssets: mediaAssets)
            }
        }
    }
}

struct AnimateInProgressVideoDirectionSection: View {
    let storyScenes: [AnimateVideoDirectionScene]

    private var presentation: AnimateInProgressVideoDirectionSectionPresentation {
        AnimateInProgressVideoDirectionSectionPresentation(storyScenes: storyScenes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AVAppShellSectionHeader(title: presentation.title)

            if presentation.videoDirectionScenes.isEmpty {
                AnimateInProgressEmptySectionRow(
                    systemImage: presentation.emptySystemImage,
                    message: presentation.emptyMessage
                )
            } else {
                ForEach(presentation.videoDirectionScenes) { videoDirectionScene in
                    AnimateInProgressVideoDirectionSceneRow(presentation: videoDirectionScene)
                }
            }
        }
    }
}

struct AnimateInProgressEmptySectionRow: View {
    let systemImage: String
    let message: String

    var body: some View {
        AVAppShellInlineMessage(message: message, systemImage: systemImage)
    }
}

struct AnimateInProgressMediaAssetRow: View {
    let presentation: AnimateInProgressMediaAssetPresentation

    var body: some View {
        AVAppShellInfoRow(
            title: presentation.title,
            detail: presentation.detail,
            systemImage: presentation.systemImage
        )
    }
}

struct AnimateInProgressVideoDirectionSceneRow: View {
    let presentation: AnimateInProgressVideoDirectionScenePresentation

    var body: some View {
        AVAppShellInfoRow(
            title: presentation.caption,
            detail: presentation.title,
            systemImage: "rectangle.stack.fill"
        )
    }
}
