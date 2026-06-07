import Foundation

struct AnimateVideo: Identifiable, Decodable, Equatable {
    let id: String
    let template: AnimateVideoTemplateID
    let creationMode: String
    let look: String
    let theme: String
    let mood: String?
    let duration: String
    let mediaUse: String
    let status: String
    let title: String
    let tone: String?
    let tempo: String?
    let occasion: String?
    let details: String?
    let storyInputSignature: String?
    let durationSeconds: Double
    let creditCost: Double
    let updatedAt: Double
    let mediaCount: Int
    let mediaPreview: [AnimateMediaAsset]
    let finalExport: AnimateArtifact?
    let assetKind: String

    init(
        id: String,
        template: AnimateVideoTemplateID,
        creationMode: String = "quick",
        look: String = "cartoon",
        theme: String = "celebration",
        mood: String? = nil,
        duration: String = "auto",
        mediaUse: String = "aviPick",
        status: String,
        title: String,
        tone: String?,
        tempo: String?,
        occasion: String?,
        details: String?,
        storyInputSignature: String? = nil,
        durationSeconds: Double,
        creditCost: Double,
        updatedAt: Double,
        mediaCount: Int = 0,
        mediaPreview: [AnimateMediaAsset] = [],
        finalExport: AnimateArtifact? = nil,
        assetKind: String = "video"
    ) {
        self.id = id
        self.template = template
        self.creationMode = creationMode
        self.look = look
        self.theme = theme
        self.mood = mood
        self.duration = duration
        self.mediaUse = mediaUse
        self.status = status
        self.title = title
        self.tone = tone
        self.tempo = tempo
        self.occasion = occasion
        self.details = details
        self.storyInputSignature = storyInputSignature
        self.durationSeconds = durationSeconds
        self.creditCost = creditCost
        self.updatedAt = updatedAt
        self.mediaCount = mediaCount
        self.mediaPreview = mediaPreview
        self.finalExport = finalExport
        self.assetKind = assetKind
    }

    func renamed(_ title: String) -> AnimateVideo {
        AnimateVideo(
            id: id,
            template: template,
            creationMode: creationMode,
            look: look,
            theme: theme,
            mood: mood,
            duration: duration,
            mediaUse: mediaUse,
            status: status,
            title: title,
            tone: tone,
            tempo: tempo,
            occasion: occasion,
            details: details,
            storyInputSignature: storyInputSignature,
            durationSeconds: durationSeconds,
            creditCost: creditCost,
            updatedAt: updatedAt,
            mediaCount: mediaCount,
            mediaPreview: mediaPreview,
            finalExport: finalExport,
            assetKind: assetKind
        )
    }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case template
        case creationMode
        case look
        case theme
        case mood
        case duration
        case mediaUse
        case status
        case title
        case tone
        case tempo
        case occasion
        case details
        case storyInputSignature
        case durationSeconds
        case creditCost
        case updatedAt
        case mediaCount
        case mediaPreview
        case finalExport
        case assetKind
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        template = try container.decodeIfPresent(AnimateVideoTemplateID.self, forKey: .template)
            ?? AnimateVideoTemplateID(rawValue: try container.decodeIfPresent(String.self, forKey: .theme) ?? "")
            ?? .birthdayMessage
        creationMode = try container.decodeIfPresent(String.self, forKey: .creationMode) ?? "quick"
        look = try container.decodeIfPresent(String.self, forKey: .look) ?? "cartoon"
        theme = try container.decodeIfPresent(String.self, forKey: .theme) ?? template.rawValue
        mood = try container.decodeIfPresent(String.self, forKey: .mood)
            ?? container.decodeIfPresent(String.self, forKey: .tone)
        duration = try container.decodeIfPresent(String.self, forKey: .duration) ?? "auto"
        mediaUse = try container.decodeIfPresent(String.self, forKey: .mediaUse) ?? "aviPick"
        status = try container.decode(String.self, forKey: .status)
        title = try container.decode(String.self, forKey: .title)
        tone = try container.decodeIfPresent(String.self, forKey: .tone)
        tempo = try container.decodeIfPresent(String.self, forKey: .tempo)
        occasion = try container.decodeIfPresent(String.self, forKey: .occasion)
        details = try container.decodeIfPresent(String.self, forKey: .details)
        storyInputSignature = try container.decodeIfPresent(String.self, forKey: .storyInputSignature)
        durationSeconds = try container.decode(Double.self, forKey: .durationSeconds)
        creditCost = try container.decode(Double.self, forKey: .creditCost)
        updatedAt = try container.decode(Double.self, forKey: .updatedAt)
        mediaPreview = try container.decodeIfPresent([AnimateMediaAsset].self, forKey: .mediaPreview) ?? []
        mediaCount = try container.decodeIfPresent(Int.self, forKey: .mediaCount) ?? mediaPreview.count
        finalExport = try container.decodeIfPresent(AnimateArtifact.self, forKey: .finalExport)
        assetKind = try container.decodeIfPresent(String.self, forKey: .assetKind) ?? "video"
    }
}
