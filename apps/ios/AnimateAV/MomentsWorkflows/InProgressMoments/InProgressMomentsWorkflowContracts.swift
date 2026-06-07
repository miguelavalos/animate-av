import Combine
import Foundation

@MainActor
protocol AnimateInProgressSummaryProviding: AnyObject {
    var inProgressSummaryPublisher: AnyPublisher<AnimateInProgressSummary, Never> { get }
}

@MainActor
protocol AnimateVideosViewing: AnimateInProgressSummaryProviding {
    var activeMomentPublisher: AnyPublisher<AnimateVideo?, Never> { get }
    var activeWorkspacePublisher: AnyPublisher<AnimateWorkspace?, Never> { get }
    var isLoadingAnimateWorkspacePublisher: AnyPublisher<Bool, Never> { get }
    var isDeletingMomentPublisher: AnyPublisher<Bool, Never> { get }
    var inProgressErrorMessagePublisher: AnyPublisher<String?, Never> { get }

    func observeAnimateWorkspace(ownerUserId: String?, momentId: String?)
    func clearAnimateWorkspace()
    func renameMoment(_ moment: AnimateVideo, title: String) async -> Bool
    func deleteMoment(_ moment: AnimateVideo) async -> Bool
}
