import Combine
import Foundation

@MainActor
protocol MomentsCurrentUserProviding: AnyObject {
    var currentUserId: String? { get }
}

@MainActor
protocol MomentsAuthTokenProviding: AnyObject {
    func currentBearerToken() async throws -> String?
}

@MainActor
protocol AnimateCreditBalanceProviding: AnyObject {
    var currentCreditBalance: AnimateCreditBalance { get }

    func refreshCreditBalance() async
}

@MainActor
protocol MomentsAccountStateProviding: AnyObject {
    var isSignedInPublisher: AnyPublisher<Bool, Never> { get }
    var currentUserIdPublisher: AnyPublisher<String?, Never> { get }
    var displayNamePublisher: AnyPublisher<String?, Never> { get }
    var creditBalancePublisher: AnyPublisher<AnimateCreditBalance, Never> { get }
    var creditBalanceLoadStatePublisher: AnyPublisher<AnimateCreditBalanceLoadState, Never> { get }
}

@MainActor
protocol MomentsAuthenticationControlling: AnyObject {
    var isAuthenticationBusy: Bool { get }
    var isAuthenticationAvailable: Bool { get }

    func signInWithApple() async throws
    func signInWithGoogle() async throws
}
