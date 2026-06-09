import Foundation

struct AnimateInProgressMediaSectionPresentation: Equatable {
    let title = L10n.string("video.media.title")
    let emptySystemImage = "photo.badge.plus"
    let emptyMessage = L10n.string("video.media.empty")
    let mediaAssets: [AnimateInProgressMediaAssetPresentation]

    init(mediaAssets: [AnimateMediaAsset]) {
        self.mediaAssets = AnimateInProgressMediaAssetPresentation.sorted(mediaAssets)
    }
}

struct AnimateInProgressMediaAssetPresentation: Identifiable, Equatable {
    let id: String
    let systemImage: String
    let title: String
    let detail: String

    init(mediaAsset: AnimateMediaAsset) {
        id = mediaAsset.id
        systemImage = mediaAsset.kind == "video" ? "video" : "photo"
        title = "\(AnimateStatusRules.displayKind(mediaAsset.kind)) \(Int(mediaAsset.sortOrder) + 1)"
        detail = AnimateVideoFormatting.mediaAssetDetail(mediaAsset)
    }

    static func sorted(_ mediaAssets: [AnimateMediaAsset]) -> [AnimateInProgressMediaAssetPresentation] {
        mediaAssets
            .sorted { $0.sortOrder < $1.sortOrder }
            .map(AnimateInProgressMediaAssetPresentation.init)
    }
}
