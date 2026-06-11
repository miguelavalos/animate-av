import Combine
import Foundation

@MainActor
final class AnimateAviViewModel: ObservableObject {
    @Published private(set) var videosSummary = AnimateInProgressSummary()
    @Published private(set) var isSignedIn = false
    @Published private(set) var creditBalance = AnimateCreditBalance.empty
    @Published private(set) var creditBalanceLoadState = AnimateCreditBalanceLoadState.signedOut

    private var videosCancellables = Set<AnyCancellable>()
    private var accountCancellables = Set<AnyCancellable>()

    var presentation: AnimateAviPresentation {
        AnimateAviPresentation.make(
            isSignedIn: isSignedIn,
            videosSummary: videosSummary.videoSummary,
            creditBalance: creditBalance,
            creditBalanceLoadState: creditBalanceLoadState
        )
    }

    func bind(to summaryProvider: any AnimateInProgressSummaryProviding) {
        videosCancellables.removeAll()

        summaryProvider.inProgressSummaryPublisher
            .removeDuplicates()
            .sink { [weak self] videosSummary in
                self?.videosSummary = videosSummary.videoSummary
            }
            .store(in: &videosCancellables)
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
