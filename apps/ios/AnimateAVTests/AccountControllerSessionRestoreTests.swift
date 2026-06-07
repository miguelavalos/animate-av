import AccountAV
import Foundation
import XCTest
@testable import AnimateAV

@MainActor
final class AccountControllerSessionRestoreTests: XCTestCase {
    override func tearDown() {
        AccountControllerURLProtocol.reset()
        super.tearDown()
    }

    func testTemporarilyUnavailableSessionPreservesCurrentUser() async {
        let user = AccountAVUser(id: "user-1", displayName: "User One", emailAddress: "user@example.com")
        AccountControllerURLProtocol.profileUser = user
        let accountService = StubAVAccountService(user: user)
        let controller = AccountController(
            service: accountService,
            accountProfileClient: accountProfileClient(),
            balanceClient: balanceClient(),
            purchaseService: StubAnimatePurchaseService(),
            userDefaults: isolatedUserDefaults()
        )
        await controller.syncFromAccountProvider()
        accountService.restoreResult = .temporarilyUnavailable(nil)

        await controller.syncFromAccountProvider()

        XCTAssertTrue(controller.isSignedIn)
        XCTAssertEqual(controller.currentUserId, user.id)
        XCTAssertTrue(controller.isAccountSessionTemporarilyUnavailable)
        XCTAssertFalse(accountService.didSignOut)
    }

    func testLastKnownUserPreservesColdStartDuringTemporarySessionFailure() async {
        let userDefaults = isolatedUserDefaults()
        let user = AccountAVUser(id: "cached-user", displayName: "Cached User", emailAddress: "cached@example.com")
        AccountControllerURLProtocol.profileUser = user
        let signedInController = AccountController(
            service: StubAVAccountService(user: user),
            accountProfileClient: accountProfileClient(),
            balanceClient: balanceClient(),
            purchaseService: StubAnimatePurchaseService(),
            userDefaults: userDefaults
        )
        await signedInController.syncFromAccountProvider()

        let restoredController = AccountController(
            service: StubAVAccountService(user: nil, restoreResult: .temporarilyUnavailable(nil)),
            accountProfileClient: accountProfileClient(),
            balanceClient: balanceClient(),
            purchaseService: StubAnimatePurchaseService(),
            userDefaults: userDefaults
        )
        await restoredController.syncFromAccountProvider()

        XCTAssertTrue(restoredController.isSignedIn)
        XCTAssertEqual(restoredController.currentUserId, user.id)
        XCTAssertTrue(restoredController.isAccountSessionTemporarilyUnavailable)
    }

    func testConfirmedSignedOutClearsLastKnownUser() async {
        let userDefaults = isolatedUserDefaults()
        let user = AccountAVUser(id: "signed-out-user", displayName: "Signed Out User", emailAddress: nil)
        AccountControllerURLProtocol.profileUser = user
        let signedInController = AccountController(
            service: StubAVAccountService(user: user),
            accountProfileClient: accountProfileClient(),
            balanceClient: balanceClient(),
            purchaseService: StubAnimatePurchaseService(),
            userDefaults: userDefaults
        )
        await signedInController.syncFromAccountProvider()

        let signedOutController = AccountController(
            service: StubAVAccountService(user: nil, restoreResult: .signedOut),
            accountProfileClient: accountProfileClient(),
            balanceClient: balanceClient(),
            purchaseService: StubAnimatePurchaseService(),
            userDefaults: userDefaults
        )
        await signedOutController.syncFromAccountProvider()

        XCTAssertFalse(signedOutController.isSignedIn)
        XCTAssertNil(signedOutController.currentUserId)
        XCTAssertFalse(signedOutController.isAccountSessionTemporarilyUnavailable)
    }

    func testManualSignOutClearsLastKnownUser() async throws {
        let userDefaults = isolatedUserDefaults()
        AccountControllerURLProtocol.profileUser = AccountAVUser(id: "manual-user", displayName: "Manual User", emailAddress: nil)
        let accountService = StubAVAccountService(
            user: AccountAVUser(id: "manual-user", displayName: "Manual User", emailAddress: nil)
        )
        let controller = AccountController(
            service: accountService,
            accountProfileClient: accountProfileClient(),
            balanceClient: balanceClient(),
            purchaseService: StubAnimatePurchaseService(),
            userDefaults: userDefaults
        )
        await controller.syncFromAccountProvider()

        controller.signOut()
        try await Task.sleep(nanoseconds: 50_000_000)

        let restoredController = AccountController(
            service: StubAVAccountService(user: nil, restoreResult: .temporarilyUnavailable(nil)),
            accountProfileClient: accountProfileClient(),
            balanceClient: balanceClient(),
            purchaseService: StubAnimatePurchaseService(),
            userDefaults: userDefaults
        )

        XCTAssertFalse(restoredController.isSignedIn)
        XCTAssertNil(restoredController.currentUserId)
        XCTAssertTrue(accountService.didSignOut)
    }

