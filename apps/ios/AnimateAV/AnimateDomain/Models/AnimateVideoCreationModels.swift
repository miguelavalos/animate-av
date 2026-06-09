import Foundation

enum AnimateVideoMusicPreset: String, CaseIterable, Identifiable {
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

struct AnimateVideoLookFamily: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let looks: [AnimateVideoLook]
    let heroAssetName: String
    let systemImage: String
}

enum AnimateVideoLook: String, CaseIterable, Identifiable, Codable {
    case anime
    case cartoon
    case comic
    case clay
    case watercolor
    case cinematic3d
    case manga
    case paperCut
    case plush
    case sticker
    case pixel
    case neon
    case storybook
    case yellowComedy
    case soft3d
    case darkFantasy
    case vintagePoster
    case pencilSketch
    case editorialCaricature
    case euroComic
    case americanComic
    case stopMotion
    case blackWhiteManga
    case toyFigure
    case chibi
    case flatVector
    case pastelDream
    case heroicComic
    case noirInk
    case rubberHose
    case fantasyQuest
    case miniAvatar
    case kawaiiPop
    case graphicNovel
    case sundayStrip
    case inkWash
    case shonenAction
    case cozySliceOfLife
    case magicalFantasyAnime
    case cyberAnime
    case shojoRomance
    case superDeformed
    case animeWatercolor
    case charcoal
    case oilPainting
    case inkMarker
    case crayonKids
    case acrylicPoster
    case lowPoly
    case voxelWorld
    case synthwave
    case glitchArt
    case isometricGame
    case sciFiSpace
    case steampunk
    case pirateStory
    case fairytale
    case mythicEpic
    case feltCraft
    case collageCutout
    case cardboardTheater
    case origami
    case stainedGlass
    case embroideredTextile

    var id: String { rawValue }

    static var families: [AnimateVideoLookFamily] {
        [
            family(
                id: "popular",
                looks: [.cartoon, .anime, .cinematic3d, .comic, .manga, .clay, .watercolor, .paperCut],
                heroAssetName: "LookCartoon",
                systemImage: "sparkles"
            ),
            family(
                id: "cuteSocial",
                looks: [.plush, .sticker, .chibi, .miniAvatar, .toyFigure, .soft3d, .kawaiiPop, .rubberHose],
                heroAssetName: "LookPlush",
                systemImage: "heart.fill"
            ),
            family(
                id: "comicsInk",
                looks: [.americanComic, .euroComic, .heroicComic, .noirInk, .editorialCaricature, .graphicNovel, .sundayStrip, .inkWash],
                heroAssetName: "LookComic",
                systemImage: "text.bubble.fill"
            ),
            family(
                id: "animeManga",
                looks: [.shonenAction, .cozySliceOfLife, .magicalFantasyAnime, .cyberAnime, .blackWhiteManga, .shojoRomance, .superDeformed, .animeWatercolor],
                heroAssetName: "LookAnime",
                systemImage: "bolt.fill"
            ),
            family(
                id: "paintedHandmade",
                looks: [.pencilSketch, .charcoal, .oilPainting, .pastelDream, .storybook, .inkMarker, .crayonKids, .acrylicPoster],
                heroAssetName: "LookWatercolor",
                systemImage: "paintbrush.pointed.fill"
            ),
            family(
                id: "digitalGame",
                looks: [.pixel, .neon, .flatVector, .lowPoly, .voxelWorld, .synthwave, .glitchArt, .isometricGame],
                heroAssetName: "LookPixel",
                systemImage: "gamecontroller.fill"
            ),
            family(
                id: "fantasyWorlds",
                looks: [.fantasyQuest, .darkFantasy, .sciFiSpace, .steampunk, .pirateStory, .fairytale, .mythicEpic, .yellowComedy],
                heroAssetName: "LookFantasyQuest",
                systemImage: "wand.and.stars"
            ),
            family(
                id: "craftTexture",
                looks: [.stopMotion, .feltCraft, .collageCutout, .cardboardTheater, .origami, .stainedGlass, .embroideredTextile, .vintagePoster],
                heroAssetName: "LookStopMotion",
                systemImage: "scissors"
            )
        ]
    }

    static var selectorOrder: [AnimateVideoLook] {
        families.flatMap(\.looks)
    }

