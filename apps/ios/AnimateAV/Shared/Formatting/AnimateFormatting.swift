import Foundation

enum AnimateDateFormatting {
    static func formattedDate(milliseconds: Double) -> String {
        let date = Date(timeIntervalSince1970: milliseconds / 1000)
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

enum AnimateVideoFormatting {
    static func updatedAt(_ moment: AnimateVideo) -> String {
        "Updated \(AnimateDateFormatting.formattedDate(milliseconds: moment.updatedAt))"
    }

    static func galleryDate(_ milliseconds: Double) -> String {
        "Saved \(AnimateDateFormatting.formattedDate(milliseconds: milliseconds))"
    }

    static func storyUsage(_ moment: AnimateVideo) -> String {
        L10n.string("moment.kind.story")
    }

    static func statusTitle(_ moment: AnimateVideo) -> String {
        AnimateStatusRules.displayTitle(for: moment.status)
    }

    static func compactDetail(for moment: AnimateVideo, includeTitle: Bool = false) -> String {
        var parts: [String] = []

        if includeTitle {
            parts.append(moment.title)
        }

        parts.append(statusTitle(moment))
        parts.append(updatedAt(moment))

        return parts.joined(separator: " · ")
    }

    static func mediaAssetDetail(_ media: AnimateMediaAsset) -> String {
        let selection = media.selected ? "Selected" : "Not selected"
        return "\(selection) · \(AnimateStatusRules.displayTitle(for: media.moderationStatus))"
    }

    static func artifactDetail(_ artifact: AnimateArtifact) -> String {
        var parts = [
            AnimateStatusRules.displayTitle(for: artifact.status)
        ]

        if artifact.hasWatermark == true {
            parts.append("Watermarked")
        }

        parts.append("Expires \(AnimateDateFormatting.formattedDate(milliseconds: artifact.expiresAt))")
        return parts.joined(separator: " · ")
    }
}
