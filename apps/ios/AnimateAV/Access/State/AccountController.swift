import AccountAV
import AVDiagnosticsFoundation
import AuthenticationServices
import Combine
import Foundation

@MainActor
final class AccountController: ObservableObject {
    @Published private(set) var user: AccountAVUser?
    @Published private(set) var creditBalance = AnimateCreditBalance.empty
    @Published private(set) var creditBalanceLoadState = AnimateCreditBalanceLoadState.signedOut
    @Published private(set) var purchaseCatalog = AnimatePurchaseCatalog.empty
    @Published private(set) var isPurchaseCatalogLoading = false
    @Published private(set) var purchaseCatalogErrorMessage: String?
    @Published private(set) var isPurchaseInProgress = false
    @Published private(set) var isAccountSessionTemporarilyUnavailable = false
    @Published private(set) var isBusy = false
    @Published var errorMessage: String?

    private let service: AVAccountService
    private let accountProfileClient: AnimateAccountProfileClient
    private let balanceClient: AnimateCreditBalanceClient
    private let promoCodeClient: AnimatePromoCodeClient
    private let purchaseService: AnimatePurchaseServicing
    private let userDefaults: UserDefaults
    private let lastKnownAccountUserKey = "animateav.account.lastKnownUser"

    init(
        service: AVAccountService = DefaultAVAccountService(),
        accountProfileClient: AnimateAccountProfileClient? = nil,
        balanceClient: AnimateCreditBalanceClient? = nil,
        promoCodeClient: AnimatePromoCodeClient? = nil,
        purchaseService: AnimatePurchaseServicing = RevenueCatAnimatePurchaseService(),
        userDefaults: UserDefaults = .standard
    ) {
        self.service = service
        self.accountProfileClient = accountProfileClient ?? AnimateAccountProfileClient(baseURLString: AppConfig.animateAPIBaseURL)
        self.balanceClient = balanceClient ?? AnimateCreditBalanceClient(baseURLString: AppConfig.animateAPIBaseURL)
        self.promoCodeClient = promoCodeClient ?? AnimatePromoCodeClient(baseURLString: AppConfig.animateAPIBaseURL)
        self.purchaseService = purchaseService
        self.userDefaults = userDefaults
        self.user = Self.lastKnownAccountUser(from: userDefaults)
        refresh()
    }

    var isAccountAvailable: Bool {
        service.isAvailable
    }

    var isSignedIn: Bool {
        user != nil
    }

    func refresh() {
        if user == nil {
            resetSignedOutAccountState()
        } else {
            persistLastKnownAccountUser(user)
            creditBalanceLoadState = .loading
            Task { await refreshCreditBalance() }
        }
    }

    func syncFromAccountProvider() async {
        addAccountBreadcrumb("restore_started")
        switch await service.restoreSession() {
        case .active(let providerUser):
            guard let resolvedUser = await resolveInternalAccountUser(providerUser: providerUser) else {
                captureAccountError(
                    AnimateAPIError(code: "moments_account_profile_resolution_failed", message: "Account profile resolution failed."),
                    operation: "restore",
                    data: ["restore_result": "active_without_internal_user"]
                )
                isAccountSessionTemporarilyUnavailable = true
                if user == nil {
                    resetSignedOutAccountState()
                }
                return
            }
            user = resolvedUser
            AVDiagnostics.setUserContext(AVDiagnosticsUserContext(id: resolvedUser.id))
            addAccountBreadcrumb("restore_active")
            isAccountSessionTemporarilyUnavailable = false
            persistLastKnownAccountUser(resolvedUser)
            await refreshCreditBalance()
        case .temporarilyUnavailable:
            addAccountBreadcrumb("restore_temporarily_unavailable")
            isAccountSessionTemporarilyUnavailable = true
            if user == nil {
                resetSignedOutAccountState()
            }
        case .signedOut, .invalidated:
            user = nil
            AVDiagnostics.clearUserContext()
            addAccountBreadcrumb("restore_signed_out")
            isAccountSessionTemporarilyUnavailable = false
            clearLastKnownAccountUser()
            resetSignedOutAccountState()
        }
    }

