import Combine
import Foundation

@MainActor
protocol InProgressMomentsSummaryProviding: AnyObject {
    var inProgressSummaryPublisher: AnyPublisher<InProgressMomentsSummary, Never> { get }
}

@MainActor
protocol InProgressMomentsViewing: InProgressMomentsSummaryProviding {
    var activeMomentPublisher: AnyPublisher<InProgressMoment?, Never> { get }
    var activeWorkspacePublisher: AnyPublisher<MomentWorkspace?, Never> { get }
    var isLoadingMomentWorkspacePublisher: AnyPublisher<Bool, Never> { get }
    var isDeletingMomentPublisher: AnyPublisher<Bool, Never> { get }
    var inProgressErrorMessagePublisher: AnyPublisher<String?, Never> { get }

    func observeMomentWorkspace(ownerUserId: String?, momentId: String?)
    func clearMomentWorkspace()
    func renameMoment(_ moment: InProgressMoment, title: String) async -> Bool
    func deleteMoment(_ moment: InProgressMoment) async -> Bool
}
