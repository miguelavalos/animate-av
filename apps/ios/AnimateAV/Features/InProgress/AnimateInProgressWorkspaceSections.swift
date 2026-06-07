import AVAppShellFoundation
import SwiftUI

struct AnimateInProgressMediaSection: View {
    let mediaAssets: [MomentMediaAsset]

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
                MomentsSharedSyncedMediaGrid(mediaAssets: mediaAssets)
            }
        }
    }
}

struct AnimateInProgressStorySection: View {
    let storyScenes: [MomentStoryScene]

    private var presentation: AnimateInProgressStorySectionPresentation {
        AnimateInProgressStorySectionPresentation(storyScenes: storyScenes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AVAppShellSectionHeader(title: presentation.title)

            if presentation.storyScenes.isEmpty {
                AnimateInProgressEmptySectionRow(
                    systemImage: presentation.emptySystemImage,
                    message: presentation.emptyMessage
                )
            } else {
                ForEach(presentation.storyScenes) { storyScene in
                    AnimateInProgressStorySceneRow(presentation: storyScene)
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

struct AnimateInProgressStorySceneRow: View {
    let presentation: AnimateInProgressStoryScenePresentation

    var body: some View {
        AVAppShellInfoRow(
            title: presentation.caption,
            detail: presentation.title,
            systemImage: "rectangle.stack.fill"
        )
    }
}
