import Foundation

struct AnimateWorkspace: Decodable, Equatable {
    let video: AnimateVideo
    let mediaAssets: [AnimateMediaAsset]
    let storyScenes: [AnimateVideoDirectionScene]
    let renderJobs: [AnimateRenderJob]
    let artifacts: [AnimateArtifact]

    private enum CodingKeys: String, CodingKey {
        case video
        case mediaAssets
        case storyScenes
        case renderJobs
        case artifacts
    }
}
