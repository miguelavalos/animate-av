import Foundation
import SwiftUI

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

enum AnimateVideoVoiceProfile: String, CaseIterable, Identifiable {
    case narratorWoman
    case narratorMan

    var id: String { rawValue }

    static var selectorOrder: [AnimateVideoVoiceProfile] {
        [.narratorWoman, .narratorMan]
    }

    var title: String {
        switch self {
        case .narratorWoman: L10n.string("create.voiceProfile.narratorWoman.title")
        case .narratorMan: L10n.string("create.voiceProfile.narratorMan.title")
        }
    }

    var detail: String {
        switch self {
        case .narratorWoman: L10n.string("create.voiceProfile.narratorWoman.detail")
        case .narratorMan: L10n.string("create.voiceProfile.narratorMan.detail")
        }
    }

    var portraitAssetName: String {
        switch self {
        case .narratorWoman: "VoiceAdultWoman"
        case .narratorMan: "VoiceAdultMan"
        }
    }

    var avatarSystemImage: String {
        switch self {
        case .narratorWoman, .narratorMan: "person.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .narratorWoman: Color(red: 0.88, green: 0.48, blue: 0.28)
        case .narratorMan: Color(red: 0.35, green: 0.52, blue: 0.84)
        }
    }

    var skinColor: Color {
        switch self {
        case .narratorWoman: Color(red: 0.86, green: 0.62, blue: 0.43)
        case .narratorMan: Color(red: 0.34, green: 0.22, blue: 0.16)
        }
    }

    var hairColor: Color {
        switch self {
        case .narratorWoman: Color(red: 0.36, green: 0.18, blue: 0.08)
        case .narratorMan: Color(red: 0.04, green: 0.04, blue: 0.04)
        }
    }
}

enum AnimateVideoVoiceTone: String, CaseIterable, Identifiable {
    case warm
    case cheerful
    case calm
    case dramatic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .warm: L10n.string("create.voiceTone.warm.title")
        case .cheerful: L10n.string("create.voiceTone.cheerful.title")
        case .calm: L10n.string("create.voiceTone.calm.title")
        case .dramatic: L10n.string("create.voiceTone.dramatic.title")
        }
    }

    var systemImage: String {
        switch self {
        case .warm: "heart.fill"
        case .cheerful: "sparkles"
        case .calm: "leaf.fill"
        case .dramatic: "theatermasks.fill"
        }
    }
}

enum AnimateVideoMovementDirection: String, CaseIterable, Identifiable, Codable {
    case subtleFaithful
    case livingPortrait
    case livingBackground
    case cinematic
    case celebration
    case custom

    var id: String { rawValue }

    static var selectorOrder: [AnimateVideoMovementDirection] {
        [.subtleFaithful, .livingPortrait, .livingBackground, .cinematic, .celebration]
    }

    var title: String {
        switch self {
        case .subtleFaithful: L10n.string("create.movement.subtleFaithful.title")
        case .livingPortrait: L10n.string("create.movement.livingPortrait.title")
        case .livingBackground: L10n.string("create.movement.livingBackground.title")
        case .cinematic: L10n.string("create.movement.cinematic.title")
        case .celebration: L10n.string("create.movement.celebration.title")
        case .custom: L10n.string("create.movement.custom.title")
        }
    }

    var detail: String {
        switch self {
        case .subtleFaithful: L10n.string("create.movement.subtleFaithful.detail")
        case .livingPortrait: L10n.string("create.movement.livingPortrait.detail")
        case .livingBackground: L10n.string("create.movement.livingBackground.detail")
        case .cinematic: L10n.string("create.movement.cinematic.detail")
        case .celebration: L10n.string("create.movement.celebration.detail")
        case .custom: L10n.string("create.movement.custom.detail")
        }
    }

    var systemImage: String {
        switch self {
        case .subtleFaithful: "camera.aperture"
        case .livingPortrait: "person.crop.circle"
        case .livingBackground: "leaf.fill"
        case .cinematic: "movieclapper.fill"
        case .celebration: "sparkles"
        case .custom: "slider.horizontal.3"
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

enum AnimateVideoSetupLimits {
    static let messageCharacterLimit = 150
    static let animationDirectionCharacterLimit = 500
}

struct AnimateVideoSetupForm: Equatable {
    var creationMode: AnimateVideoCreationMode = .quick
    var look: AnimateVideoLook = .cartoon
    var theme: AnimateVideoCreationStyleID = .celebration
    var duration: AnimateVideoDuration = .auto
    var mediaUse: AnimateVideoMediaUse = .aviPick
    var template: AnimateVideoTemplate
    var occasion = "Character intro"
    var recipient = ""
    var tone: AnimateVideoSetupTone = .warm
    var tempo: AnimateVideoSetupTempo = .balanced
    var details = ""
    var hasMessage = false
    var audioEnabled = true
    var musicEnabled = true
    var voiceEnabled = false
    var voiceProfile: AnimateVideoVoiceProfile = .narratorWoman
    var voiceTone: AnimateVideoVoiceTone = .warm
    var movementDirection: AnimateVideoMovementDirection = .subtleFaithful
    var visualDirectionMode: AnimateVisualDirectionMode = .none
    var visualDirectionTemplateId: String?
    var animationDirection = ""
    var startsWithSourcePhoto = true

    var activeMessageText: String? {
        let trimmed = details.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var activeVoiceProfile: AnimateVideoVoiceProfile? {
        nil
    }

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
        form.hasMessage = !(video.details ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        form.voiceEnabled = false
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
            && hasMessage == other.hasMessage
            && audioEnabled == other.audioEnabled
            && musicEnabled == other.musicEnabled
            && voiceEnabled == other.voiceEnabled
            && voiceProfile == other.voiceProfile
            && voiceTone == other.voiceTone
            && movementDirection == other.movementDirection
            && visualDirectionMode == other.visualDirectionMode
            && visualDirectionTemplateId == other.visualDirectionTemplateId
            && animationDirection.trimmingCharacters(in: .whitespacesAndNewlines) == other.animationDirection.trimmingCharacters(in: .whitespacesAndNewlines)
            && startsWithSourcePhoto == other.startsWithSourcePhoto
    }
}

enum AnimateVisualDirectionMode: String, Codable, Equatable {
    case none
    case template
    case custom
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
