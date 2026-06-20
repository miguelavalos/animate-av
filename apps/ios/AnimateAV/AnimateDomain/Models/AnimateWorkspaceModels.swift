import Foundation

struct AnimateWorkspace: Decodable, Equatable {
    let video: AnimateVideo
    let mediaAssets: [AnimateMediaAsset]
    let videoDirectionScenes: [AnimateVideoDirectionScene]
    let renderJobs: [AnimateRenderJob]
    let artifacts: [AnimateArtifact]

    private enum CodingKeys: String, CodingKey {
        case video
        case mediaAssets
        case videoDirectionScenes
        case renderJobs
        case artifacts
    }
}
