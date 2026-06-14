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
    case timedOut

    var errorDescription: String? {
        switch self {
        case .unavailable:
            L10n.string("account.error.unavailable")
        case .timedOut:
            L10n.string("account.error.unavailable")
        }
    }
}

struct DefaultAVAccountService: AVAccountService {
    private static let restoreTimeout: Duration = .seconds(8)
    private static let tokenTimeout: Duration = .seconds(8)

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
        do {
            return try await withTimeout(Self.restoreTimeout) {
                await accountService.restoreSession()
            }
        } catch {
            return .temporarilyUnavailable(accountService.providerSessionUser)
        }
    }

    func getToken() async throws -> String? {
        if Self.uiTestAccountUser != nil {
            return nil
        }
        return try await withTimeout(Self.tokenTimeout) {
            try await accountService.getToken()
        }
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

private func withTimeout<T: Sendable>(
    _ timeout: Duration,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask {
            try await operation()
        }
        group.addTask {
            try await Task.sleep(for: timeout)
            throw AVAccountServiceError.timedOut
        }

        guard let result = try await group.next() else {
            throw AVAccountServiceError.timedOut
        }
        group.cancelAll()
        return result
    }
}

private extension Bundle {
    func accountAVNonEmptyStringValue(for key: String) -> String? {
        let rawValue = object(forInfoDictionaryKey: key) as? String ?? ""
        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty || trimmedValue == "$(inherited)" ? nil : trimmedValue
    }
}
