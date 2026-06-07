import Combine
import Foundation

@MainActor
protocol AnimateInProgressSummaryProviding: AnyObject {
    var inProgressSummaryPublisher: AnyPublisher<AnimateInProgressSummary, Never> { get }
}

@MainActor
protocol AnimateVideosViewing: AnimateInProgressSummaryProviding {
    var activeVideoPublisher: AnyPublisher<AnimateVideo?, Never> { get }
    var activeWorkspacePublisher: AnyPublisher<AnimateWorkspace?, Never> { get }
    var isLoadingAnimateWorkspacePublisher: AnyPublisher<Bool, Never> { get }
    var isDeletingVideoPublisher: AnyPublisher<Bool, Never> { get }
    var inProgressErrorMessagePublisher: AnyPublisher<String?, Never> { get }

    func observeAnimateWorkspace(ownerUserId: String?, momentId: String?)
    func clearAnimateWorkspace()
    func renameVideo(_ video: AnimateVideo, title: String) async -> Bool
    func deleteVideo(_ video: AnimateVideo) async -> Bool
}
