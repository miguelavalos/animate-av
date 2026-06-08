import Combine
import Foundation

@MainActor
final class AnimateHomeViewModel: ObservableObject {
    @Published private(set) var videosSummary = AnimateInProgressSummary()
    @Published private(set) var isSignedIn = false
    @Published private(set) var displayName: String?
    @Published private(set) var creditBalance = AnimateCreditBalance.empty
    @Published private(set) var creditBalanceLoadState = AnimateCreditBalanceLoadState.signedOut

    private var videosCancellables = Set<AnyCancellable>()
    private var accountCancellables = Set<AnyCancellable>()

    func bind(to summaryProvider: any AnimateInProgressSummaryProviding) {
        videosCancellables.removeAll()

        summaryProvider.inProgressSummaryPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] videosSummary in
                self?.videosSummary = videosSummary
            }
            .store(in: &videosCancellables)
    }

    func bind(accountStateProvider: any AnimateAccountStateProviding) {
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
