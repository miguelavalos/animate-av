import Foundation

struct AnimateWorkspace: Decodable, Equatable {
    let moment: AnimateVideo
    let mediaAssets: [AnimateMediaAsset]
    let storyScenes: [AnimateStoryScene]
    let renderJobs: [AnimateRenderJob]
    let artifacts: [AnimateArtifact]
}
