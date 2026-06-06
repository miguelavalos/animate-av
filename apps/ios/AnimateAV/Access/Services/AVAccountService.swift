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
        fallbackDisplayName: L10n.string("account.displayName.user"),
        loggerSubsystem: "app.avalsys.animateav"
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
        guard MomentsUITestEnvironment.current.hasAccountOverride else { return nil }

        return AccountAVUser(
            id: MomentsUITestEnvironment.accountUserId,
            displayName: MomentsUITestEnvironment.accountUserDisplayName,
            emailAddress: MomentsUITestEnvironment.accountUserEmailAddress
        )
    }
}
