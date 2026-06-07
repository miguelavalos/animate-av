import Foundation

struct AnimateArtifact: Identifiable, Decodable, Equatable {
    let id: String
    let workflowArtifactId: String?
    let kind: String
    let r2Key: String
    let status: String
    let hasWatermark: Bool?
    let expiresAt: Double
    let createdAt: Double

    init(
        id: String,
        workflowArtifactId: String? = nil,
        kind: String,
        r2Key: String,
        status: String,
        hasWatermark: Bool?,
        expiresAt: Double,
        createdAt: Double = 0
    ) {
        self.id = id
        self.workflowArtifactId = workflowArtifactId
        self.kind = kind
        self.r2Key = r2Key
        self.status = status
        self.hasWatermark = hasWatermark
        self.expiresAt = expiresAt
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case workflowArtifactId
        case kind
        case r2Key
        case status
        case hasWatermark
        case expiresAt
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? container.decode(String.self, forKey: .workflowArtifactId)
        workflowArtifactId = try container.decodeIfPresent(String.self, forKey: .workflowArtifactId)
        kind = try container.decode(String.self, forKey: .kind)
        r2Key = try container.decode(String.self, forKey: .r2Key)
        status = try container.decode(String.self, forKey: .status)
        hasWatermark = try container.decodeIfPresent(Bool.self, forKey: .hasWatermark)
        expiresAt = try container.decodeIfPresent(Double.self, forKey: .expiresAt) ?? 0
        createdAt = try container.decodeIfPresent(Double.self, forKey: .createdAt) ?? 0
    }
}
