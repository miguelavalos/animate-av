import Foundation

struct AnimateWorkspace: Decodable, Equatable {
    let video: AnimateVideo
    let mediaAssets: [AnimateMediaAsset]
    let storyScenes: [AnimateStoryScene]
    let renderJobs: [AnimateRenderJob]
    let artifacts: [AnimateArtifact]

    private enum CodingKeys: String, CodingKey {
        case video = "moment"
        case mediaAssets
        case storyScenes
        case renderJobs
        case artifacts
    }
}