    static func family(containing look: AnimateVideoLook?) -> AnimateVideoLookFamily {
        guard let look,
              let family = families.first(where: { $0.looks.contains(look) }) else {
            return families[0]
        }
        return family
    }

    private static func family(
        id: String,
        looks: [AnimateVideoLook],
        heroAssetName: String,
        systemImage: String
    ) -> AnimateVideoLookFamily {
        AnimateVideoLookFamily(
            id: id,
            title: L10n.string("create.look.family.\(id).title"),
            subtitle: L10n.string("create.look.family.\(id).subtitle"),
            looks: looks,
            heroAssetName: heroAssetName,
            systemImage: systemImage
        )
    }

    var defaultVoiceProfile: AnimateVideoVoiceProfile {
        guard let lookIndex = Self.selectorOrder.firstIndex(of: self) else {
            return .adultWoman
        }

        let voiceOrder = AnimateVideoVoiceProfile.selectorOrder
        guard !voiceOrder.isEmpty else {
            return .adultWoman
        }

        return voiceOrder[lookIndex % voiceOrder.count]
    }

    var title: String {
        L10n.string("create.look.\(rawValue).title")
    }

    var subtitle: String {
        L10n.string("create.look.\(rawValue).subtitle")
    }

    var assetName: String {
        switch self {
        case .anime: "LookAnime"
        case .cartoon: "LookCartoon"
        case .comic: "LookComic"
        case .clay: "LookClay"
        case .watercolor: "LookWatercolor"
        case .cinematic3d: "LookCinematic3d"
        case .manga: "LookManga"
        case .paperCut: "LookPaperCut"
        case .plush: "LookPlush"
        case .sticker: "LookSticker"
        case .pixel: "LookPixel"
        case .neon: "LookNeon"
        case .storybook: "LookStorybook"
        case .yellowComedy: "LookYellowComedy"
        case .soft3d: "LookSoft3d"
        case .darkFantasy: "LookDarkFantasy"
        case .vintagePoster: "LookVintagePoster"
        case .pencilSketch: "LookPencilSketch"
        case .editorialCaricature: "LookEditorialCaricature"
        case .euroComic: "LookEuroComic"
        case .americanComic: "LookAmericanComic"
        case .stopMotion: "LookStopMotion"
        case .blackWhiteManga: "LookBlackWhiteManga"
        case .toyFigure: "LookToyFigure"
        case .chibi: "LookChibi"
        case .flatVector: "LookFlatVector"
        case .pastelDream: "LookPastelDream"
        case .heroicComic: "LookHeroicComic"
        case .noirInk: "LookNoirInk"
        case .rubberHose: "LookRubberHose"
        case .fantasyQuest: "LookFantasyQuest"
        case .miniAvatar: "LookMiniAvatar"
        case .kawaiiPop: "LookKawaiiPop"
        case .graphicNovel: "LookGraphicNovel"
        case .sundayStrip: "LookSundayStrip"
        case .inkWash: "LookInkWash"
        case .shonenAction: "LookShonenAction"
        case .cozySliceOfLife: "LookCozySliceOfLife"
        case .magicalFantasyAnime: "LookMagicalFantasyAnime"
        case .cyberAnime: "LookCyberAnime"
        case .shojoRomance: "LookShojoRomance"
        case .superDeformed: "LookSuperDeformed"
        case .animeWatercolor: "LookAnimeWatercolor"
        case .charcoal: "LookCharcoal"
        case .oilPainting: "LookOilPainting"
        case .inkMarker: "LookInkMarker"
        case .crayonKids: "LookCrayonKids"
        case .acrylicPoster: "LookAcrylicPoster"
        case .lowPoly: "LookLowPoly"
        case .voxelWorld: "LookVoxelWorld"
        case .synthwave: "LookSynthwave"
        case .glitchArt: "LookGlitchArt"
        case .isometricGame: "LookIsometricGame"
        case .sciFiSpace: "LookSciFiSpace"
        case .steampunk: "LookSteampunk"
        case .pirateStory: "LookPirateStory"
        case .fairytale: "LookFairytale"
        case .mythicEpic: "LookMythicEpic"
        case .feltCraft: "LookFeltCraft"
        case .collageCutout: "LookCollageCutout"
        case .cardboardTheater: "LookCardboardTheater"
        case .origami: "LookOrigami"
        case .stainedGlass: "LookStainedGlass"
        case .embroideredTextile: "LookEmbroideredTextile"
        }
    }

