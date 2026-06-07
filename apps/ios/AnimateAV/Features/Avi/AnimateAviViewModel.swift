import Combine
import Foundation

@MainActor
final class AnimateAviViewModel: ObservableObject {
    @Published private(set) var momentsSummary = InProgressMomentsSummary()
    @Published private(set) var isSignedIn = false
    @Published private(set) var creditBalance = AnimateCreditBalance.empty
    @Published private(set) var creditBalanceLoadState = AnimateCreditBalanceLoadState.signedOut

    private var momentsCancellables = Set<AnyCancellable>()
    private var accountCancellables = Set<AnyCancellable>()

    var presentation: AnimateAviPresentation {
        AnimateAviPresentation.make(
            isSignedIn: isSignedIn,
            momentsSummary: momentsSummary,
            creditBalance: creditBalance,
            creditBalanceLoadState: creditBalanceLoadState
        )
    }

    func bind(to summaryProvider: any InProgressMomentsSummaryProviding) {
        momentsCancellables.removeAll()

        summaryProvider.inProgressSummaryPublisher
            .removeDuplicates()
            .sink { [weak self] momentsSummary in
                self?.momentsSummary = momentsSummary
            }
            .store(in: &momentsCancellables)
    }

    func bind(accountStateProvider: any AnimateAccountStateProviding) {
        accountCancellables.removeAll()

        Publishers.CombineLatest3(
            accountStateProvider.isSignedInPublisher,
            accountStateProvider.creditBalancePublisher,
            accountStateProvider.creditBalanceLoadStatePublisher
        )
        .sink { [weak self] isSignedIn, creditBalance, creditBalanceLoadState in
            self?.isSignedIn = isSignedIn
            self?.creditBalance = creditBalance
            self?.creditBalanceLoadState = creditBalanceLoadState
        }
        .store(in: &accountCancellables)
    }
}
