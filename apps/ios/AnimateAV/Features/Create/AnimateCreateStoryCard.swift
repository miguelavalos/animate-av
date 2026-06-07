import AVAppShellFoundation
import AVBrandFoundation
import SwiftUI

struct AnimateCreateStoryCard: View {
    let presentation: AnimateCreateStoryPresentation
    let generateStory: () -> Void

    var body: some View {
        AVAppShellCard {
            VStack(alignment: .leading, spacing: 14) {
                AVAppShellContentHeader(
                    title: L10n.string("create.story.plan.title"),
                    detail: L10n.string("create.story.plan.detail")
                )

                AnimateCreateStoryScenesSection(presentation: presentation)

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

private struct AnimateCreateStoryScenesSection: View {
    let presentation: AnimateCreateStoryPresentation

    var body: some View {
        if !presentation.savedScenes.isEmpty {
            ForEach(presentation.savedScenes) { scene in
                AnimateCreateStorySceneRow(
                    index: Int(scene.sceneIndex),
                    caption: scene.caption,
                    narration: scene.narrationText ?? ""
                )
            }
        } else if !presentation.summary.generatedScenes.isEmpty {
            ForEach(presentation.summary.generatedScenes) { scene in
                AnimateCreateStorySceneRow(
                    index: scene.sceneIndex,
                    caption: scene.caption,
                    narration: scene.narrationText
                )
            }
        } else {
            AnimateCreateEmptySectionRow(
                systemImage: "text.bubble",
                message: presentation.emptyMessage
            )
        }
    }
}