    func signInWithApple() async throws {
        addAccountBreadcrumb("sign_in_started", data: ["provider": "apple"])
        try await runAuthOperation {
            try await service.signInWithApple()
        }
    }

    func signInWithGoogle() async throws {
        addAccountBreadcrumb("sign_in_started", data: ["provider": "google"])
        try await runAuthOperation {
            try await service.signInWithGoogle()
        }
    }

    func signOut() {
        addAccountBreadcrumb("sign_out_started")
        startAuthTask { [self] in
            try await self.service.signOut()
            await self.purchaseService.logOut()
            self.user = nil
            AVDiagnostics.clearUserContext()
            self.addAccountBreadcrumb("sign_out_completed")
            self.isAccountSessionTemporarilyUnavailable = false
            self.clearLastKnownAccountUser()
            self.resetSignedOutAccountState()
        }
    }

    func claimPromotionCode(_ code: String) async throws -> Int {
        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let user, !normalizedCode.isEmpty else { return 0 }

        guard let token = try await currentBackendBearerToken(for: user) else {
            throw AnimateAPIError(code: "moments_auth_token_missing", message: L10n.string("access.signInRequired.generic"))
        }
        let response = try await promoCodeClient.redeem(code: normalizedCode, bearerToken: token)
        creditBalance = response.balance
        creditBalanceLoadState = .loaded
        return response.creditsGranted
    }

    func loadPurchaseProducts() async {
        guard let user else {
            purchaseCatalog = .empty
            purchaseCatalogErrorMessage = nil
            return
        }

        isPurchaseCatalogLoading = true
        purchaseCatalogErrorMessage = nil
        defer { isPurchaseCatalogLoading = false }

        do {
            purchaseCatalog = try await purchaseService.loadCatalog(userId: user.id)
        } catch {
            purchaseCatalog = .empty
            purchaseCatalogErrorMessage = L10n.string("paywall.purchasesUnavailable")
        }
    }

    func purchase(_ product: AnimateCreditPaywallProduct) async throws -> AnimatePurchaseResult {
        guard let user else {
            throw AnimateAPIError(code: "moments_sign_in_required", message: L10n.string("access.signInRequired.purchase"))
        }
        guard !isPurchaseInProgress else {
            return AnimatePurchaseResult(status: .cancelled, productId: product.id, transactionId: nil)
        }

        isPurchaseInProgress = true
        defer { isPurchaseInProgress = false }

        let result = try await purchaseService.purchase(productId: product.id, userId: user.id)
        if result.status == .purchased {
            await refreshCreditBalanceAfterBillingEvent()
        }
        return result
    }

    func restorePurchases() async throws -> AnimatePurchaseResult {
        guard let user else {
            throw AnimateAPIError(code: "animate_sign_in_required", message: L10n.string("access.signInRequired.restore"))
        }
        guard !isPurchaseInProgress else {
            return AnimatePurchaseResult(status: .cancelled, productId: nil, transactionId: nil)
        }

        isPurchaseInProgress = true
        defer { isPurchaseInProgress = false }

        let result = try await purchaseService.restorePurchases(userId: user.id)
        await refreshCreditBalanceAfterBillingEvent()
        return result
    }

    func refreshCreditBalance() async {
        guard let user else {
            resetSignedOutAccountState()
            return
        }

        creditBalanceLoadState = .loading
        do {
            guard let token = try await currentBackendBearerToken(for: user) else {
                throw AnimateAPIError(code: "moments_auth_token_missing", message: L10n.string("access.signInRequired.generic"))
            }
            creditBalance = try await balanceClient.fetchBalance(bearerToken: token)
            creditBalanceLoadState = .loaded
            isAccountSessionTemporarilyUnavailable = false
            persistLastKnownAccountUser(user)
        } catch {
            captureAccountError(error, operation: "credit_balance")
            creditBalanceLoadState = AnimateCreditBalanceLoadState.failureState(for: error)
            errorMessage = error.localizedDescription
        }
    }

