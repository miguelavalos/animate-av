import Foundation

struct AnimateGalleryVideoRecord: Identifiable, Codable, Equatable {
    let id: String
    let momentId: String
    let artifactId: String
    let title: String
    let r2Key: String
    let localRelativePath: String
    let createdAt: Double

    init(
        id: String,
        momentId: String,
        artifactId: String,
        title: String,
        r2Key: String,
        localRelativePath: String,
        createdAt: Double
    ) {
        self.id = id
        self.momentId = momentId
        self.artifactId = artifactId
        self.title = title
        self.r2Key = r2Key
        self.localRelativePath = localRelativePath
        self.createdAt = createdAt
    }

    func renamed(_ title: String) -> AnimateGalleryVideoRecord {
        AnimateGalleryVideoRecord(
            id: id,
            momentId: momentId,
            artifactId: artifactId,
            title: title,
            r2Key: r2Key,
            localRelativePath: localRelativePath,
            createdAt: createdAt
        )
    }
}

struct AnimateGalleryVideoPresentation: Identifiable, Equatable {
    let record: AnimateGalleryVideoRecord
    let localFileURL: URL?
    let availability: AnimateGalleryVideoAvailability
    let remoteArtifact: MomentArtifact?

    var id: String { record.id }
    var title: String { record.title }
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
}

enum AnimateGalleryVideoAvailability: String, Equatable {
    case savedOnDevice
    case localFileMissing
    case downloadAvailable
    case downloadUnavailable
    case remoteMetadataOnly
}

struct AnimateGalleryImagePresentation: Identifiable, Equatable {
    let artifact: MomentArtifact
    let localFileURL: URL?

    var id: String { artifact.workflowArtifactId ?? artifact.id }
    var title: String { L10n.string("gallery.image.defaultTitle") }
    var canDownload: Bool {
        artifact.status == "available"
            && artifact.expiresAt > Date().timeIntervalSince1970 * 1000
    }
    var availabilityTitle: String {
        if localFileURL != nil {
            return L10n.string("gallery.image.downloaded")
        }
        return canDownload
            ? L10n.string("gallery.image.downloadAvailable")
            : L10n.string("gallery.image.downloadUnavailable")
    }
}
