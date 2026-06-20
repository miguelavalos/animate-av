import AVAppShellFoundation
import Foundation

struct AnimateLaunchContext {
    enum Tab: String {
        case home
        case create
        case createImage
        case inProgress
        case avi
    }

    let isUITesting: Bool
    let shouldDisableSplash: Bool
    let preferredTab: Tab?

    static let current = AnimateLaunchContext(environment: ProcessInfo.processInfo.environment)

    init(environment: [String: String]) {
        let settings = AnimateLaunchSettings.merged(environment: environment)
        isUITesting = settings["ANIMATEAV_UI_TESTS"] == "1"
        shouldDisableSplash = isUITesting || settings["ANIMATEAV_DISABLE_SPLASH"] == "1"
        preferredTab = settings["ANIMATEAV_OPEN_TAB"].flatMap(Tab.init(rawValue:))
    }
}

struct AnimateUITestEnvironment {
    let environment: [String: String]

    static let current = AnimateUITestEnvironment(environment: ProcessInfo.processInfo.environment)

    private var settings: [String: String] {
        AnimateLaunchSettings.merged(environment: environment)
    }

    var isEnabled: Bool {
        settings["ANIMATEAV_UI_TESTS"] == "1"
    }

    var accountMode: String? {
        guard isEnabled else { return nil }
        return settings["ANIMATEAV_UI_TESTS_ACCOUNT_MODE"]
    }

    var createFixture: String? {
        guard isEnabled else { return nil }
        return settings["ANIMATEAV_CREATE_FIXTURE"]
    }

    var initialChromeItem: AVAppShellChromeItem? {
        guard isEnabled else { return nil }
        switch settings["ANIMATEAV_UI_TESTS_INITIAL_CHROME"] {
        case "account":
            return .account
        case "accountSafety":
            return .account
        case "settings":
            return .settings
        default:
            return nil
        }
    }

    var showsAccountSafetyOnly: Bool {
        guard isEnabled else { return false }
        return settings["ANIMATEAV_UI_TESTS_INITIAL_CHROME"] == "accountSafety"
    }

    var hasAccountOverride: Bool {
        accountMode != nil
    }

    static let accountUserId = "animate-ui-test-user"
    static let accountUserDisplayName = "Animate UI Test User"
    static let accountUserEmailAddress = "animate-ui-test@example.test"
}

enum AnimateLaunchSettings {
    static func merged(environment: [String: String]) -> [String: String] {
        var settings = environment
        let arguments = CommandLine.arguments.dropFirst()
        var index = arguments.startIndex
        while index < arguments.endIndex {
            let argument = arguments[index]
            if let separatorIndex = argument.firstIndex(of: "=") {
                let key = String(argument[..<separatorIndex]).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
                let value = String(argument[argument.index(after: separatorIndex)...])
                if !key.isEmpty {
                    settings[key] = value
                }
            } else if argument.hasPrefix("-") {
                let key = String(argument.drop(while: { $0 == "-" }))
                let nextIndex = arguments.index(after: index)
                if nextIndex < arguments.endIndex, !arguments[nextIndex].hasPrefix("-") {
                    settings[key] = arguments[nextIndex]
                    index = nextIndex
                }
            }
            index = arguments.index(after: index)
        }
        return settings
    }
}
