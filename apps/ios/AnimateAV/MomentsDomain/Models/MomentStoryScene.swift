import Foundation

struct MomentStoryScene: Identifiable, Decodable, Equatable {
    let id: String
    let sceneIndex: Double
    let mediaAssetIds: [String]
    let caption: String
    let narrationText: String?
    let tone: String?
    let musicCue: String?
    let durationMs: Double
    let createdBy: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case sceneIndex
        case mediaAssetIds
        case caption
        case narrationText
        case tone
        case musicCue
        case durationMs
        case createdBy
    }
}
