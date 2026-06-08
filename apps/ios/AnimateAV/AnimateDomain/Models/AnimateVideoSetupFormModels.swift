import Foundation

enum AnimateVideoSetupTone: String, CaseIterable, Identifiable {
    case warm
    case playful
    case cinematic
    case calm
    case upbeat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .warm: L10n.string("create.tone.warm.title")
        case .playful: L10n.string("create.tone.playful.title")
        case .cinematic: L10n.string("create.tone.cinematic.title")
        case .calm: L10n.string("create.tone.calm.title")
        case .upbeat: L10n.string("create.tone.upbeat.title")
        }
    }
}

enum AnimateVideoSetupTempo: String, CaseIterable, Identifiable {
    case gentle
    case balanced
    case upbeat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gentle: L10n.string("create.tempo.gentle.title")
        case .balanced: L10n.string("create.tempo.balanced.title")
        case .upbeat: L10n.string("create.tempo.upbeat.title")
        }
    }
}

extension AnimateVideoSetupTone {
    init(musicPreset: AnimateVideoMusicPreset) {
        switch musicPreset {
        case .warm:
            self = .warm
        case .fun:
            self = .playful
        case .cinematic:
            self = .cinematic
        case .calm:
            self = .calm
        case .upbeat:
            self = .upbeat
        }
    }
}

struct AnimateVideoSetupForm: Equatable {
    var creationMode: AnimateVideoCreationMode = .quick
    var look: AnimateVideoLook = .cartoon
    var theme: AnimateVideoCreationStyleID = .celebration
    var duration: AnimateVideoDuration = .auto
    var mediaUse: AnimateVideoMediaUse = .aviPick
    var template: AnimateVideoTemplate
    var occasion = "Birthday"
    var recipient = ""
    var tone: AnimateVideoSetupTone = .warm
    var tempo: AnimateVideoSetupTempo = .balanced
    var details = ""

    var title: String {
        let trimmedRecipient = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOccasion = occasion.trimmingCharacters(in: .whitespacesAndNewlines)
        let videoTitle = trimmedOccasion.isEmpty ? template.title : trimmedOccasion
        return trimmedRecipient.isEmpty ? videoTitle : "\(videoTitle) for \(trimmedRecipient)"
    }

    var canCreateVideo: Bool {
        !occasion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func continuing(
        video: AnimateVideo,
        templates: [AnimateVideoTemplate]
    ) -> AnimateVideoSetupForm? {
        guard let template = templates.first(where: { $0.id == video.template }) else {
            return nil
        }

        var form = AnimateVideoSetupForm(
            template: template,
            occasion: video.occasion ?? "",
            recipient: "",
            tone: AnimateVideoSetupTone(rawValue: video.mood ?? video.tone ?? "") ?? .warm,
            tempo: AnimateVideoSetupTempo(rawValue: video.tempo ?? "") ?? .balanced,
            details: video.details ?? ""
        )
        form.creationMode = .quick
        form.look = AnimateVideoLook(rawValue: video.look) ?? .cartoon
        form.theme = AnimateVideoCreationStyleID(rawValue: video.theme) ?? .celebration
        form.duration = AnimateVideoDuration(rawValue: video.duration) ?? .auto
        form.mediaUse = AnimateVideoMediaUse(rawValue: video.mediaUse) ?? .aviPick
        return form
    }

    func matchesPersistedSetup(of other: AnimateVideoSetupForm) -> Bool {
        creationMode == other.creationMode
            && look == other.look
            && theme == other.theme
            && duration == other.duration
            && mediaUse == other.mediaUse
            && occasion.trimmingCharacters(in: .whitespacesAndNewlines) == other.occasion.trimmingCharacters(in: .whitespacesAndNewlines)
            && tone == other.tone
            && tempo == other.tempo
            && details.trimmingCharacters(in: .whitespacesAndNewlines) == other.details.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum AnimateVideoSetupRules {
    enum BlockReason {
        case missingOccasion
    }

    struct Availability {
        let canCreateVideo: Bool
        let blockReason: BlockReason?
    }

    static func availability(
        form: AnimateVideoSetupForm,
        balance: AnimateCreditBalance
    ) -> Availability {
        guard !form.occasion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Availability(canCreateVideo: false, blockReason: .missingOccasion)
        }

        return Availability(canCreateVideo: true, blockReason: nil)
    }

    static func availabilityMessage(_ availability: Availability) -> String? {
        switch availability.blockReason {
        case nil:
            return nil
        case .missingOccasion:
            return L10n.string("create.rules.missingOccasion")
        }
    }
}
