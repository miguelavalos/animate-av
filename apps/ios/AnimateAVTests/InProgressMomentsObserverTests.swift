import Combine
import XCTest
@testable import AnimateAV

@MainActor
final class InProgressMomentsObserverTests: XCTestCase {
    func testMomentsObserverPublishesMomentUpdates() async throws {
        let repository = MockMomentsRepository()
        let observer = InProgressMomentsObserver(momentsRepository: repository)

        observer.observeInProgressMoments(ownerUserId: "user-1")
        let moment = makeMoment(id: "moment-1")
        repository.sendMoments([moment])
        await waitUntil { observer.moments == [moment] }

        XCTAssertEqual(observer.moments, [moment])
        XCTAssertNil(observer.errorMessage)
        XCTAssertEqual(repository.observedOwnerUserIds, ["user-1"])
    }

    func testMomentsObserverClearsStateWhenOwnerIsMissing() async {
        let repository = MockMomentsRepository()
        let observer = InProgressMomentsObserver(momentsRepository: repository)

        observer.observeInProgressMoments(ownerUserId: "user-1")
        repository.sendMoments([makeMoment(id: "moment-1")])
        await waitUntil { !observer.moments.isEmpty }

        observer.observeInProgressMoments(ownerUserId: nil)

        XCTAssertTrue(observer.moments.isEmpty)
        XCTAssertNil(observer.errorMessage)
        XCTAssertEqual(repository.observedOwnerUserIds, ["user-1"])
    }

    func testMomentsObserverPublishesObservationErrors() {
        let repository = MockMomentsRepository(momentsError: TestObservationError.moments)
        let observer = InProgressMomentsObserver(momentsRepository: repository)

        observer.observeInProgressMoments(ownerUserId: "user-1")

        XCTAssertTrue(observer.moments.isEmpty)
        XCTAssertEqual(observer.errorMessage, TestObservationError.moments.localizedDescription)
    }

    func testMomentsObserverIgnoresStaleMomentUpdatesAfterChangingOwner() async {
        let repository = MockMomentsRepository()
        let observer = InProgressMomentsObserver(momentsRepository: repository)

        observer.observeInProgressMoments(ownerUserId: "user-1")
        let firstSubject = repository.momentsSubjects[0]
        let firstMoment = makeMoment(id: "moment-1")
        firstSubject.send([firstMoment])
        await waitUntil { observer.moments == [firstMoment] }

        observer.observeInProgressMoments(ownerUserId: "user-2")
        let secondMoment = makeMoment(id: "moment-2")
        repository.sendMoments([secondMoment])
        await waitUntil { observer.moments == [secondMoment] }

        firstSubject.send([makeMoment(id: "stale-moment")])
        try? await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertEqual(observer.moments, [secondMoment])
        XCTAssertEqual(repository.observedOwnerUserIds, ["user-1", "user-2"])
    }

    func testWorkspaceObserverPublishesWorkspaceUpdates() async throws {
        let repository = MockWorkspaceRepository()
        let observer = MomentsWorkspaceObserver(momentsRepository: repository)

        observer.observeWorkspace(ownerUserId: "user-1", momentId: "moment-1")
        let workspace = makeWorkspace(moment: makeMoment(id: "moment-1"))
        repository.sendWorkspace(workspace)
        await waitUntil { observer.activeWorkspace == workspace }

        XCTAssertEqual(observer.activeWorkspace, workspace)
        XCTAssertNil(observer.errorMessage)
        XCTAssertEqual(repository.observedRequests, [
            WorkspaceRequest(ownerUserId: "user-1", momentId: "moment-1")
        ])
    }

    func testWorkspaceObserverClearsStateWhenRequestIsIncomplete() async {
        let repository = MockWorkspaceRepository()
        let observer = MomentsWorkspaceObserver(momentsRepository: repository)

        observer.observeWorkspace(ownerUserId: "user-1", momentId: "moment-1")
        repository.sendWorkspace(makeWorkspace(moment: makeMoment(id: "moment-1")))
        await waitUntil { observer.activeWorkspace != nil }

        observer.observeWorkspace(ownerUserId: "user-1", momentId: nil)

        XCTAssertNil(observer.activeWorkspace)
        XCTAssertNil(observer.errorMessage)
        XCTAssertEqual(repository.observedRequests, [
            WorkspaceRequest(ownerUserId: "user-1", momentId: "moment-1")
        ])
    }

    func testWorkspaceObserverPublishesObservationErrors() {
        let repository = MockWorkspaceRepository(workspaceError: TestObservationError.workspace)
        let observer = MomentsWorkspaceObserver(momentsRepository: repository)

        observer.observeWorkspace(ownerUserId: "user-1", momentId: "moment-1")

        XCTAssertNil(observer.activeWorkspace)
        XCTAssertEqual(observer.errorMessage, TestObservationError.workspace.localizedDescription)
    }

