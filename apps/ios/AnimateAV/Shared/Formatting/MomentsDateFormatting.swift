import Foundation

enum MomentsDateFormatting {
    static func formattedDate(milliseconds: Double) -> String {
        let date = Date(timeIntervalSince1970: milliseconds / 1000)
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

enum MomentsMomentFormatting {
    static func updatedAt(_ moment: InProgressMoment) -> String {
        "Updated \(MomentsDateFormatting.formattedDate(milliseconds: moment.updatedAt))"
    }

    static func galleryDate(_ milliseconds: Double) -> String {
        "Saved \(MomentsDateFormatting.formattedDate(milliseconds: milliseconds))"
    }

    static func storyUsage(_ moment: InProgressMoment) -> String {
        L10n.string("moment.kind.story")
    }

    static func statusTitle(_ moment: InProgressMoment) -> String {
        MomentStatusRules.displayTitle(for: moment.status)
    }

    static func compactDetail(for moment: InProgressMoment, includeTitle: Bool = false) -> String {
        var parts: [String] = []

        if includeTitle {
            parts.append(moment.title)
        }

        parts.append(statusTitle(moment))
        parts.append(updatedAt(moment))

        return parts.joined(separator: " · ")
    }

    static func mediaAssetDetail(_ media: MomentMediaAsset) -> String {
        let selection = media.selected ? "Selected" : "Not selected"
        return "\(selection) · \(MomentStatusRules.displayTitle(for: media.moderationStatus))"
    }

    static func artifactDetail(_ artifact: MomentArtifact) -> String {
        var parts = [
            MomentStatusRules.displayTitle(for: artifact.status)
        ]

        if artifact.hasWatermark == true {
            parts.append("Watermarked")
        }

        parts.append("Expires \(MomentsDateFormatting.formattedDate(milliseconds: artifact.expiresAt))")
        return parts.joined(separator: " · ")
    }
}
