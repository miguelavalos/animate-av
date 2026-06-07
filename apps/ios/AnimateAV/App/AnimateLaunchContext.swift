import Foundation

struct AnimateLaunchContext {
    enum Tab: String {
        case home
        case create
        case inProgress
        case avi
    }

    let isUITesting: Bool
    let shouldDisableSplash: Bool
    let preferredTab: Tab?

    static let current = AnimateLaunchContext(environment: ProcessInfo.processInfo.environment)

    init(environment: [String: String]) {
        isUITesting = environment["ANIMATEAV_UI_TESTS"] == "1"
        shouldDisableSplash = isUITesting || environment["ANIMATEAV_DISABLE_SPLASH"] == "1"
        preferredTab = environment["ANIMATEAV_OPEN_TAB"].flatMap(Tab.init(rawValue:))
    }
}

struct MomentsUITestEnvironment {
    let environment: [String: String]

    static let current = MomentsUITestEnvironment(environment: ProcessInfo.processInfo.environment)

    var isEnabled: Bool {
        environment["ANIMATEAV_UI_TESTS"] == "1"
    }

    var accountMode: String? {
        guard isEnabled else { return nil }
        return environment["ANIMATEAV_UI_TESTS_ACCOUNT_MODE"]
    }

    var createFixture: String? {
        guard isEnabled else { return nil }
        return environment["ANIMATEAV_CREATE_FIXTURE"]
    }

    var hasAccountOverride: Bool {
        accountMode != nil
    }

    static let accountUserId = "animate-ui-test-user"
    static let accountUserDisplayName = "Animate UI Test User"
    static let accountUserEmailAddress = "animate-ui-test@example.test"
}