    func testWorkspaceObserverIgnoresStaleWorkspaceUpdatesAfterChangingMoment() async {
        let repository = MockWorkspaceRepository()
        let observer = MomentsWorkspaceObserver(momentsRepository: repository)

        observer.observeWorkspace(ownerUserId: "user-1", momentId: "moment-1")
        let firstSubject = repository.workspaceSubjects[0]
        let firstWorkspace = makeWorkspace(moment: makeMoment(id: "moment-1"))
        firstSubject.send(firstWorkspace)
        await waitUntil { observer.activeWorkspace == firstWorkspace }

        observer.observeWorkspace(ownerUserId: "user-1", momentId: "moment-2")
        let secondWorkspace = makeWorkspace(moment: makeMoment(id: "moment-2"))
        repository.sendWorkspace(secondWorkspace)
        await waitUntil { observer.activeWorkspace == secondWorkspace }

        firstSubject.send(makeWorkspace(moment: makeMoment(id: "stale-moment")))
        try? await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertEqual(observer.activeWorkspace, secondWorkspace)
        XCTAssertEqual(repository.observedRequests, [
            WorkspaceRequest(ownerUserId: "user-1", momentId: "moment-1"),
            WorkspaceRequest(ownerUserId: "user-1", momentId: "moment-2")
        ])
    }

    private func waitUntil(
        timeoutNanoseconds: UInt64 = 250_000_000,
        condition: @escaping @MainActor () -> Bool
    ) async {
        let deadline = ContinuousClock.now.advanced(by: .nanoseconds(Int(timeoutNanoseconds)))
        while ContinuousClock.now < deadline {
            if condition() {
                return
            }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }

    private func makeWorkspace(moment: InProgressMoment) -> MomentWorkspace {
        MomentWorkspace(
            moment: moment,
            mediaAssets: [],
            storyScenes: [],
            renderJobs: [],
            artifacts: []
        )
    }

    private func makeMoment(id: String) -> InProgressMoment {
        InProgressMoment(
            id: id,
            template: .birthdayMessage,
            status: "in_progress",
            title: "Family Weekend",
            tone: nil,
            tempo: nil,
            occasion: nil,
            details: nil,
            durationSeconds: 30,
            creditCost: 2,
            updatedAt: 10
        )
    }
}

@MainActor
private final class MockMomentsRepository: InProgressMomentsObserving {
    private(set) var momentsSubjects: [CurrentValueSubject<[InProgressMoment], Error>] = []
    private(set) var observedOwnerUserIds: [String] = []
    private let momentsError: Error?

    init(momentsError: Error? = nil) {
        self.momentsError = momentsError
    }

    func observeInProgressMoments(ownerUserId: String) throws -> AnyPublisher<[InProgressMoment], Error> {
        observedOwnerUserIds.append(ownerUserId)
        if let momentsError {
            throw momentsError
        }
        let subject = CurrentValueSubject<[InProgressMoment], Error>([])
        momentsSubjects.append(subject)
        return subject.eraseToAnyPublisher()
    }

    func sendMoments(_ moments: [InProgressMoment]) {
        momentsSubjects.last?.send(moments)
    }
}

@MainActor
private final class MockWorkspaceRepository: MomentWorkspaceObserving {
    private(set) var workspaceSubjects: [CurrentValueSubject<MomentWorkspace?, Error>] = []
    private(set) var observedRequests: [WorkspaceRequest] = []
    private let workspaceError: Error?

    init(workspaceError: Error? = nil) {
        self.workspaceError = workspaceError
    }

    func observeMomentWorkspace(
        ownerUserId: String,
        momentId: String
    ) throws -> AnyPublisher<MomentWorkspace?, Error> {
        observedRequests.append(WorkspaceRequest(ownerUserId: ownerUserId, momentId: momentId))
        if let workspaceError {
            throw workspaceError
        }
        let subject = CurrentValueSubject<MomentWorkspace?, Error>(nil)
        workspaceSubjects.append(subject)
        return subject.eraseToAnyPublisher()
    }

    func sendWorkspace(_ workspace: MomentWorkspace?) {
        workspaceSubjects.last?.send(workspace)
    }
}

private struct WorkspaceRequest: Equatable {
    var ownerUserId: String
    var momentId: String
}

private enum TestObservationError: LocalizedError {
    case moments
    case workspace

    var errorDescription: String? {
        switch self {
        case .moments:
            "Moment observation failed."
        case .workspace:
            "Workspace observation failed."
        }
    }
}
