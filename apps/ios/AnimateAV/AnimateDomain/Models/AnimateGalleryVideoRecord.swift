import Foundation

struct AnimateGalleryVideoRecord: Identifiable, Codable, Equatable {
    let id: String
    let videoId: String
    let artifactId: String
    let title: String
    let r2Key: String
    let localRelativePath: String
    let sourceImageLocalRelativePath: String?
    let generatedImageLocalRelativePath: String?
    let createdAt: Double

    init(
        id: String,
        videoId: String,
        artifactId: String,
        title: String,
        r2Key: String,
        localRelativePath: String,
        sourceImageLocalRelativePath: String? = nil,
        generatedImageLocalRelativePath: String? = nil,
        createdAt: Double
    ) {
        self.id = id
        self.videoId = videoId
        self.artifactId = artifactId
        self.title = title
        self.r2Key = r2Key
        self.localRelativePath = localRelativePath
        self.sourceImageLocalRelativePath = sourceImageLocalRelativePath
        self.generatedImageLocalRelativePath = generatedImageLocalRelativePath
        self.createdAt = createdAt
    }

    func renamed(_ title: String) -> AnimateGalleryVideoRecord {
        AnimateGalleryVideoRecord(
            id: id,
            videoId: videoId,
            artifactId: artifactId,
            title: title,
            r2Key: r2Key,
            localRelativePath: localRelativePath,
            sourceImageLocalRelativePath: sourceImageLocalRelativePath,
            generatedImageLocalRelativePath: generatedImageLocalRelativePath,
            createdAt: createdAt
        )
    }
}

struct AnimateGalleryVideoPresentation: Identifiable, Equatable {
    let record: AnimateGalleryVideoRecord
    let localFileURL: URL?
    let sourceImageURL: URL?
    let generatedImageURL: URL?
    let availability: AnimateGalleryVideoAvailability
    let remoteArtifact: AnimateArtifact?

    var id: String { record.id }
    var title: String { record.title }
    var lookTitle: String { remoteArtifact?.look?.formattedAnimateLookTitle ?? record.title }
    var displayTitle: String {
        Self.displayTitle(title: record.title, lookTitle: lookTitle, createdAt: record.createdAt)
    }
    var isLocalFileAvailable: Bool { availability == .savedOnDevice }
    var canDownload: Bool { availability == .downloadAvailable }
    var availabilityTitle: String {
        switch availability {
        case .savedOnDevice:
            return L10n.string("gallery.video.savedOnDevice")
        case .localFileMissing:
            return L10n.string("gallery.video.localFileMissing")
        case .downloadAvailable:
            return L10n.string("gallery.video.downloadAvailable")
        case .downloadUnavailable:
            return L10n.string("gallery.video.downloadUnavailable")
        case .remoteMetadataOnly:
            return L10n.string("gallery.video.remoteMetadataOnly")
        }
    }

    static func automaticTitle(lookTitle: String, createdAt: Double) -> String {
        guard createdAt > 0 else { return lookTitle }
        return "\(lookTitle) · \(AnimateDateFormatting.formattedDate(milliseconds: createdAt))"
    }

    static func displayTitle(title: String, lookTitle: String, createdAt: Double) -> String {
        if isGenericTitle(title) {
            return automaticTitle(lookTitle: lookTitle, createdAt: createdAt)
        }
        return title
    }

    private static func isGenericTitle(_ title: String) -> Bool {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return [
            L10n.string("gallery.video.defaultTitle"),
            "Animate AV video",
            "Animate video",
            "Video Animate"
        ].map { $0.lowercased() }.contains(normalizedTitle)
    }
}

struct AnimateGalleryImageRecord: Identifiable, Codable, Equatable {
    let id: String
    let artifactId: String
    let title: String
    let look: String?
    let r2Key: String
    let localRelativePath: String
    let createdAt: Double

    init(
        id: String,
        artifactId: String,
        title: String,
        look: String?,
        r2Key: String,
        localRelativePath: String,
        createdAt: Double
    ) {
        self.id = id
        self.artifactId = artifactId
        self.title = title
        self.look = look
        self.r2Key = r2Key
        self.localRelativePath = localRelativePath
        self.createdAt = createdAt
    }
}

enum AnimateGalleryVideoAvailability: String, Equatable {
    case savedOnDevice
    case localFileMissing
    case downloadAvailable
    case downloadUnavailable
    case remoteMetadataOnly
}

struct AnimateGalleryImagePresentation: Identifiable, Equatable {
    let record: AnimateGalleryImageRecord?
    let remoteArtifact: AnimateArtifact?
    let localFileURL: URL?

    var id: String { record?.id ?? remoteArtifact?.workflowArtifactId ?? remoteArtifact?.id ?? UUID().uuidString }
    var title: String { record?.title ?? L10n.string("gallery.image.defaultTitle") }
    var lookTitle: String {
        let rawLook = record?.look ?? remoteArtifact?.look ?? parsedLookFromTitle
        guard let rawLook else { return title }

        return rawLook.formattedAnimateLookTitle
    }
    var canDownload: Bool {
        guard localFileURL == nil,
              let remoteArtifact
        else { return false }

        return remoteArtifact.status == "available"
            && remoteArtifact.expiresAt > Date().timeIntervalSince1970 * 1000
    }
    var availabilityTitle: String {
        if localFileURL != nil {
            return L10n.string("gallery.image.downloaded")
        }
        return canDownload
            ? L10n.string("gallery.image.downloadAvailable")
            : L10n.string("gallery.image.downloadUnavailable")
    }

    private var parsedLookFromTitle: String? {
        guard let title = remoteArtifact?.title,
              title.hasPrefix("Animate AV "),
              title.hasSuffix(" image")
        else { return nil }

        return String(title.dropFirst("Animate AV ".count).dropLast(" image".count))
    }

}

extension String {
    var formattedAnimateLookTitle: String {
        replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { word in
                word.prefix(1).uppercased() + word.dropFirst()
            }
            .joined(separator: " ")
    }
}
