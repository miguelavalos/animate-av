import Foundation

struct AnimateRenderStatusResponse: Decodable, Equatable {
    let appId: String
    let videoId: String
    let renderJobId: String
    let workflowRunId: String?
    let renderKind: String
    let status: String
    let phase: String?
    let progressPercent: Int
    let userMessage: String?
    let canEditSetup: Bool?
    let canRetry: Bool?
    let artifactId: String?
    let artifactKind: String?
    let artifactStatus: String?
    let artifactR2Key: String?
    let artifactDurationSeconds: Int?
    let artifactCreditCost: Int?
    let artifactHasWatermark: Bool?
    let sourceImageArtifactId: String?
    let generatedImageArtifactId: String?
    let errorCode: String?
    let errorMessage: String?
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case appId
        case videoId
        case renderJobId
        case workflowRunId
        case renderKind
        case status
        case phase
        case progressPercent
        case userMessage
        case canEditSetup
        case canRetry
        case artifactId
        case artifactKind
        case artifactStatus
        case artifactR2Key
        case artifactDurationSeconds
        case artifactCreditCost
        case artifactHasWatermark
        case sourceImageArtifactId
        case generatedImageArtifactId
        case errorCode
        case errorMessage
        case updatedAt
    }
}
