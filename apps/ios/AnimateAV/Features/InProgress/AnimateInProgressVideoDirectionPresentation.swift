import Foundation

struct AnimateInProgressVideoDirectionSectionPresentation: Equatable {
    let title = L10n.string("moment.story.title")
    let emptySystemImage = "text.bubble"
    let emptyMessage = L10n.string("moment.story.empty")
    let videoDirectionScenes: [AnimateInProgressVideoDirectionScenePresentation]

    init(storyScenes: [AnimateVideoDirectionScene]) {
        self.videoDirectionScenes = AnimateInProgressVideoDirectionScenePresentation.sorted(storyScenes)
    }
}

struct AnimateInProgressVideoDirectionScenePresentation: Identifiable, Equatable {
    let id: String
    let title: String
    let caption: String

    init(scene: AnimateVideoDirectionScene) {
        id = scene.id
        title = L10n.string("moment.story.scene", Int(scene.sceneIndex) + 1)
        caption = scene.caption
    }

    static func sorted(_ scenes: [AnimateVideoDirectionScene]) -> [AnimateInProgressVideoDirectionScenePresentation] {
        scenes
            .sorted { $0.sceneIndex < $1.sceneIndex }
            .map(AnimateInProgressVideoDirectionScenePresentation.init)
    }
}
