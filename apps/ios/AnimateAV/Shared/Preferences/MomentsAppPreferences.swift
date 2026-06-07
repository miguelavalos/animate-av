import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case catalan = "ca"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: L10n.string("language.english")
        case .spanish: L10n.string("language.spanish")
        case .french: L10n.string("language.french")
        case .german: L10n.string("language.german")
        case .catalan: L10n.string("language.catalan")
        }
    }

    var autonym: String {
        switch self {
        case .english: "English"
        case .spanish: "Español"
        case .french: "Français"
        case .german: "Deutsch"
        case .catalan: "Català"
        }
    }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    static func resolved(from rawValue: String?) -> AppLanguage {
        guard let rawValue else { return .english }
        if let exactMatch = AppLanguage(rawValue: rawValue) {
            return exactMatch
        }

        let normalized = rawValue.lowercased()
        if normalized.hasPrefix("es") { return .spanish }
        if normalized.hasPrefix("fr") { return .french }
        if normalized.hasPrefix("de") { return .german }
        if normalized.hasPrefix("ca") { return .catalan }
        return .english
    }
}

final class AppLanguageController: ObservableObject {
    @Published private(set) var currentLanguage: AppLanguage

    var locale: Locale {
        currentLanguage.locale
    }

    private let userDefaults: UserDefaults
    private let userDefaultsKey = "animateav.appLanguage"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let launchLanguage = ProcessInfo.processInfo.environment["ANIMATEAV_APP_LANGUAGE"] {
            let resolvedLanguage = AppLanguage.resolved(from: launchLanguage)
            currentLanguage = resolvedLanguage
            userDefaults.set(resolvedLanguage.rawValue, forKey: userDefaultsKey)
            return
        }

        currentLanguage = AppLanguage.resolved(
            from: userDefaults.string(forKey: userDefaultsKey) ?? Locale.preferredLanguages.first
        )
    }

    func select(_ language: AppLanguage) {
        userDefaults.set(language.rawValue, forKey: userDefaultsKey)
        guard currentLanguage != language else { return }
        currentLanguage = language
    }
}

enum L10n {
    private static let userDefaultsKey = "animateav.appLanguage"

    static var locale: Locale {
        selectedLanguage.locale
    }

    static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: bundle, value: key, comment: "")
    }

    static func string(_ key: String, _ arguments: CVarArg...) -> String {
        let format = string(key)
        guard !arguments.isEmpty else { return format }
        return String(format: format, locale: locale, arguments: arguments)
    }

    private static var bundle: Bundle {
        guard let path = Bundle.main.path(forResource: selectedLanguage.rawValue, ofType: "lproj"),
              let localizedBundle = Bundle(path: path) else {
            return .main
        }

        return localizedBundle
    }

    private static var selectedLanguage: AppLanguage {
        AppLanguage.resolved(
            from: ProcessInfo.processInfo.environment["ANIMATEAV_APP_LANGUAGE"]
                ?? UserDefaults.standard.string(forKey: userDefaultsKey)
                ?? Locale.preferredLanguages.first
        )
    }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum MomentsNewMomentStartPreference: String, CaseIterable, Identifiable {
    case askEveryTime = "ask"
    case photosOrClips = "single"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .askEveryTime: L10n.string("profile.creationPreferences.start.ask.title")
        case .photosOrClips: L10n.string("profile.creationPreferences.start.photos.title")
        }
    }

    var detail: String {
        switch self {
        case .askEveryTime: L10n.string("profile.creationPreferences.start.ask.detail")
        case .photosOrClips: L10n.string("profile.creationPreferences.start.photos.detail")
        }
    }

    var systemImage: String {
        switch self {
        case .askEveryTime: "rectangle.stack.badge.plus"
        case .photosOrClips: "photo.badge.plus"
        }
    }
}

final class AppThemeController: ObservableObject {
    @Published private(set) var currentTheme: AppTheme

    private let userDefaults: UserDefaults
    private let userDefaultsKey = "animateav.appTheme"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        currentTheme = AppTheme(rawValue: userDefaults.string(forKey: userDefaultsKey) ?? "") ?? .system
    }

    func select(_ theme: AppTheme) {
        guard currentTheme != theme else { return }
        currentTheme = theme
        userDefaults.set(theme.rawValue, forKey: userDefaultsKey)
    }
}

final class MomentsNewMomentStartController: ObservableObject {
    @Published private(set) var currentPreference: MomentsNewMomentStartPreference

    private let userDefaults: UserDefaults
    private let userDefaultsKey = "animateav.newMomentStartPreference"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        currentPreference = MomentsNewMomentStartPreference(
            rawValue: userDefaults.string(forKey: userDefaultsKey) ?? ""
        ) ?? .photosOrClips
    }

    func select(_ preference: MomentsNewMomentStartPreference) {
        guard currentPreference != preference else { return }
        currentPreference = preference
        userDefaults.set(preference.rawValue, forKey: userDefaultsKey)
    }
}
