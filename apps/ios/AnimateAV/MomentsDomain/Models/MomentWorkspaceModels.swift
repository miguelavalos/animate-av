import Foundation

struct MomentWorkspace: Decodable, Equatable {
    let moment: InProgressMoment
    let mediaAssets: [MomentMediaAsset]
    let storyScenes: [MomentStoryScene]
    let renderJobs: [MomentRenderJob]
    let artifacts: [MomentArtifact]
}
