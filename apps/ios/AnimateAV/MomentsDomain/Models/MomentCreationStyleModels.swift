import Foundation

enum MomentMusicPreset: String, CaseIterable, Identifiable {
    case warm
    case fun
    case cinematic
    case calm
    case upbeat

    var id: String { rawValue }

    var title: String {
        switch self {
        case .warm: L10n.string("create.music.warm.title")
        case .fun: L10n.string("create.music.fun.title")
        case .cinematic: L10n.string("create.music.cinematic.title")
        case .calm: L10n.string("create.music.calm.title")
        case .upbeat: L10n.string("create.music.upbeat.title")
        }
    }

    var subtitle: String {
        switch self {
        case .warm: L10n.string("create.music.warm.subtitle")
        case .fun: L10n.string("create.music.fun.subtitle")
        case .cinematic: L10n.string("create.music.cinematic.subtitle")
        case .calm: L10n.string("create.music.calm.subtitle")
        case .upbeat: L10n.string("create.music.upbeat.subtitle")
        }
    }

    var assetName: String {
        switch self {
        case .warm: "MoodWarm"
        case .fun: "MoodFun"
        case .cinematic: "MoodCinematic"
        case .calm: "MoodCalm"
        case .upbeat: "MoodUpbeat"
        }
    }
}

enum MomentLook: String, CaseIterable, Identifiable, Codable {
    case anime
    case cartoon
    case comic
    case clay

    var id: String { rawValue }

    static var selectorOrder: [MomentLook] {
        [.cartoon, .anime, .comic, .clay]
    }

    var title: String {
        switch self {
        case .anime: L10n.string("create.look.anime.title")
        case .cartoon: L10n.string("create.look.cartoon.title")
        case .comic: L10n.string("create.look.comic.title")
        case .clay: L10n.string("create.look.clay.title")
        }
    }

    var subtitle: String {
        switch self {
        case .anime: L10n.string("create.look.anime.subtitle")
        case .cartoon: L10n.string("create.look.cartoon.subtitle")
        case .comic: L10n.string("create.look.comic.subtitle")
        case .clay: L10n.string("create.look.clay.subtitle")
        }
    }

    var assetName: String {
        switch self {
        case .anime: "LookAnime"
        case .cartoon: "LookCartoon"
        case .comic: "LookComic"
        case .clay: "LookClay"
        }
    }

    var systemImage: String {
        switch self {
        case .anime: "sparkles"
        case .cartoon: "face.smiling.fill"
        case .comic: "text.bubble.fill"
        case .clay: "cube.fill"
        }
    }

}

enum MomentCreationMode: String, CaseIterable, Identifiable, Codable {
    case quick

    var id: String { rawValue }
}

enum MomentMediaUse: String, CaseIterable, Identifiable, Codable {
    case aviPick
    case useAll

    var id: String { rawValue }
}

enum MomentDuration: String, CaseIterable, Identifiable, Codable {
    case auto
    case short
    case standard
    case extended

    static var allCases: [MomentDuration] { [.short, .standard, .extended] }

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: L10n.string("create.duration.auto.title")
        case .short: L10n.string("create.duration.short.title")
        case .standard: L10n.string("create.duration.standard.title")
        case .extended: L10n.string("create.duration.extended.title")
        }
    }

    var subtitle: String {
        switch self {
        case .auto: L10n.string("create.duration.auto.subtitle")
        case .short: L10n.string("create.duration.short.subtitle")
        case .standard: L10n.string("create.duration.standard.subtitle")
        case .extended: L10n.string("create.duration.extended.subtitle")
        }
    }

    var assetName: String {
        switch self {
        case .auto: "LengthAuto"
        case .short: "LengthShort"
        case .standard: "LengthStandard"
        case .extended: "LengthExtended"
        }
    }
}

enum MomentCreationStyleID: String, CaseIterable, Identifiable {
    case celebration
    case eventRecap
    case travel
    case favoritePeople
    case birthday
    case familyMoments
    case softRoast
    case milestone

    var id: String { rawValue }
}

