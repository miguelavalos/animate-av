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
    case childGirl
    case childBoy
    case teenGirl
    case teenBoy
    case adultWoman
    case adultMan
    case elderWoman
    case elderMan

    var id: String { rawValue }

    static var selectorOrder: [AnimateVideoVoiceProfile] {
        [
            .childGirl,
            .childBoy,
            .teenGirl,
            .teenBoy,
            .adultWoman,
            .adultMan,
            .elderWoman,
            .elderMan
        ]
    }

    var title: String {
        switch self {
        case .childGirl: L10n.string("create.voiceProfile.childGirl.title")
        case .childBoy: L10n.string("create.voiceProfile.childBoy.title")
        case .teenGirl: L10n.string("create.voiceProfile.teenGirl.title")
        case .teenBoy: L10n.string("create.voiceProfile.teenBoy.title")
        case .adultWoman: L10n.string("create.voiceProfile.adultWoman.title")
        case .adultMan: L10n.string("create.voiceProfile.adultMan.title")
        case .elderWoman: L10n.string("create.voiceProfile.elderWoman.title")
        case .elderMan: L10n.string("create.voiceProfile.elderMan.title")
        }
    }

    var detail: String {
        switch self {
        case .childGirl: L10n.string("create.voiceProfile.childGirl.detail")
        case .childBoy: L10n.string("create.voiceProfile.childBoy.detail")
        case .teenGirl: L10n.string("create.voiceProfile.teenGirl.detail")
        case .teenBoy: L10n.string("create.voiceProfile.teenBoy.detail")
        case .adultWoman: L10n.string("create.voiceProfile.adultWoman.detail")
        case .adultMan: L10n.string("create.voiceProfile.adultMan.detail")
        case .elderWoman: L10n.string("create.voiceProfile.elderWoman.detail")
        case .elderMan: L10n.string("create.voiceProfile.elderMan.detail")
        }
    }

    var portraitAssetName: String {
        switch self {
        case .childGirl: "VoiceChildGirl"
        case .childBoy: "VoiceChildBoy"
        case .teenGirl: "VoiceTeenGirl"
        case .teenBoy: "VoiceTeenBoy"
        case .adultWoman: "VoiceAdultWoman"
        case .adultMan: "VoiceAdultMan"
        case .elderWoman: "VoiceElderWoman"
        case .elderMan: "VoiceElderMan"
        }
    }

    var avatarSystemImage: String {
        switch self {
        case .childGirl, .teenGirl, .adultWoman, .elderWoman: "person.fill"
        case .childBoy, .teenBoy, .adultMan, .elderMan: "person.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .childGirl: Color(red: 0.95, green: 0.42, blue: 0.58)
        case .childBoy: Color(red: 0.30, green: 0.58, blue: 0.92)
        case .teenGirl: Color(red: 0.72, green: 0.40, blue: 0.88)
        case .teenBoy: Color(red: 0.23, green: 0.68, blue: 0.64)
        case .adultWoman: Color(red: 0.88, green: 0.48, blue: 0.28)
        case .adultMan: Color(red: 0.35, green: 0.52, blue: 0.84)
        case .elderWoman: Color(red: 0.62, green: 0.56, blue: 0.78)
        case .elderMan: Color(red: 0.52, green: 0.62, blue: 0.46)
        }
    }

    var skinColor: Color {
        switch self {
        case .childGirl: Color(red: 0.78, green: 0.50, blue: 0.35)
        case .childBoy: Color(red: 0.93, green: 0.71, blue: 0.50)
        case .teenGirl: Color(red: 0.40, green: 0.25, blue: 0.18)
        case .teenBoy: Color(red: 0.69, green: 0.42, blue: 0.28)
        case .adultWoman: Color(red: 0.86, green: 0.62, blue: 0.43)
        case .adultMan: Color(red: 0.34, green: 0.22, blue: 0.16)
        case .elderWoman: Color(red: 0.74, green: 0.55, blue: 0.42)
        case .elderMan: Color(red: 0.90, green: 0.72, blue: 0.58)
        }
    }

    var hairColor: Color {
        switch self {
        case .childGirl: Color(red: 0.20, green: 0.10, blue: 0.06)
        case .childBoy: Color(red: 0.67, green: 0.42, blue: 0.18)
        case .teenGirl: Color(red: 0.08, green: 0.07, blue: 0.07)
        case .teenBoy: Color(red: 0.14, green: 0.10, blue: 0.08)
        case .adultWoman: Color(red: 0.36, green: 0.18, blue: 0.08)
        case .adultMan: Color(red: 0.04, green: 0.04, blue: 0.04)
        case .elderWoman, .elderMan: Color(red: 0.82, green: 0.82, blue: 0.78)
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
    var occasion = "Character intro"
    var recipient = ""
    var tone: AnimateVideoSetupTone = .warm
    var tempo: AnimateVideoSetupTempo = .balanced
    var details = ""
    var hasMessage = false
    var audioEnabled = true
    var musicEnabled = true
    var voiceEnabled = false
    var voiceProfile: AnimateVideoVoiceProfile = .adultWoman
    var voiceTone: AnimateVideoVoiceTone = .warm

    var activeMessageText: String? {
        guard hasMessage else { return nil }
        let trimmed = details.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    var activeVoiceProfile: AnimateVideoVoiceProfile? {
        guard hasMessage, audioEnabled, voiceEnabled, activeMessageText != nil else { return nil }
        return voiceProfile
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
        form.voiceEnabled = form.hasMessage
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
