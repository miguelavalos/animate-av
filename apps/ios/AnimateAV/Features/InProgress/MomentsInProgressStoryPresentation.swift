import Foundation

struct MomentsInProgressStorySectionPresentation: Equatable {
    let title = L10n.string("moment.story.title")
    let emptySystemImage = "text.bubble"
    let emptyMessage = L10n.string("moment.story.empty")
    let storyScenes: [MomentsInProgressStoryScenePresentation]

    init(storyScenes: [MomentStoryScene]) {
        self.storyScenes = MomentsInProgressStoryScenePresentation.sorted(storyScenes)
    }
}

struct MomentsInProgressStoryScenePresentation: Identifiable, Equatable {
    let id: String
    let title: String
    let caption: String

    init(scene: MomentStoryScene) {
        id = scene.id
        title = L10n.string("moment.story.scene", Int(scene.sceneIndex) + 1)
        caption = scene.caption
    }

    static func sorted(_ scenes: [MomentStoryScene]) -> [MomentsInProgressStoryScenePresentation] {
        scenes
            .sorted { $0.sceneIndex < $1.sceneIndex }
            .map(MomentsInProgressStoryScenePresentation.init)
    }
}
