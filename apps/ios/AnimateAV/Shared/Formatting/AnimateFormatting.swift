import Foundation

enum AnimateDateFormatting {
    static func formattedDate(milliseconds: Double) -> String {
        let date = Date(timeIntervalSince1970: milliseconds / 1000)
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

enum AnimateVideoFormatting {
    static func updatedAt(_ video: AnimateVideo) -> String {
        L10n.string(
            "video.date.updated",
            AnimateDateFormatting.formattedDate(milliseconds: video.updatedAt)
        )
    }

    static func galleryDate(_ milliseconds: Double) -> String {
        L10n.string("video.date.saved", AnimateDateFormatting.formattedDate(milliseconds: milliseconds))
    }

    static func storyUsage(_ video: AnimateVideo) -> String {
        L10n.string("video.kind.story")
    }

    static func statusTitle(_ video: AnimateVideo) -> String {
        AnimateStatusRules.displayTitle(for: video.status)
    }

    static func compactDetail(for video: AnimateVideo, includeTitle: Bool = false) -> String {
        var parts: [String] = []

        if includeTitle {
            parts.append(video.title)
        }

        parts.append(statusTitle(video))
        parts.append(updatedAt(video))

        return parts.joined(separator: " · ")
    }

    static func mediaAssetDetail(_ media: AnimateMediaAsset) -> String {
        let selection = media.selected
            ? L10n.string("video.media.selected")
            : L10n.string("video.media.notSelected")
        return "\(selection) · \(AnimateStatusRules.displayTitle(for: media.moderationStatus))"
    }

    static func artifactDetail(_ artifact: AnimateArtifact) -> String {
        var parts = [
            AnimateStatusRules.displayTitle(for: artifact.status)
        ]

        if artifact.hasWatermark == true {
            parts.append(L10n.string("video.artifact.watermarked"))
        }

        parts.append(L10n.string(
            "video.artifact.expiresAt",
            AnimateDateFormatting.formattedDate(milliseconds: artifact.expiresAt)
        ))
        return parts.joined(separator: " · ")
    }
}
