import Combine
import Foundation

@MainActor
final class AnimateHomeViewModel: ObservableObject {
    @Published private(set) var momentsSummary = InProgressMomentsSummary()
    @Published private(set) var isSignedIn = false
    @Published private(set) var displayName: String?
    @Published private(set) var creditBalance = AnimateCreditBalance.empty
    @Published private(set) var creditBalanceLoadState = AnimateCreditBalanceLoadState.signedOut

    private var momentsCancellables = Set<AnyCancellable>()
    private var accountCancellables = Set<AnyCancellable>()

    func bind(to summaryProvider: any InProgressMomentsSummaryProviding) {
        momentsCancellables.removeAll()

        summaryProvider.inProgressSummaryPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] momentsSummary in
                self?.momentsSummary = momentsSummary
            }
            .store(in: &momentsCancellables)
    }

    func bind(accountStateProvider: any MomentsAccountStateProviding) {
        accountCancellables.removeAll()

        Publishers.CombineLatest4(
            accountStateProvider.isSignedInPublisher,
            accountStateProvider.displayNamePublisher,
            accountStateProvider.creditBalancePublisher,
            accountStateProvider.creditBalanceLoadStatePublisher
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] isSignedIn, displayName, creditBalance, creditBalanceLoadState in
            self?.isSignedIn = isSignedIn
            self?.displayName = displayName
            self?.creditBalance = creditBalance
            self?.creditBalanceLoadState = creditBalanceLoadState
        }
        .store(in: &accountCancellables)
    }
}
