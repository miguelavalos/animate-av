import Foundation

struct MomentsGalleryVideoRecord: Identifiable, Codable, Equatable {
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

    func renamed(_ title: String) -> MomentsGalleryVideoRecord {
        MomentsGalleryVideoRecord(
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

struct MomentsGalleryVideoPresentation: Identifiable, Equatable {
    let record: MomentsGalleryVideoRecord
    let localFileURL: URL?
    let availability: MomentsGalleryVideoAvailability
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

enum MomentsGalleryVideoAvailability: String, Equatable {
    case savedOnDevice
    case localFileMissing
    case downloadAvailable
    case downloadUnavailable
    case remoteMetadataOnly
}