    func testActiveProviderSessionPublishesInternalAccountUserId() async {
        let providerUser = AccountAVUser(
            id: "user_3DLceydoveFCDDoCV1ndJz2H0C2",
            displayName: "Clerk User",
            emailAddress: "user@example.com"
        )
        let internalUser = AccountAVUser(
            id: "63d0a87f-4ab1-4d6c-ab66-7abee9432ec9",
            displayName: "Account AV User",
            emailAddress: "user@example.com"
        )
        AccountControllerURLProtocol.profileUser = internalUser
        let controller = AccountController(
            service: StubAVAccountService(user: providerUser),
            accountProfileClient: accountProfileClient(),
            balanceClient: balanceClient(),
            purchaseService: StubAnimatePurchaseService(),
            userDefaults: isolatedUserDefaults()
        )

        await controller.syncFromAccountProvider()

        XCTAssertTrue(controller.isSignedIn)
        XCTAssertEqual(controller.currentUserId, internalUser.id)
        XCTAssertNotEqual(controller.currentUserId, providerUser.id)
    }

    func testPurchasesUseInternalAccountUserId() async throws {
        let providerUser = AccountAVUser(
            id: "user_clerk_subject",
            displayName: "Clerk User",
            emailAddress: "user@example.com"
        )
        let internalUser = AccountAVUser(
            id: "appsav-internal-user-id",
            displayName: "Account AV User",
            emailAddress: "user@example.com"
        )
        let purchaseService = CapturingAnimatePurchaseService()
        AccountControllerURLProtocol.profileUser = internalUser
        let controller = AccountController(
            service: StubAVAccountService(user: providerUser),
            accountProfileClient: accountProfileClient(),
            balanceClient: balanceClient(),
            purchaseService: purchaseService,
            userDefaults: isolatedUserDefaults()
        )

        await controller.syncFromAccountProvider()
        await controller.loadPurchaseProducts()
        _ = try await controller.purchase(.starterPack)
        _ = try await controller.restorePurchases()

        XCTAssertEqual(purchaseService.loadedCatalogUserIds, [internalUser.id])
        XCTAssertEqual(purchaseService.purchaseUserIds, [internalUser.id])
        XCTAssertEqual(purchaseService.restoreUserIds, [internalUser.id])
        XCTAssertFalse(purchaseService.loadedCatalogUserIds.contains(providerUser.id))
        XCTAssertFalse(purchaseService.purchaseUserIds.contains(providerUser.id))
        XCTAssertFalse(purchaseService.restoreUserIds.contains(providerUser.id))
    }

    func testActiveProviderSessionDoesNotPublishProviderIdWhenProfileFails() async {
        let providerUser = AccountAVUser(
            id: "user_clerk_subject",
            displayName: "Clerk User",
            emailAddress: "user@example.com"
        )
        AccountControllerURLProtocol.profileStatusCode = 500
        let controller = AccountController(
            service: StubAVAccountService(user: providerUser),
            accountProfileClient: accountProfileClient(),
            balanceClient: balanceClient(),
            purchaseService: StubAnimatePurchaseService(),
            userDefaults: isolatedUserDefaults()
        )

        await controller.syncFromAccountProvider()

        XCTAssertFalse(controller.isSignedIn)
        XCTAssertNil(controller.currentUserId)
        XCTAssertTrue(controller.isAccountSessionTemporarilyUnavailable)
    }

    func testActiveProviderSessionDoesNotPublishProviderIdWithoutToken() async {
        let providerUser = AccountAVUser(
            id: "user_clerk_without_token",
            displayName: "Clerk User",
            emailAddress: "user@example.com"
        )
        let controller = AccountController(
            service: StubAVAccountService(user: providerUser, token: nil),
            accountProfileClient: accountProfileClient(),
            balanceClient: balanceClient(),
            purchaseService: StubAnimatePurchaseService(),
            userDefaults: isolatedUserDefaults()
        )

        await controller.syncFromAccountProvider()

        XCTAssertFalse(controller.isSignedIn)
        XCTAssertNil(controller.currentUserId)
        XCTAssertTrue(controller.isAccountSessionTemporarilyUnavailable)
    }

    private func accountProfileClient() -> AnimateAccountProfileClient {
        AnimateAccountProfileClient(baseURLString: "https://account.example.test", session: urlProtocolSession())
    }

