import Combine
import XCTest
@testable import AnimateAV

@MainActor
final class AnimateInProgressObserverTests: XCTestCase {
    func testInProgressObserverPublishesVideoUpdates() async throws {
        let repository = MockAnimateRepository()
        let observer = AnimateInProgressObserver(animateRepository: repository)

        observer.observeAnimateVideos(ownerUserId: "user-1")
        let video = makeVideo(id: "video-1")
        repository.sendVideos([video])
        await waitUntil { observer.videos == [video] }

        XCTAssertEqual(observer.videos, [video])
        XCTAssertNil(observer.errorMessage)
        XCTAssertEqual(repository.observedOwnerUserIds, ["user-1"])
    }

    func testInProgressObserverClearsStateWhenOwnerIsMissing() async {
        let repository = MockAnimateRepository()
        let observer = AnimateInProgressObserver(animateRepository: repository)

        observer.observeAnimateVideos(ownerUserId: "user-1")
        repository.sendVideos([makeVideo(id: "video-1")])
        await waitUntil { !observer.videos.isEmpty }

        observer.observeAnimateVideos(ownerUserId: nil)

        XCTAssertTrue(observer.videos.isEmpty)
        XCTAssertNil(observer.errorMessage)
        XCTAssertEqual(repository.observedOwnerUserIds, ["user-1"])
    }

    func testInProgressObserverPublishesObservationErrors() {
        let repository = MockAnimateRepository(videoError: TestObservationError.videos)
        let observer = AnimateInProgressObserver(animateRepository: repository)

        observer.observeAnimateVideos(ownerUserId: "user-1")

        XCTAssertTrue(observer.videos.isEmpty)
        XCTAssertEqual(observer.errorMessage, TestObservationError.videos.localizedDescription)
    }

    func testInProgressObserverIgnoresStaleVideoUpdatesAfterChangingOwner() async {
        let repository = MockAnimateRepository()
        let observer = AnimateInProgressObserver(animateRepository: repository)

        observer.observeAnimateVideos(ownerUserId: "user-1")
        let firstSubject = repository.videoSubjects[0]
        let firstVideo = makeVideo(id: "video-1")
        firstSubject.send([firstVideo])
        await waitUntil { observer.videos == [firstVideo] }

        observer.observeAnimateVideos(ownerUserId: "user-2")
        let secondVideo = makeVideo(id: "video-2")
        repository.sendVideos([secondVideo])
        await waitUntil { observer.videos == [secondVideo] }

        firstSubject.send([makeVideo(id: "stale-video")])
        try? await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertEqual(observer.videos, [secondVideo])
        XCTAssertEqual(repository.observedOwnerUserIds, ["user-1", "user-2"])
    }

    func testWorkspaceObserverPublishesWorkspaceUpdates() async throws {
        let repository = MockWorkspaceRepository()
        let observer = AnimateWorkspaceObserver(animateRepository: repository)

        observer.observeWorkspace(ownerUserId: "user-1", videoId: "video-1")
        let workspace = makeWorkspace(video: makeVideo(id: "video-1"))
        repository.sendWorkspace(workspace)
        await waitUntil { observer.activeWorkspace == workspace }

        XCTAssertEqual(observer.activeWorkspace, workspace)
        XCTAssertNil(observer.errorMessage)
        XCTAssertEqual(repository.observedRequests, [
            WorkspaceRequest(ownerUserId: "user-1", videoId: "video-1")
        ])
    }

    func testWorkspaceObserverClearsStateWhenRequestIsIncomplete() async {
        let repository = MockWorkspaceRepository()
        let observer = AnimateWorkspaceObserver(animateRepository: repository)

        observer.observeWorkspace(ownerUserId: "user-1", videoId: "video-1")
        repository.sendWorkspace(makeWorkspace(video: makeVideo(id: "video-1")))
        await waitUntil { observer.activeWorkspace != nil }

        observer.observeWorkspace(ownerUserId: "user-1", videoId: nil)

        XCTAssertNil(observer.activeWorkspace)
        XCTAssertNil(observer.errorMessage)
        XCTAssertEqual(repository.observedRequests, [
            WorkspaceRequest(ownerUserId: "user-1", videoId: "video-1")
        ])
    }

