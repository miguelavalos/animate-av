import Foundation

struct MomentsInProgressMediaSectionPresentation: Equatable {
    let title = L10n.string("moment.media.title")
    let emptySystemImage = "photo.badge.plus"
    let emptyMessage = L10n.string("moment.media.empty")
    let mediaAssets: [MomentsInProgressMediaAssetPresentation]

    init(mediaAssets: [MomentMediaAsset]) {
        self.mediaAssets = MomentsInProgressMediaAssetPresentation.sorted(mediaAssets)
    }
}

struct MomentsInProgressMediaAssetPresentation: Identifiable, Equatable {
    let id: String
    let systemImage: String
    let title: String
    let detail: String

    init(mediaAsset: MomentMediaAsset) {
        id = mediaAsset.id
        systemImage = mediaAsset.kind == "video" ? "video" : "photo"
        title = "\(MomentStatusRules.displayKind(mediaAsset.kind)) \(Int(mediaAsset.sortOrder) + 1)"
        detail = MomentsMomentFormatting.mediaAssetDetail(mediaAsset)
    }

    static func sorted(_ mediaAssets: [MomentMediaAsset]) -> [MomentsInProgressMediaAssetPresentation] {
        mediaAssets
            .sorted { $0.sortOrder < $1.sortOrder }
            .map(MomentsInProgressMediaAssetPresentation.init)
    }
}
