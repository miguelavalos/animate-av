import Combine
import Foundation

@MainActor
protocol AnimateCurrentUserProviding: AnyObject {
    var currentUserId: String? { get }
}

@MainActor
protocol AnimateAuthTokenProviding: AnyObject {
    func currentBearerToken() async throws -> String?
}

@MainActor
protocol AnimateCreditBalanceProviding: AnyObject {
    var currentCreditBalance: AnimateCreditBalance { get }

    func refreshCreditBalance() async
}

@MainActor
protocol AnimateAccountStateProviding: AnyObject {
    var isSignedInPublisher: AnyPublisher<Bool, Never> { get }
    var currentUserIdPublisher: AnyPublisher<String?, Never> { get }
    var displayNamePublisher: AnyPublisher<String?, Never> { get }
    var creditBalancePublisher: AnyPublisher<AnimateCreditBalance, Never> { get }
    var creditBalanceLoadStatePublisher: AnyPublisher<AnimateCreditBalanceLoadState, Never> { get }
    var canUseAnimateImageGenerationPublisher: AnyPublisher<Bool, Never> { get }
}

extension AnimateAccountStateProviding {
    var canUseAnimateImageGenerationPublisher: AnyPublisher<Bool, Never> {
        Just(false).eraseToAnyPublisher()
    }
}

@MainActor
protocol AnimateAuthenticationControlling: AnyObject {
    var isAuthenticationBusy: Bool { get }
    var isAuthenticationAvailable: Bool { get }

    func signInWithApple() async throws
    func signInWithGoogle() async throws
}
