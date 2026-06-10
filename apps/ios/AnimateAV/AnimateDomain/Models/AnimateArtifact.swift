import Foundation

struct AnimateArtifact: Identifiable, Decodable, Equatable {
    let id: String
    let workflowArtifactId: String?
    let kind: String
    let r2Key: String
    let title: String?
    let look: String?
    let status: String
    let durationSeconds: Double?
    let creditCost: Int?
    let hasWatermark: Bool?
    let expiresAt: Double
    let createdAt: Double

    init(
        id: String,
        workflowArtifactId: String? = nil,
        kind: String,
        r2Key: String,
        title: String? = nil,
        look: String? = nil,
        status: String,
        durationSeconds: Double? = nil,
        creditCost: Int? = nil,
        hasWatermark: Bool?,
        expiresAt: Double,
        createdAt: Double = 0
    ) {
        self.id = id
        self.workflowArtifactId = workflowArtifactId
        self.kind = kind
        self.r2Key = r2Key
        self.title = title
        self.look = look
        self.status = status
        self.durationSeconds = durationSeconds
        self.creditCost = creditCost
        self.hasWatermark = hasWatermark
        self.expiresAt = expiresAt
        self.createdAt = createdAt
    }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case workflowArtifactId
        case kind
        case r2Key
        case title
        case look
        case status
        case durationSeconds
        case creditCost
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
        title = try container.decodeIfPresent(String.self, forKey: .title)
        look = try container.decodeIfPresent(String.self, forKey: .look)
        status = try container.decode(String.self, forKey: .status)
        durationSeconds = try container.decodeIfPresent(Double.self, forKey: .durationSeconds)
        creditCost = try container.decodeIfPresent(Int.self, forKey: .creditCost)
        hasWatermark = try container.decodeIfPresent(Bool.self, forKey: .hasWatermark)
        expiresAt = try container.decodeIfPresent(Double.self, forKey: .expiresAt) ?? 0
        createdAt = try container.decodeIfPresent(Double.self, forKey: .createdAt) ?? 0
    }
}
