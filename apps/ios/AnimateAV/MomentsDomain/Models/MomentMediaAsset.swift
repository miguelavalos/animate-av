import Foundation

struct MomentMediaAsset: Identifiable, Decodable, Equatable {
    let id: String
    let platformMediaAssetId: String?
    let uploadId: String?
    let kind: String
    let r2Key: String?
    let thumbnailR2Key: String?
    let sortOrder: Double
    let selected: Bool
    let moderationStatus: String
    let uploadedAt: Double?
    let sourceExpiresAt: Double?

    init(
        id: String,
        platformMediaAssetId: String?,
        uploadId: String?,
        kind: String,
        r2Key: String? = nil,
        thumbnailR2Key: String? = nil,
        sortOrder: Double,
        selected: Bool,
        moderationStatus: String,
        uploadedAt: Double?,
        sourceExpiresAt: Double?
    ) {
        self.id = id
        self.platformMediaAssetId = platformMediaAssetId
        self.uploadId = uploadId
        self.kind = kind
        self.r2Key = r2Key
        self.thumbnailR2Key = thumbnailR2Key
        self.sortOrder = sortOrder
        self.selected = selected
        self.moderationStatus = moderationStatus
        self.uploadedAt = uploadedAt
        self.sourceExpiresAt = sourceExpiresAt
    }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case platformMediaAssetId
        case uploadId
        case kind
        case r2Key
        case thumbnailR2Key
        case sortOrder
        case selected
        case moderationStatus
        case uploadedAt
        case sourceExpiresAt
    }
}