    var systemImage: String {
        switch self {
        case .anime, .shonenAction, .cozySliceOfLife, .magicalFantasyAnime,
             .cyberAnime, .shojoRomance, .superDeformed, .animeWatercolor:
            "sparkles"
        case .cartoon, .rubberHose:
            "face.smiling.fill"
        case .comic, .americanComic, .euroComic, .heroicComic,
             .graphicNovel, .sundayStrip:
            "text.bubble.fill"
        case .clay, .soft3d, .toyFigure, .lowPoly, .voxelWorld:
            "cube.fill"
        case .watercolor, .pastelDream, .oilPainting,
             .acrylicPoster:
            "paintbrush.pointed.fill"
        case .cinematic3d:
            "camera.aperture"
        case .manga, .blackWhiteManga:
            "bolt.fill"
        case .paperCut, .collageCutout, .cardboardTheater, .origami:
            "scissors"
        case .plush, .kawaiiPop, .feltCraft, .embroideredTextile:
            "heart.fill"
        case .sticker:
            "seal.fill"
        case .pixel, .flatVector, .isometricGame:
            "square.grid.3x3.fill"
        case .neon, .synthwave:
            "wand.and.stars"
        case .storybook, .fairytale:
            "book.closed.fill"
        case .yellowComedy, .chibi, .miniAvatar:
            "person.crop.circle.fill"
        case .darkFantasy, .fantasyQuest, .sciFiSpace, .steampunk, .pirateStory,
             .mythicEpic:
            "moon.stars.fill"
        case .vintagePoster:
            "photo.artframe"
        case .pencilSketch, .charcoal, .inkMarker, .crayonKids:
            "pencil.tip"
        case .editorialCaricature:
            "person.crop.square.filled.and.at.rectangle"
        case .stopMotion:
            "camera.fill"
        case .noirInk, .inkWash, .glitchArt, .stainedGlass:
            "drop.fill"
        }
    }

}

enum AnimateVideoCreationMode: String, CaseIterable, Identifiable, Codable {
    case quick

    var id: String { rawValue }
}

enum AnimateVideoMediaUse: String, CaseIterable, Identifiable, Codable {
    case aviPick
    case useAll

    var id: String { rawValue }
}

enum AnimateVideoDuration: String, CaseIterable, Identifiable, Codable {
    case auto

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: L10n.string("create.duration.auto.title")
        }
    }

    var subtitle: String {
        switch self {
        case .auto: L10n.string("create.duration.auto.subtitle")
        }
    }
}

enum AnimateVideoCreationStyleID: String, CaseIterable, Identifiable {
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

struct AnimateVideoCreationStyle: Identifiable, Equatable {
    let id: AnimateVideoCreationStyleID
    let title: String
    let subtitle: String
    let assetName: String
    let template: AnimateVideoTemplate
    let defaultMusic: AnimateVideoMusicPreset
    let allowedMusic: [AnimateVideoMusicPreset]
    let tone: AnimateVideoSetupTone
    let tempo: AnimateVideoSetupTempo
    let isEnabled: Bool

    var durationSeconds: Int { 15 }
    var creditCost: Int { 1 }
    var minimumAssets: Int { 1 }
    var recommendedAssets: ClosedRange<Int> { 1...1 }
    var maximumAssets: Int { 1 }

    static var launchStyles: [AnimateVideoCreationStyle] { [
        AnimateVideoCreationStyle(
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
        AnimateVideoCreationStyle(
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
        AnimateVideoCreationStyle(
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
        AnimateVideoCreationStyle(
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
        AnimateVideoCreationStyle(
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
        AnimateVideoCreationStyle(
            id: .familyMoments,
            title: L10n.string("create.theme.familyMoments.title"),
            subtitle: L10n.string("create.theme.familyMoments.subtitle"),
            assetName: "StyleFamilyCartoon",
            template: .birthdayMessage,
            defaultMusic: .warm,
            allowedMusic: [.warm, .fun, .cinematic, .calm],
            tone: .warm,
            tempo: .gentle,
            isEnabled: true
        ),
        AnimateVideoCreationStyle(
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
        AnimateVideoCreationStyle(
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