    func currentBearerToken() async throws -> String? {
        guard let user else { return nil }
        return try await currentBackendBearerToken(for: user)
    }

    private func refreshCreditBalanceAfterBillingEvent() async {
        await refreshCreditBalance()
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await self?.refreshCreditBalance()
        }
    }

    private func resolveInternalAccountUser(providerUser: AccountAVUser) async -> AccountAVUser? {
        do {
            guard let token = try await service.getToken() else {
                return AnimateUITestEnvironment.current.hasAccountOverride ? providerUser : nil
            }
            return try await accountProfileClient.fetchCurrentUser(bearerToken: token)
        } catch {
            captureAccountError(error, operation: "profile_resolution")
            errorMessage = error.localizedDescription
            return nil
        }
    }

    private func currentBackendBearerToken(for user: AccountAVUser) async throws -> String? {
        if let token = try await service.getToken() {
            return token
        }
        if AnimateUITestEnvironment.current.hasAccountOverride {
            return user.id
        }
        return nil
    }

    private func resetSignedOutAccountState() {
        creditBalance = .empty
        creditBalanceLoadState = .signedOut
        purchaseCatalog = .empty
        purchaseCatalogErrorMessage = nil
    }

    private static func lastKnownAccountUser(from userDefaults: UserDefaults) -> AccountAVUser? {
        guard let data = userDefaults.data(forKey: "animateav.account.lastKnownUser"),
              let snapshot = try? JSONDecoder().decode(AnimateLastKnownAccountUser.self, from: data) else {
            return nil
        }
        return snapshot.accountUser
    }

    private func persistLastKnownAccountUser(_ user: AccountAVUser?) {
        guard let user else { return }
        let snapshot = AnimateLastKnownAccountUser(user: user)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        userDefaults.set(data, forKey: lastKnownAccountUserKey)
    }

    private func clearLastKnownAccountUser() {
        userDefaults.removeObject(forKey: lastKnownAccountUserKey)
    }

    private func startAuthTask(_ operation: @escaping () async throws -> Void) {
        Task {
            do {
                try await runAuthOperation(operation)
            } catch {
                // Interactive sign-in surfaces report their own errors.
            }
        }
    }

    private func runAuthOperation(_ operation: () async throws -> Void) async throws {
        guard !isBusy else { return }
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        do {
            try await operation()
            addAccountBreadcrumb("auth_operation_completed")
            await syncFromAccountProvider()
        } catch {
            guard !error.isAuthCancellation else {
                addAccountBreadcrumb("auth_operation_cancelled")
                throw error
            }
            captureAccountError(error, operation: "auth_operation")
            errorMessage = error.localizedDescription
            throw error
        }
    }

    private func addAccountBreadcrumb(_ message: String, data: [String: String] = [:]) {
        AVDiagnostics.addBreadcrumb(
            AVDiagnosticsBreadcrumb(
                category: "animate.account",
                message: message,
                data: data
            )
        )
    }

    private func captureAccountError(_ error: Error, operation: String, data: [String: String] = [:]) {
        var contextData = data
        contextData["operation"] = operation
        AVDiagnostics.capture(
            error: error,
            context: AVDiagnosticsContext(
                feature: "animate.account",
                code: diagnosticsErrorCode(for: error),
                data: contextData
            )
        )
    }

    private func diagnosticsErrorCode(for error: Error) -> String {
        if let videoError = error as? AnimateAPIError {
            return videoError.code
        }
        return String(describing: type(of: error))
    }
}

private extension Error {
    var isAuthCancellation: Bool {
        let nsError = self as NSError
        if nsError.domain == ASAuthorizationError.errorDomain,
           nsError.code == ASAuthorizationError.Code.canceled.rawValue {
            return true
        }

        if nsError.domain.contains("AuthenticationServices"),
           nsError.code == ASAuthorizationError.Code.unknown.rawValue {
            return true
        }

        if nsError.domain == ASWebAuthenticationSessionError.errorDomain,
           nsError.code == ASWebAuthenticationSessionError.Code.canceledLogin.rawValue {
            return true
        }

        if nsError.domain == NSURLErrorDomain,
           nsError.code == NSURLErrorCancelled {
            return true
        }

        let description = nsError.localizedDescription.lowercased()
        if description.contains("cancel") || description.contains("cancelad") {
            return true
        }

        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
            return underlying.isAuthCancellation
        }

