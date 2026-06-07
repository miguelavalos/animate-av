import Foundation

struct AnimateInProgressStorySectionPresentation: Equatable {
    let title = L10n.string("moment.story.title")
    let emptySystemImage = "text.bubble"
    let emptyMessage = L10n.string("moment.story.empty")
    let storyScenes: [AnimateInProgressStoryScenePresentation]

    init(storyScenes: [AnimateStoryScene]) {
        self.storyScenes = AnimateInProgressStoryScenePresentation.sorted(storyScenes)
    }
}

struct AnimateInProgressStoryScenePresentation: Identifiable, Equatable {
    let id: String
    let title: String
    let caption: String

    init(scene: AnimateStoryScene) {
        id = scene.id
        title = L10n.string("moment.story.scene", Int(scene.sceneIndex) + 1)
        caption = scene.caption
    }

    static func sorted(_ scenes: [AnimateStoryScene]) -> [AnimateInProgressStoryScenePresentation] {
        scenes
            .sorted { $0.sceneIndex < $1.sceneIndex }
            .map(AnimateInProgressStoryScenePresentation.init)
    }
}
