import AVAppShellFoundation
import AVBrandFoundation
import SwiftUI

struct MomentsCreateStoryCard: View {
    let presentation: MomentsCreateStoryPresentation
    let generateStory: () -> Void

    var body: some View {
        AVAppShellCard {
            VStack(alignment: .leading, spacing: 14) {
                AVAppShellContentHeader(
                    title: L10n.string("create.story.plan.title"),
                    detail: L10n.string("create.story.plan.detail")
                )

                MomentsCreateStoryScenesSection(presentation: presentation)

                AVAppShellPrimaryButton(
                    presentation.planButtonTitle,
                    systemImage: "text.bubble.fill",
                    isDisabled: !presentation.canPlanStory || presentation.summary.isPlanning,
                    action: generateStory
                )

                if let availabilityMessage = presentation.availabilityMessage {
                    AVAppShellInlineMessage(message: availabilityMessage)
                }

                if let storyStatusMessage = presentation.summary.statusMessage {
                    Text(storyStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct MomentsCreateStoryScenesSection: View {
    let presentation: MomentsCreateStoryPresentation

    var body: some View {
        if !presentation.savedScenes.isEmpty {
            ForEach(presentation.savedScenes) { scene in
                MomentsCreateStorySceneRow(
                    index: Int(scene.sceneIndex),
                    caption: scene.caption,
                    narration: scene.narrationText ?? ""
                )
            }
        } else if !presentation.summary.generatedScenes.isEmpty {
            ForEach(presentation.summary.generatedScenes) { scene in
                MomentsCreateStorySceneRow(
                    index: scene.sceneIndex,
                    caption: scene.caption,
                    narration: scene.narrationText
                )
            }
        } else {
            MomentsCreateEmptySectionRow(
                systemImage: "text.bubble",
                message: presentation.emptyMessage
            )
        }
    }
}
