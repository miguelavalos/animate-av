import Foundation

struct AnimateInProgressMediaSectionPresentation: Equatable {
    let title = L10n.string("moment.media.title")
    let emptySystemImage = "photo.badge.plus"
    let emptyMessage = L10n.string("moment.media.empty")
    let mediaAssets: [AnimateInProgressMediaAssetPresentation]

    init(mediaAssets: [MomentMediaAsset]) {
        self.mediaAssets = AnimateInProgressMediaAssetPresentation.sorted(mediaAssets)
    }
}

struct AnimateInProgressMediaAssetPresentation: Identifiable, Equatable {
    let id: String
    let systemImage: String
    let title: String
    let detail: String

    init(mediaAsset: MomentMediaAsset) {
        id = mediaAsset.id
        systemImage = mediaAsset.kind == "video" ? "video" : "photo"
        title = "\(MomentStatusRules.displayKind(mediaAsset.kind)) \(Int(mediaAsset.sortOrder) + 1)"
        detail = AnimateVideoFormatting.mediaAssetDetail(mediaAsset)
    }

    static func sorted(_ mediaAssets: [MomentMediaAsset]) -> [AnimateInProgressMediaAssetPresentation] {
        mediaAssets
            .sorted { $0.sortOrder < $1.sortOrder }
            .map(AnimateInProgressMediaAssetPresentation.init)
    }
}
