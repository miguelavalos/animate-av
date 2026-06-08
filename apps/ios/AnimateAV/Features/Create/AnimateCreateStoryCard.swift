import AVAppShellFoundation
import AVBrandFoundation
import SwiftUI

struct AnimateCreateVideoDirectionPreparationCard: View {
    let presentation: AnimateCreateVideoDirectionPreparationPresentation
    let generateStory: () -> Void

    var body: some View {
        AVAppShellCard {
            VStack(alignment: .leading, spacing: 14) {
                AVAppShellContentHeader(
                    title: L10n.string("create.story.plan.title"),
                    detail: L10n.string("create.story.plan.detail")
                )

                AnimateCreateVideoDirectionScenesSection(presentation: presentation)

                AVAppShellPrimaryButton(
                    presentation.planButtonTitle,
                    systemImage: "text.bubble.fill",
                    isDisabled: !presentation.canPrepareVideoDirection || presentation.summary.isPlanning,
                    action: generateStory
                )

                if let availabilityMessage = presentation.availabilityMessage {
                    AVAppShellInlineMessage(message: availabilityMessage)
                }

                if let videoDirectionStatusMessage = presentation.summary.statusMessage {
                    Text(videoDirectionStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct AnimateCreateVideoDirectionScenesSection: View {
    let presentation: AnimateCreateVideoDirectionPreparationPresentation

    var body: some View {
        if !presentation.savedScenes.isEmpty {
            ForEach(presentation.savedScenes) { scene in
                AnimateCreateVideoDirectionSceneRow(
                    index: Int(scene.sceneIndex),
                    caption: scene.caption,
                    narration: scene.narrationText ?? ""
                )
            }
        } else if !presentation.summary.generatedScenes.isEmpty {
            ForEach(presentation.summary.generatedScenes) { scene in
                AnimateCreateVideoDirectionSceneRow(
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
