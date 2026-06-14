import AccountAV
import Foundation

@MainActor
protocol AVAccountService {
    var isAvailable: Bool { get }
    var providerSessionUser: AccountAVUser? { get }

    func restoreSession() async -> AccountAVSessionRestoreResult
    func getToken() async throws -> String?
    func signInWithApple() async throws
    func signInWithGoogle() async throws
    func signOut() async throws
}

enum AVAccountServiceError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        switch self {
        case .unavailable:
            L10n.string("account.error.unavailable")
        }
    }
}

struct DefaultAVAccountService: AVAccountService {
    private let accountService = ClerkAccountAVService(
        publishableKeyProvider: { AppConfig.avAccountKey },
        keychainServiceProvider: { Bundle.main.accountAVNonEmptyStringValue(for: "ACCOUNTAV_KEYCHAIN_SERVICE") },
        keychainAccessGroupProvider: { Bundle.main.accountAVNonEmptyStringValue(for: "ACCOUNTAV_KEYCHAIN_ACCESS_GROUP") },
        fallbackDisplayName: L10n.string("account.displayName.user"),
        loggerSubsystem: "com.avalsys.animateav"
    )

    var isAvailable: Bool {
        if Self.uiTestAccountUser != nil { return true }
        return accountService.isAvailable
    }

    var providerSessionUser: AccountAVUser? {
        if let uiTestAccountUser = Self.uiTestAccountUser {
            return uiTestAccountUser
        }
        return accountService.providerSessionUser
    }

    func restoreSession() async -> AccountAVSessionRestoreResult {
        if let uiTestAccountUser = Self.uiTestAccountUser {
            return .active(uiTestAccountUser)
        }
        return await accountService.restoreSession()
    }

    func getToken() async throws -> String? {
        if Self.uiTestAccountUser != nil {
            return nil
        }
        return try await accountService.getToken()
    }

    func signInWithApple() async throws {
        guard isAvailable else { throw AVAccountServiceError.unavailable }
        try await accountService.signInWithApple()
    }

    func signInWithGoogle() async throws {
        guard isAvailable else { throw AVAccountServiceError.unavailable }
        try await accountService.signInWithGoogle()
    }

    func signOut() async throws {
        if Self.uiTestAccountUser != nil { return }
        guard isAvailable else { return }
        try await accountService.signOut()
    }

    private static var uiTestAccountUser: AccountAVUser? {
        guard AnimateUITestEnvironment.current.hasAccountOverride else { return nil }

        return AccountAVUser(
            id: AnimateUITestEnvironment.accountUserId,
            displayName: AnimateUITestEnvironment.accountUserDisplayName,
            emailAddress: AnimateUITestEnvironment.accountUserEmailAddress
        )
    }
}

private extension Bundle {
    func accountAVNonEmptyStringValue(for key: String) -> String? {
        let rawValue = object(forInfoDictionaryKey: key) as? String ?? ""
        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty || trimmedValue == "$(inherited)" ? nil : trimmedValue
    }
}
