import AccountAV
import AVDiagnosticsFoundation
import Foundation

@MainActor
enum AppConfig {
    static var avAccountKey: String {
        Bundle.main.object(forInfoDictionaryKey: "ACCOUNTAV_PUBLISHABLE_KEY") as? String ?? ""
    }

    static var isAVAccountAvailable: Bool {
        !avAccountKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static var diagnosticsConfiguration: AVDiagnosticsConfiguration {
        AVDiagnosticsConfiguration(
            dsn: diagnosticsDSN,
            environment: diagnosticsEnvironment,
            releaseName: diagnosticsReleaseName,
            tracesSampleRate: 0,
            isEnabled: isDiagnosticsEnabled
        )
    }

    static var revenueCatPublicAPIKey: String {
        configuredString(for: "ANIMATEAV_REVENUECAT_PUBLIC_API_KEY", fallback: "")
    }

    static var revenueCatOfferingID: String {
        configuredString(for: "ANIMATEAV_REVENUECAT_OFFERING_ID", fallback: "animate_credits")
    }

    static var revenueCatMonthlyPackageID: String {
        configuredString(for: "ANIMATEAV_REVENUECAT_MONTHLY_PACKAGE_ID", fallback: "$rc_monthly")
    }

    static var animateConvexURL: String {
        Bundle.main.object(forInfoDictionaryKey: "ANIMATEAV_CONVEX_URL") as? String ?? ""
    }

    static var animateAPIBaseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "ACCOUNTAV_API_BASE_URL") as? String ?? ""
    }

    static var supportURL: URL {
        configuredSupportURL(
            explicitURL: configuredOptionalURL(for: "SUPPORTAV_BASE_URL"),
            email: configuredOptionalString(for: "SUPPORT_EMAIL_TO") ?? "support@avalsys.com"
        ) ?? URL(string: "https://support-av.avalsys.com/")!
    }

    static var privacyPolicyURL: URL {
        configuredURL(for: "ANIMATEAV_PRIVACY_URL", fallback: "https://animate-av.avalsys.com/privacy")
    }

    static var termsURL: URL {
        configuredURL(for: "ANIMATEAV_TERMS_URL", fallback: "https://animate-av.avalsys.com/terms")
    }

    static var accountDeletionURL: URL {
        configuredURL(for: "ACCOUNTAV_DELETE_ACCOUNT_URL", fallback: "https://account.avalsys.com/account/delete")
    }

    static var openSourceURL: URL {
        configuredURL(for: "ANIMATEAV_OPEN_SOURCE_URL", fallback: "https://github.com/avalsys/animate-av")
    }

    static func configureAVAccountIfPossible() {
        AccountAVClerk.configureIfPossible(publishableKey: avAccountKey)
    }

    private static var diagnosticsEnvironment: AVDiagnosticsEnvironment {
        switch configuredString(for: "ANIMATEAV_CONFIG_ENVIRONMENT", fallback: "dev").lowercased() {
        case "prod", "production":
            return .production
        case "staging", "preview":
            return .preview
        case "dev", "debug":
            return .debug
        default:
            return .debug
        }
    }

    private static var diagnosticsReleaseName: String? {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.avalsys.animateav"
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "0"
        return "\(bundleIdentifier)@\(version)+\(build)"
    }

    private static var diagnosticsDSN: String {
        configuredString(for: "ANIMATEAV_IOS_SENTRY_DSN", fallback: "")
    }

    private static var isDiagnosticsEnabled: Bool {
        #if DEBUG
        isDebugDiagnosticsOverrideEnabled && !diagnosticsDSN.isEmpty
        #else
        !diagnosticsDSN.isEmpty
        #endif
    }

    private static var isDebugDiagnosticsOverrideEnabled: Bool {
        configuredBoolean(for: "ANIMATEAV_ENABLE_DEBUG_DIAGNOSTICS")
    }

    private static func configuredURL(for key: String, fallback: String) -> URL {
        let trimmedValue = configuredString(for: key, fallback: fallback)
        return URL(string: trimmedValue.isEmpty ? fallback : trimmedValue) ?? URL(string: fallback)!
    }

    private static func configuredOptionalURL(for key: String) -> URL? {
        guard let rawValue = configuredOptionalString(for: key) else {
            return nil
        }
        return URL(string: rawValue)
    }

    private static func configuredString(for key: String, fallback: String) -> String {
        configuredOptionalString(for: key) ?? fallback
    }

    private static func configuredOptionalString(for key: String) -> String? {
        let rawValue = ProcessInfo.processInfo.environment[key]
            ?? Bundle.main.object(forInfoDictionaryKey: key) as? String
            ?? ""
        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty || trimmedValue == "$(inherited)" ? nil : trimmedValue
    }

    private static func configuredBoolean(for key: String) -> Bool {
        guard let rawValue = configuredOptionalString(for: key)?.lowercased() else {
            return false
        }

        return rawValue == "1" || rawValue == "true" || rawValue == "yes"
    }

    private static func configuredSupportURL(explicitURL: URL?, email: String?) -> URL? {
        if let explicitURL {
            return explicitURL
        }
        guard let email else { return nil }
        let encodedSubject = "Animate AV Support".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Animate%20AV%20Support"
        return URL(string: "mailto:\(email)?subject=\(encodedSubject)")
    }
}
