import Foundation

struct AnimateInProgressWorkspaceHeaderPresentation: Equatable {
    let title: String
    let updatedAtTitle: String
    let countsTitle: String

    init(workspace: MomentWorkspace) {
        title = workspace.moment.title
        updatedAtTitle = AnimateVideoFormatting.updatedAt(workspace.moment)
        countsTitle = [
            Self.countTitle(workspace.mediaAssets.count, singular: "media item", plural: "media items"),
            Self.countTitle(workspace.storyScenes.count, singular: "scene", plural: "scenes"),
            Self.countTitle(workspace.renderJobs.count, singular: "job", plural: "jobs")
        ].joined(separator: " · ")
    }

    private static func countTitle(_ count: Int, singular: String, plural: String) -> String {
        "\(count) \(count == 1 ? singular : plural)"
    }
}