    func testWorkspaceObserverPublishesObservationErrors() {
        let repository = MockWorkspaceRepository(workspaceError: TestObservationError.workspace)
        let observer = AnimateWorkspaceObserver(animateRepository: repository)

        observer.observeWorkspace(ownerUserId: "user-1", videoId: "video-1")

        XCTAssertNil(observer.activeWorkspace)
        XCTAssertEqual(observer.errorMessage, TestObservationError.workspace.localizedDescription)
    }

    func testWorkspaceObserverIgnoresStaleWorkspaceUpdatesAfterChangingVideo() async {
        let repository = MockWorkspaceRepository()
        let observer = AnimateWorkspaceObserver(animateRepository: repository)

        observer.observeWorkspace(ownerUserId: "user-1", videoId: "video-1")
        let firstSubject = repository.workspaceSubjects[0]
        let firstWorkspace = makeWorkspace(video: makeVideo(id: "video-1"))
        firstSubject.send(firstWorkspace)
        await waitUntil { observer.activeWorkspace == firstWorkspace }

        observer.observeWorkspace(ownerUserId: "user-1", videoId: "video-2")
        let secondWorkspace = makeWorkspace(video: makeVideo(id: "video-2"))
        repository.sendWorkspace(secondWorkspace)
        await waitUntil { observer.activeWorkspace == secondWorkspace }

        firstSubject.send(makeWorkspace(video: makeVideo(id: "stale-video")))
        try? await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertEqual(observer.activeWorkspace, secondWorkspace)
        XCTAssertEqual(repository.observedRequests, [
            WorkspaceRequest(ownerUserId: "user-1", videoId: "video-1"),
            WorkspaceRequest(ownerUserId: "user-1", videoId: "video-2")
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

    private func makeWorkspace(video: AnimateVideo) -> AnimateWorkspace {
        AnimateWorkspace(
            video: video,
            mediaAssets: [],
            videoDirectionScenes: [],
            renderJobs: [],
            artifacts: []
        )
    }

    private func makeVideo(id: String) -> AnimateVideo {
        AnimateVideo(
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
private final class MockAnimateRepository: AnimateInProgressObserving {
    private(set) var videoSubjects: [CurrentValueSubject<[AnimateVideo], Error>] = []
    private(set) var observedOwnerUserIds: [String] = []
    private let videoError: Error?

    init(videoError: Error? = nil) {
        self.videoError = videoError
    }

    func observeAnimateVideos(ownerUserId: String) throws -> AnyPublisher<[AnimateVideo], Error> {
        observedOwnerUserIds.append(ownerUserId)
        if let videoError {
            throw videoError
        }
        let subject = CurrentValueSubject<[AnimateVideo], Error>([])
        videoSubjects.append(subject)
        return subject.eraseToAnyPublisher()
    }

    func sendVideos(_ videos: [AnimateVideo]) {
        videoSubjects.last?.send(videos)
    }
}

@MainActor
private final class MockWorkspaceRepository: AnimateWorkspaceObserving {
    private(set) var workspaceSubjects: [CurrentValueSubject<AnimateWorkspace?, Error>] = []
    private(set) var observedRequests: [WorkspaceRequest] = []
    private let workspaceError: Error?

    init(workspaceError: Error? = nil) {
        self.workspaceError = workspaceError
    }

    func observeAnimateWorkspace(
        ownerUserId: String,
        videoId: String
    ) throws -> AnyPublisher<AnimateWorkspace?, Error> {
        observedRequests.append(WorkspaceRequest(ownerUserId: ownerUserId, videoId: videoId))
        if let workspaceError {
            throw workspaceError
        }
        let subject = CurrentValueSubject<AnimateWorkspace?, Error>(nil)
        workspaceSubjects.append(subject)
        return subject.eraseToAnyPublisher()
    }

    func sendWorkspace(_ workspace: AnimateWorkspace?) {
        workspaceSubjects.last?.send(workspace)
    }
}

private struct WorkspaceRequest: Equatable {
    var ownerUserId: String
    var videoId: String
}

private enum TestObservationError: LocalizedError {
    case videos
    case workspace

    var errorDescription: String? {
        switch self {
        case .videos:
            "Video observation failed."
        case .workspace:
            "Workspace observation failed."
        }
    }
}
