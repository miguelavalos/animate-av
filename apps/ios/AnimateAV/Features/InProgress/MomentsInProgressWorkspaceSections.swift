import AVAppShellFoundation
import SwiftUI

struct MomentsInProgressMediaSection: View {
    let mediaAssets: [MomentMediaAsset]

    private var presentation: MomentsInProgressMediaSectionPresentation {
        MomentsInProgressMediaSectionPresentation(mediaAssets: mediaAssets)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AVAppShellSectionHeader(title: presentation.title)

            if presentation.mediaAssets.isEmpty {
                MomentsInProgressEmptySectionRow(
                    systemImage: presentation.emptySystemImage,
                    message: presentation.emptyMessage
                )
            } else {
                MomentsSharedSyncedMediaGrid(mediaAssets: mediaAssets)
            }
        }
    }
}

struct MomentsInProgressStorySection: View {
    let storyScenes: [MomentStoryScene]

    private var presentation: MomentsInProgressStorySectionPresentation {
        MomentsInProgressStorySectionPresentation(storyScenes: storyScenes)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            AVAppShellSectionHeader(title: presentation.title)

            if presentation.storyScenes.isEmpty {
                MomentsInProgressEmptySectionRow(
                    systemImage: presentation.emptySystemImage,
                    message: presentation.emptyMessage
                )
            } else {
                ForEach(presentation.storyScenes) { storyScene in
                    MomentsInProgressStorySceneRow(presentation: storyScene)
                }
            }
        }
    }
}

struct MomentsInProgressEmptySectionRow: View {
    let systemImage: String
    let message: String

    var body: some View {
        AVAppShellInlineMessage(message: message, systemImage: systemImage)
    }
}

struct MomentsInProgressMediaAssetRow: View {
    let presentation: MomentsInProgressMediaAssetPresentation

    var body: some View {
        AVAppShellInfoRow(
            title: presentation.title,
            detail: presentation.detail,
            systemImage: presentation.systemImage
        )
    }
}

struct MomentsInProgressStorySceneRow: View {
    let presentation: MomentsInProgressStoryScenePresentation

    var body: some View {
        AVAppShellInfoRow(
            title: presentation.caption,
            detail: presentation.title,
            systemImage: "rectangle.stack.fill"
        )
    }
}
