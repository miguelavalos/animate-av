import Foundation

struct AnimateInProgressVideoDirectionSectionPresentation: Equatable {
    let title = L10n.string("video.story.title")
    let emptySystemImage = "text.bubble"
    let emptyMessage = L10n.string("video.story.empty")
    let videoDirectionScenes: [AnimateInProgressVideoDirectionScenePresentation]

    init(videoDirectionScenes: [AnimateVideoDirectionScene]) {
        self.videoDirectionScenes = AnimateInProgressVideoDirectionScenePresentation.sorted(videoDirectionScenes)
    }
}

struct AnimateInProgressVideoDirectionScenePresentation: Identifiable, Equatable {
    let id: String
    let title: String
    let caption: String

    init(scene: AnimateVideoDirectionScene) {
        id = scene.id
        title = L10n.string("video.story.scene", Int(scene.sceneIndex) + 1)
        caption = scene.caption
    }

    static func sorted(_ scenes: [AnimateVideoDirectionScene]) -> [AnimateInProgressVideoDirectionScenePresentation] {
        scenes
            .sorted { $0.sceneIndex < $1.sceneIndex }
            .map(AnimateInProgressVideoDirectionScenePresentation.init)
    }
}
