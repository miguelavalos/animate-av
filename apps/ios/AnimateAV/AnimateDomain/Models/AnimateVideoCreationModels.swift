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

    var id: String { rawValue }

    static var selectorOrder: [AnimateVideoLook] {
        [
            .cartoon,
            .anime,
            .cinematic3d,
            .watercolor,
            .comic,
            .manga,
            .clay,
            .paperCut,
            .plush,
            .sticker,
            .pixel,
            .neon,
            .storybook,
            .yellowComedy,
            .soft3d,
            .darkFantasy,
            .vintagePoster,
            .pencilSketch,
            .editorialCaricature,
            .euroComic,
            .americanComic,
            .stopMotion,
            .blackWhiteManga,
            .toyFigure,
            .chibi,
            .flatVector,
            .pastelDream,
            .heroicComic,
            .noirInk,
            .rubberHose,
            .fantasyQuest,
            .miniAvatar
        ]
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
        switch self {
        case .anime: L10n.string("create.look.anime.title")
        case .cartoon: L10n.string("create.look.cartoon.title")
        case .comic: L10n.string("create.look.comic.title")
        case .clay: L10n.string("create.look.clay.title")
        case .watercolor: L10n.string("create.look.watercolor.title")
        case .cinematic3d: L10n.string("create.look.cinematic3d.title")
        case .manga: L10n.string("create.look.manga.title")
        case .paperCut: L10n.string("create.look.paperCut.title")
        case .plush: L10n.string("create.look.plush.title")
        case .sticker: L10n.string("create.look.sticker.title")
        case .pixel: L10n.string("create.look.pixel.title")
        case .neon: L10n.string("create.look.neon.title")
        case .storybook: L10n.string("create.look.storybook.title")
        case .yellowComedy: L10n.string("create.look.yellowComedy.title")
        case .soft3d: L10n.string("create.look.soft3d.title")
        case .darkFantasy: L10n.string("create.look.darkFantasy.title")
        case .vintagePoster: L10n.string("create.look.vintagePoster.title")
        case .pencilSketch: L10n.string("create.look.pencilSketch.title")
        case .editorialCaricature: L10n.string("create.look.editorialCaricature.title")
        case .euroComic: L10n.string("create.look.euroComic.title")
        case .americanComic: L10n.string("create.look.americanComic.title")
        case .stopMotion: L10n.string("create.look.stopMotion.title")
        case .blackWhiteManga: L10n.string("create.look.blackWhiteManga.title")
        case .toyFigure: L10n.string("create.look.toyFigure.title")
        case .chibi: L10n.string("create.look.chibi.title")
        case .flatVector: L10n.string("create.look.flatVector.title")
        case .pastelDream: L10n.string("create.look.pastelDream.title")
        case .heroicComic: L10n.string("create.look.heroicComic.title")
        case .noirInk: L10n.string("create.look.noirInk.title")
        case .rubberHose: L10n.string("create.look.rubberHose.title")
        case .fantasyQuest: L10n.string("create.look.fantasyQuest.title")
        case .miniAvatar: L10n.string("create.look.miniAvatar.title")
        }
    }

    var subtitle: String {
        switch self {
        case .anime: L10n.string("create.look.anime.subtitle")
        case .cartoon: L10n.string("create.look.cartoon.subtitle")
        case .comic: L10n.string("create.look.comic.subtitle")
        case .clay: L10n.string("create.look.clay.subtitle")
        case .watercolor: L10n.string("create.look.watercolor.subtitle")
        case .cinematic3d: L10n.string("create.look.cinematic3d.subtitle")
        case .manga: L10n.string("create.look.manga.subtitle")
        case .paperCut: L10n.string("create.look.paperCut.subtitle")
        case .plush: L10n.string("create.look.plush.subtitle")
        case .sticker: L10n.string("create.look.sticker.subtitle")
        case .pixel: L10n.string("create.look.pixel.subtitle")
        case .neon: L10n.string("create.look.neon.subtitle")
        case .storybook: L10n.string("create.look.storybook.subtitle")
        case .yellowComedy: L10n.string("create.look.yellowComedy.subtitle")
        case .soft3d: L10n.string("create.look.soft3d.subtitle")
        case .darkFantasy: L10n.string("create.look.darkFantasy.subtitle")
        case .vintagePoster: L10n.string("create.look.vintagePoster.subtitle")
        case .pencilSketch: L10n.string("create.look.pencilSketch.subtitle")
        case .editorialCaricature: L10n.string("create.look.editorialCaricature.subtitle")
        case .euroComic: L10n.string("create.look.euroComic.subtitle")
        case .americanComic: L10n.string("create.look.americanComic.subtitle")
        case .stopMotion: L10n.string("create.look.stopMotion.subtitle")
        case .blackWhiteManga: L10n.string("create.look.blackWhiteManga.subtitle")
        case .toyFigure: L10n.string("create.look.toyFigure.subtitle")
        case .chibi: L10n.string("create.look.chibi.subtitle")
        case .flatVector: L10n.string("create.look.flatVector.subtitle")
        case .pastelDream: L10n.string("create.look.pastelDream.subtitle")
        case .heroicComic: L10n.string("create.look.heroicComic.subtitle")
        case .noirInk: L10n.string("create.look.noirInk.subtitle")
        case .rubberHose: L10n.string("create.look.rubberHose.subtitle")
        case .fantasyQuest: L10n.string("create.look.fantasyQuest.subtitle")
        case .miniAvatar: L10n.string("create.look.miniAvatar.subtitle")
        }
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
        }
    }

    var systemImage: String {
        switch self {
        case .anime: "sparkles"
        case .cartoon: "face.smiling.fill"
        case .comic: "text.bubble.fill"
        case .clay: "cube.fill"
        case .watercolor: "paintbrush.pointed.fill"
        case .cinematic3d: "camera.aperture"
        case .manga: "bolt.fill"
        case .paperCut: "scissors"
        case .plush: "heart.fill"
        case .sticker: "seal.fill"
        case .pixel: "square.grid.3x3.fill"
        case .neon: "wand.and.stars"
        case .storybook: "book.closed.fill"
        case .yellowComedy: "face.smiling.inverse"
        case .soft3d: "sparkles.rectangle.stack.fill"
        case .darkFantasy: "moon.stars.fill"
        case .vintagePoster: "photo.artframe"
        case .pencilSketch: "pencil.tip"
        case .editorialCaricature: "person.crop.square.filled.and.at.rectangle"
        case .euroComic: "bubble.left.and.text.bubble.right.fill"
        case .americanComic: "burst.fill"
        case .stopMotion: "camera.fill"
        case .blackWhiteManga: "circle.lefthalf.filled"
        case .toyFigure: "figure.stand"
        case .chibi: "face.smiling.fill"
        case .flatVector: "square.on.circle.fill"
        case .pastelDream: "cloud.sun.fill"
        case .heroicComic: "shield.lefthalf.filled"
        case .noirInk: "drop.fill"
        case .rubberHose: "hands.sparkles.fill"
        case .fantasyQuest: "wand.and.stars.inverse"
        case .miniAvatar: "person.crop.circle.fill"
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