        return false
    }
}

private struct AnimateLastKnownAccountUser: Codable {
    let id: String
    let displayName: String
    let emailAddress: String?

    init(user: AccountAVUser) {
        id = user.id
        displayName = user.displayName
        emailAddress = user.emailAddress
    }

    var accountUser: AccountAVUser {
        AccountAVUser(id: id, displayName: displayName, emailAddress: emailAddress)
    }
}

struct AnimateAccountProfileClient {
    var baseURLString: String
    var session: URLSession = .shared

    func fetchCurrentUser(bearerToken: String) async throws -> AccountAVUser {
        guard let url = URL(string: "\(baseURLString)/v1/me") else {
            throw AnimateAPIError(code: "invalid_account_api_url", message: L10n.string("access.apiURLMissing"))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
            throw AnimateAPIError.decode(
                from: data,
                fallbackCode: "account_profile_failed",
                fallbackMessage: "Account profile could not be loaded."
            )
        }

        let decoded = try JSONDecoder().decode(AnimateAccountProfileResponse.self, from: data)
        return AccountAVUser(
            id: decoded.user.id,
            displayName: decoded.user.displayName ?? L10n.string("account.displayName.user"),
            emailAddress: decoded.user.email ?? decoded.user.emailAddress
        )
    }
}

private struct AnimateAccountProfileResponse: Decodable {
    let user: User

    struct User: Decodable {
        let id: String
        let displayName: String?
        let email: String?
        let emailAddress: String?
    }
}

struct AnimateCreditBalanceClient {
    var baseURLString: String
    var session: URLSession = .shared

    func fetchBalance(bearerToken: String) async throws -> AnimateCreditBalance {
        guard let url = URL(string: "\(baseURLString)/v1/apps/animateav/credits/balance") else {
            throw AnimateAPIError(code: "invalid_animate_api_url", message: L10n.string("access.apiURLMissing"))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
            throw AnimateAPIError.decode(
                from: data,
                fallbackCode: "animate_credit_balance_failed",
                fallbackMessage: "Animate AV credit balance could not be loaded."
            )
        }

        let decoded = try JSONDecoder().decode(AnimateCreditBalanceResponse.self, from: data)
        return AnimateCreditBalance(
            proMonthly: decoded.proMonthlyCredits,
            promotional: decoded.promotionalGrantedCredits,
            purchased: decoded.purchasedCredits,
            availableCredits: decoded.spendableCredits,
            walletSummary: decoded.walletSummary,
            watermarkRemovalCreditCost: decoded.watermarkRemovalCreditCost,
            watermarkFreeIncluded: decoded.watermarkFreeIncluded
        )
    }
}

private struct AnimateCreditBalanceResponse: Decodable {
    let spendableCredits: Int
    let proMonthlyCredits: Int
    let promotionalGrantedCredits: Int
    let purchasedCredits: Int
    let watermarkRemovalCreditCost: Int
    let watermarkFreeIncluded: Bool
    let walletSummary: AnimateCreditWalletSummary?

    private enum CodingKeys: String, CodingKey {
        case spendableCredits
        case proMonthlyCredits
        case promotionalGrantedCredits
        case purchasedCredits
        case watermarkRemovalCreditCost
        case watermarkFreeIncluded
        case walletSummary
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        spendableCredits = try container.decode(Int.self, forKey: .spendableCredits)
        proMonthlyCredits = try container.decode(Int.self, forKey: .proMonthlyCredits)
        promotionalGrantedCredits = try container.decode(Int.self, forKey: .promotionalGrantedCredits)
        purchasedCredits = try container.decode(Int.self, forKey: .purchasedCredits)
        watermarkRemovalCreditCost = try container.decodeIfPresent(Int.self, forKey: .watermarkRemovalCreditCost) ?? 1
        watermarkFreeIncluded = try container.decodeIfPresent(Bool.self, forKey: .watermarkFreeIncluded) ?? false
        walletSummary = try container.decodeIfPresent(AnimateCreditWalletSummary.self, forKey: .walletSummary)
    }
}