struct MomentCreationStyle: Identifiable, Equatable {
    let id: MomentCreationStyleID
    let title: String
    let subtitle: String
    let assetName: String
    let template: MomentTemplate
    let defaultMusic: MomentMusicPreset
    let allowedMusic: [MomentMusicPreset]
    let tone: MomentSetupTone
    let tempo: MomentSetupTempo
    let isEnabled: Bool

    var durationSeconds: Int { 15 }
    var creditCost: Int { 1 }
    var minimumAssets: Int { 1 }
    var recommendedAssets: ClosedRange<Int> { 1...1 }
    var maximumAssets: Int { 1 }

    static var launchStyles: [MomentCreationStyle] { [
        MomentCreationStyle(
            id: .celebration,
            title: L10n.string("create.theme.celebration.title"),
            subtitle: L10n.string("create.theme.celebration.subtitle"),
            assetName: "StyleCelebration",
            template: .birthdayMessage,
            defaultMusic: .warm,
            allowedMusic: [.warm, .fun, .cinematic, .calm],
            tone: .warm,
            tempo: .balanced,
            isEnabled: true
        ),
        MomentCreationStyle(
            id: .eventRecap,
            title: L10n.string("create.theme.eventRecap.title"),
            subtitle: L10n.string("create.theme.eventRecap.subtitle"),
            assetName: "StyleEventRecap",
            template: .partyRecap,
            defaultMusic: .fun,
            allowedMusic: [.fun, .warm, .cinematic, .calm],
            tone: .playful,
            tempo: .upbeat,
            isEnabled: true
        ),
        MomentCreationStyle(
            id: .travel,
            title: L10n.string("create.theme.travel.title"),
            subtitle: L10n.string("create.theme.travel.subtitle"),
            assetName: "StyleTravel",
            template: .birthdayMessage,
            defaultMusic: .cinematic,
            allowedMusic: [.cinematic, .warm, .fun, .calm],
            tone: .cinematic,
            tempo: .gentle,
            isEnabled: true
        ),
        MomentCreationStyle(
            id: .favoritePeople,
            title: L10n.string("create.theme.favoritePeople.title"),
            subtitle: L10n.string("create.theme.favoritePeople.subtitle"),
            assetName: "StyleFavoritePeople",
            template: .birthdayMessage,
            defaultMusic: .warm,
            allowedMusic: [.warm, .cinematic, .fun, .calm],
            tone: .warm,
            tempo: .gentle,
            isEnabled: true
        ),
        MomentCreationStyle(
            id: .birthday,
            title: L10n.string("create.theme.birthday.title"),
            subtitle: L10n.string("create.theme.birthday.subtitle"),
            assetName: "StyleBirthday",
            template: .birthdayMessage,
            defaultMusic: .warm,
            allowedMusic: [.warm, .fun, .cinematic, .calm],
            tone: .warm,
            tempo: .balanced,
            isEnabled: true
        ),
        MomentCreationStyle(
            id: .familyMoments,
            title: L10n.string("create.theme.familyMoments.title"),
            subtitle: L10n.string("create.theme.familyMoments.subtitle"),
            assetName: "StyleFamilyMoments",
            template: .birthdayMessage,
            defaultMusic: .warm,
            allowedMusic: [.warm, .fun, .cinematic, .calm],
            tone: .warm,
            tempo: .gentle,
            isEnabled: true
        ),
        MomentCreationStyle(
            id: .softRoast,
            title: L10n.string("create.theme.softRoast.title"),
            subtitle: L10n.string("create.theme.softRoast.subtitle"),
            assetName: "StyleSoftRoast",
            template: .softRoast,
            defaultMusic: .fun,
            allowedMusic: [.fun, .warm, .cinematic, .calm],
            tone: .playful,
            tempo: .upbeat,
            isEnabled: true
        ),
        MomentCreationStyle(
            id: .milestone,
            title: L10n.string("create.theme.milestone.title"),
            subtitle: L10n.string("create.theme.milestone.subtitle"),
            assetName: "StyleMilestone",
            template: .birthdayMessage,
            defaultMusic: .warm,
            allowedMusic: [.warm, .fun, .cinematic, .calm],
            tone: .warm,
            tempo: .balanced,
            isEnabled: true
        )
    ] }
}