    private func balanceClient() -> AnimateCreditBalanceClient {
        AnimateCreditBalanceClient(baseURLString: "https://account.example.test", session: urlProtocolSession())
    }

    private func urlProtocolSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [AccountControllerURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func isolatedUserDefaults() -> UserDefaults {
        let suiteName = "AnimateAVTests.AccountController.\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}

@MainActor
private final class StubAVAccountService: AVAccountService {
    private var storedUser: AccountAVUser?
    private let token: String?
    var restoreResult: AccountAVSessionRestoreResult?
    private(set) var didSignOut = false

    init(user: AccountAVUser?, token: String? = "test-token", restoreResult: AccountAVSessionRestoreResult? = nil) {
        self.storedUser = user
        self.token = token
        self.restoreResult = restoreResult
    }

    var isAvailable: Bool { true }
    var providerSessionUser: AccountAVUser? { storedUser }

    func restoreSession() async -> AccountAVSessionRestoreResult {
        if let restoreResult {
            return restoreResult
        }
        guard let storedUser else { return .signedOut }
        return .active(storedUser)
    }

    func getToken() async throws -> String? {
        token
    }

    func signInWithApple() async throws {}
    func signInWithGoogle() async throws {}

    func signOut() async throws {
        didSignOut = true
        storedUser = nil
    }
}

@MainActor
private struct StubAnimatePurchaseService: AnimatePurchaseServicing {
    func loadCatalog(userId: String) async throws -> AnimatePurchaseCatalog {
        .empty
    }

    func purchase(productId: String, userId: String) async throws -> AnimatePurchaseResult {
        AnimatePurchaseResult(status: .cancelled, productId: productId, transactionId: nil)
    }

    func restorePurchases(userId: String) async throws -> AnimatePurchaseResult {
        AnimatePurchaseResult(status: .cancelled, productId: nil, transactionId: nil)
    }

    func logOut() async {}
}

@MainActor
private final class CapturingAnimatePurchaseService: AnimatePurchaseServicing {
    private(set) var loadedCatalogUserIds: [String] = []
    private(set) var purchaseUserIds: [String] = []
    private(set) var restoreUserIds: [String] = []

    func loadCatalog(userId: String) async throws -> AnimatePurchaseCatalog {
        loadedCatalogUserIds.append(userId)
        return AnimatePurchaseCatalog(
            entriesByProductId: [
                AnimateCreditPaywallProduct.starterPack.id: AnimatePurchaseCatalog.Entry(
                    productId: AnimateCreditPaywallProduct.starterPack.id,
                    packageIdentifier: "test-five-credits",
                    localizedTitle: "Five credits",
                    localizedPrice: "$5.00"
                )
            ]
        )
    }

    func purchase(productId: String, userId: String) async throws -> AnimatePurchaseResult {
        purchaseUserIds.append(userId)
        return AnimatePurchaseResult(status: .cancelled, productId: productId, transactionId: nil)
    }

    func restorePurchases(userId: String) async throws -> AnimatePurchaseResult {
        restoreUserIds.append(userId)
        return AnimatePurchaseResult(status: .cancelled, productId: nil, transactionId: nil)
    }

    func logOut() async {}
}

private final class AccountControllerURLProtocol: URLProtocol {
    nonisolated(unsafe) static var profileUser = AccountAVUser(id: "user-1", displayName: "User One", emailAddress: "user@example.com")
    nonisolated(unsafe) static var profileStatusCode = 200

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        let path = request.url?.path ?? ""
        let statusCode = path == "/v1/me" ? Self.profileStatusCode : 200
        let responseJSON = Self.responseJSON(for: path)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(responseJSON.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func reset() {
        profileUser = AccountAVUser(id: "user-1", displayName: "User One", emailAddress: "user@example.com")
        profileStatusCode = 200
    }

    private static func responseJSON(for path: String) -> String {
        if path == "/v1/me" {
            if profileStatusCode == 200 {
                return """
                {
                  "user": {
                    "id": "\(profileUser.id)",
                    "displayName": "\(profileUser.displayName)",
                    "email": "\(profileUser.emailAddress ?? "")"
                  }
                }
                """
            }
            return """
            {
              "error": {
                "code": "account_profile_failed",
                "message": "Account profile could not be loaded."
              }
            }
            """
        }

        return """
        {
          "proMonthlyCredits": 10,
          "promotionalGrantedCredits": 0,
          "purchasedCredits": 0,
          "watermarkRemovalCreditCost": 1,
          "watermarkFreeIncluded": true
        }
        """
    }
}