struct AnimatePromoCodeClient {
    var baseURLString: String
    var session: URLSession = .shared

    func redeem(code: String, bearerToken: String) async throws -> AnimatePromoCodeRedemptionResponse {
        guard let url = URL(string: "\(baseURLString)/v1/apps/animateav/credits/promotions/redeem") else {
            throw AnimateAPIError(code: "invalid_moments_api_url", message: L10n.string("access.apiURLMissing"))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(AnimatePromoCodeRedeemRequest(code: code))

        let (data, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse, !(200..<300).contains(httpResponse.statusCode) {
            throw AnimateAPIError.decode(
                from: data,
                fallbackCode: "moments_promo_code_redeem_failed",
                fallbackMessage: "Promo code could not be redeemed."
            )
        }

        return try JSONDecoder().decode(AnimatePromoCodeRedemptionResponse.self, from: data)
    }
}

private struct AnimatePromoCodeRedeemRequest: Encodable {
    let code: String
}

struct AnimatePromoCodeRedemptionResponse: Decodable {
    let creditsGranted: Int
    let balance: AnimateCreditBalance

    private enum CodingKeys: String, CodingKey {
        case creditsGranted
        case balance
    }

    private enum BalanceCodingKeys: String, CodingKey {
        case spendableCredits
        case proMonthlyCredits
        case promotionalGrantedCredits
        case purchasedCredits
        case watermarkRemovalCreditCost
        case watermarkFreeIncluded
        case walletSummary
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        creditsGranted = try container.decode(Int.self, forKey: .creditsGranted)
        let balanceContainer = try container.nestedContainer(keyedBy: BalanceCodingKeys.self, forKey: .balance)
        balance = AnimateCreditBalance(
            proMonthly: try balanceContainer.decode(Int.self, forKey: .proMonthlyCredits),
            promotional: try balanceContainer.decode(Int.self, forKey: .promotionalGrantedCredits),
            purchased: try balanceContainer.decode(Int.self, forKey: .purchasedCredits),
            availableCredits: try balanceContainer.decodeIfPresent(Int.self, forKey: .spendableCredits),
            walletSummary: try balanceContainer.decodeIfPresent(AnimateCreditWalletSummary.self, forKey: .walletSummary),
            watermarkRemovalCreditCost: try balanceContainer.decodeIfPresent(Int.self, forKey: .watermarkRemovalCreditCost) ?? 1,
            watermarkFreeIncluded: try balanceContainer.decodeIfPresent(Bool.self, forKey: .watermarkFreeIncluded) ?? false
        )
    }
}

extension AccountController: AnimateCurrentUserProviding, AnimateAuthTokenProviding, AnimateCreditBalanceProviding, AnimateAccountStateProviding, AnimateAuthenticationControlling {
    var currentUserId: String? {
        user?.id
    }

    var currentCreditBalance: AnimateCreditBalance {
        creditBalance
    }

    var isAuthenticationBusy: Bool {
        isBusy
    }

    var isAuthenticationAvailable: Bool {
        isAccountAvailable
    }

    var isSignedInPublisher: AnyPublisher<Bool, Never> {
        $user
            .map { $0 != nil }
            .eraseToAnyPublisher()
    }

    var currentUserIdPublisher: AnyPublisher<String?, Never> {
        $user
            .map(\.?.id)
            .eraseToAnyPublisher()
    }

    var displayNamePublisher: AnyPublisher<String?, Never> {
        $user
            .map(\.?.displayName)
            .eraseToAnyPublisher()
    }

    var creditBalancePublisher: AnyPublisher<AnimateCreditBalance, Never> {
        $creditBalance.eraseToAnyPublisher()
    }

    var creditBalanceLoadStatePublisher: AnyPublisher<AnimateCreditBalanceLoadState, Never> {
        $creditBalanceLoadState.eraseToAnyPublisher()
    }
}
