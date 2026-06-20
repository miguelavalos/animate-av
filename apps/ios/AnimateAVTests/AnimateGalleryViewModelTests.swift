import Combine
import XCTest
@testable import AnimateAV

@MainActor
final class AnimateGalleryViewModelTests: XCTestCase {
    private let dismissedRemoteVideoIdsDefaultsKey = "AnimateGallery.dismissedRemoteVideoIds"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: dismissedRemoteVideoIdsDefaultsKey)
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: dismissedRemoteVideoIdsDefaultsKey)
        super.tearDown()
    }

    func testDeletingDownloadedRemoteVideoDoesNotReinsertDownloadPlaceholder() {
        let artifact = AnimateArtifact(
            id: "remote-artifact-1",
            workflowArtifactId: "final-artifact-1",
            kind: "final_video",
            r2Key: "animateav/video.mp4",
            title: "Cartoon",
            look: "cartoon",
            status: "available",
            durationSeconds: 5,
            creditCost: 1,
            hasWatermark: true,
            expiresAt: Date().addingTimeInterval(3600).timeIntervalSince1970 * 1000,
            createdAt: 1_780_000_000_000
        )
        let record = AnimateGalleryVideoRecord(
            id: "final-artifact-1",
            videoId: "video-1",
            artifactId: "final-artifact-1",
            title: "Cartoon",
            r2Key: "animateav/video.mp4",
            localRelativePath: "Videos/final-artifact-1.mp4",
            createdAt: 1_780_000_000_000
        )
        let store = TestAnimateGalleryStore(videoRecords: [record], existingVideoIds: ["final-artifact-1"])
        let provider = TestAnimateGalleryArtifactsProvider()
        provider.send([artifact])

        let viewModel = AnimateGalleryViewModel(
            galleryStore: store,
            galleryArtifactsProvider: provider
        )

        XCTAssertEqual(viewModel.videos.map(\.id), ["final-artifact-1"])

        guard let video = viewModel.videos.first else {
            XCTFail("Expected downloaded video")
            return
        }
        viewModel.deleteVideo(video)

        XCTAssertTrue(viewModel.videos.isEmpty)
        XCTAssertTrue(store.deletedVideoIds.contains("final-artifact-1"))

        provider.send([artifact])

        XCTAssertTrue(viewModel.videos.isEmpty)
    }

    func testRemoteGalleryObservationIsExplicitAndStopsCleanly() {
        let provider = TestAnimateGalleryArtifactsProvider()
        let accountState = TestAnimateAccountStateProvider(ownerUserId: "user-1")
        let viewModel = AnimateGalleryViewModel(
            galleryStore: TestAnimateGalleryStore(),
            galleryArtifactsProvider: provider
        )

        viewModel.bind(accountStateProvider: accountState)
        viewModel.startRemoteGalleryObservation()

        XCTAssertEqual(provider.observedOwnerUserIds, ["user-1"])

        viewModel.stopRemoteGalleryObservation()

        XCTAssertEqual(provider.clearCount, 1)
    }

    func testFinishedRemoteVideoMetadataAppearsWithoutLocalRecord() {
        let summaryProvider = TestAnimateInProgressSummaryProvider()
        let viewModel = AnimateGalleryViewModel(
            galleryStore: TestAnimateGalleryStore(),
            galleryArtifactsProvider: TestAnimateGalleryArtifactsProvider()
        )

        viewModel.bind(to: summaryProvider)
        summaryProvider.send(
            AnimateInProgressSummary.make(from: [
                makeVideo(id: "finished-video", status: "gallery_ready", title: "Finished video", finalExport: nil)
            ])
        )

        XCTAssertEqual(viewModel.videos.map(\.id), ["finished-video"])
        XCTAssertEqual(viewModel.videos.first?.availability, .remoteMetadataOnly)
        XCTAssertEqual(viewModel.videos.first?.title, "Finished video")
    }

    func testFinishedRemoteVideoWithFinalExportIsDownloadable() {
        let summaryProvider = TestAnimateInProgressSummaryProvider()
        let viewModel = AnimateGalleryViewModel(
            galleryStore: TestAnimateGalleryStore(),
            galleryArtifactsProvider: TestAnimateGalleryArtifactsProvider()
        )
        let finalExport = makeArtifact(
            id: "artifact-1",
            workflowArtifactId: "workflow-artifact-1",
            status: "available"
        )

        viewModel.bind(to: summaryProvider)
        summaryProvider.send(
            AnimateInProgressSummary.make(from: [
                makeVideo(
                    id: "finished-video",
                    status: "gallery_ready",
                    title: "Finished video",
                    finalExport: finalExport
                )
            ])
        )

        XCTAssertEqual(viewModel.videos.map(\.id), ["workflow-artifact-1"])
        XCTAssertEqual(viewModel.videos.first?.record.videoId, "finished-video")
        XCTAssertEqual(viewModel.videos.first?.availability, .downloadAvailable)
        XCTAssertEqual(viewModel.videos.first?.remoteArtifact, finalExport)
    }
}

private final class TestAnimateInProgressSummaryProvider: AnimateInProgressSummaryProviding {
    private let summarySubject = CurrentValueSubject<AnimateInProgressSummary, Never>(AnimateInProgressSummary())

    var inProgressSummaryPublisher: AnyPublisher<AnimateInProgressSummary, Never> {
        summarySubject.eraseToAnyPublisher()
    }

    func send(_ summary: AnimateInProgressSummary) {
        summarySubject.send(summary)
    }
}

private final class TestAnimateGalleryArtifactsProvider: AnimateGalleryListProviding {
    private let artifactsSubject = CurrentValueSubject<[AnimateArtifact], Never>([])
    private let errorSubject = CurrentValueSubject<String?, Never>(nil)
    private(set) var observedOwnerUserIds: [String?] = []
    private(set) var clearCount = 0

    var galleryArtifactsPublisher: AnyPublisher<[AnimateArtifact], Never> {
        artifactsSubject.eraseToAnyPublisher()
    }

    var galleryArtifactsErrorPublisher: AnyPublisher<String?, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    func observeGalleryArtifacts(ownerUserId: String?) {
        observedOwnerUserIds.append(ownerUserId)
    }

    func clearGalleryArtifacts() {
        clearCount += 1
        artifactsSubject.send([])
    }

    func send(_ artifacts: [AnimateArtifact]) {
        artifactsSubject.send(artifacts)
    }
}

private final class TestAnimateAccountStateProvider: AnimateAccountStateProviding {
    private let ownerUserId: String?

    init(ownerUserId: String?) {
        self.ownerUserId = ownerUserId
    }

    var isSignedInPublisher: AnyPublisher<Bool, Never> {
        Just(ownerUserId != nil).eraseToAnyPublisher()
    }

    var currentUserIdPublisher: AnyPublisher<String?, Never> {
        Just(ownerUserId).eraseToAnyPublisher()
    }

    var displayNamePublisher: AnyPublisher<String?, Never> {
        Just(nil).eraseToAnyPublisher()
    }

    var creditBalancePublisher: AnyPublisher<AnimateCreditBalance, Never> {
        Just(.empty).eraseToAnyPublisher()
    }

    var creditBalanceLoadStatePublisher: AnyPublisher<AnimateCreditBalanceLoadState, Never> {
        Just(.loaded).eraseToAnyPublisher()
    }
}

private func makeArtifact(
    id: String,
    workflowArtifactId: String?,
    status: String
) -> AnimateArtifact {
    AnimateArtifact(
        id: id,
        workflowArtifactId: workflowArtifactId,
        kind: "final_video",
        r2Key: "animateav/video.mp4",
        title: "Cartoon",
        look: "cartoon",
        status: status,
        durationSeconds: 5,
        creditCost: 1,
        hasWatermark: true,
        expiresAt: Date().addingTimeInterval(3600).timeIntervalSince1970 * 1000,
        createdAt: 1_780_000_000_000
    )
}

private func makeVideo(
    id: String,
    status: String,
    title: String,
    finalExport: AnimateArtifact?
) -> AnimateVideo {
    AnimateVideo(
        id: id,
        template: .birthdayMessage,
        status: status,
        title: title,
        tone: nil,
        tempo: nil,
        occasion: nil,
        details: nil,
        durationSeconds: 5,
        creditCost: 1,
        updatedAt: 1_780_000_000_000,
        finalExport: finalExport
    )
}

private final class TestAnimateGalleryStore: AnimateGalleryStoring {
    private var videoRecords: [AnimateGalleryVideoRecord]
    private var imageRecords: [AnimateGalleryImageRecord] = []
    private var existingVideoIds: Set<String>
    private var existingImageIds: Set<String> = []
    private(set) var deletedVideoIds = Set<String>()

    convenience init() {
        self.init(videoRecords: [], existingVideoIds: [])
    }

    init(videoRecords: [AnimateGalleryVideoRecord], existingVideoIds: Set<String>) {
        self.videoRecords = videoRecords
        self.existingVideoIds = existingVideoIds
    }

    func loadRecords() -> [AnimateGalleryVideoRecord] { videoRecords }
    func saveRecords(_ records: [AnimateGalleryVideoRecord]) { videoRecords = records }
    func loadImageRecords() -> [AnimateGalleryImageRecord] { imageRecords }
    func saveImageRecords(_ records: [AnimateGalleryImageRecord]) { imageRecords = records }
    func localFileExists(for record: AnimateGalleryVideoRecord) -> Bool { existingVideoIds.contains(record.id) }
    func localFileURL(for record: AnimateGalleryVideoRecord) -> URL { URL(fileURLWithPath: "/tmp/\(record.id).mp4") }
    func localFileExists(for record: AnimateGalleryImageRecord) -> Bool { existingImageIds.contains(record.id) }
    func localFileURL(for record: AnimateGalleryImageRecord) -> URL { URL(fileURLWithPath: "/tmp/\(record.id).jpg") }
    func localFileExists(relativePath: String) -> Bool { false }
    func localFileURL(relativePath: String) -> URL { URL(fileURLWithPath: "/tmp/\(relativePath)") }
    func contains(artifactId: String) -> Bool { videoRecords.contains { $0.artifactId == artifactId } }
    func containsImage(artifactId: String) -> Bool { imageRecords.contains { $0.artifactId == artifactId } }
    func saveSourceImage(data: Data, videoId: String, artifactId: String) throws -> String { "Images/\(artifactId).jpg" }
    func saveDownloadedVideo(
        temporaryFileURL: URL,
        videoId: String,
        artifactId: String,
        title: String,
        r2Key: String,
        sourceImageLocalRelativePath: String?,
        generatedImageLocalRelativePath: String?,
        createdAt: Date
    ) throws -> AnimateGalleryVideoRecord {
        AnimateGalleryVideoRecord(
            id: artifactId,
            videoId: videoId,
            artifactId: artifactId,
            title: title,
            r2Key: r2Key,
            localRelativePath: "Videos/\(artifactId).mp4",
            sourceImageLocalRelativePath: sourceImageLocalRelativePath,
            generatedImageLocalRelativePath: generatedImageLocalRelativePath,
            createdAt: createdAt.timeIntervalSince1970 * 1000
        )
    }
    func saveDownloadedImage(
        temporaryFileURL: URL,
        artifactId: String,
        title: String,
        look: String?,
        r2Key: String,
        createdAt: Date
    ) throws -> AnimateGalleryImageRecord {
        AnimateGalleryImageRecord(
            id: artifactId,
            artifactId: artifactId,
            title: title,
            look: look,
            r2Key: r2Key,
            localRelativePath: "Images/\(artifactId).jpg",
            createdAt: createdAt.timeIntervalSince1970 * 1000
        )
    }
    func addRecord(_ record: AnimateGalleryVideoRecord) { videoRecords = [record] + videoRecords.filter { $0.id != record.id } }
    func addImageRecord(_ record: AnimateGalleryImageRecord) { imageRecords = [record] + imageRecords.filter { $0.id != record.id } }
    func renameRecord(_ record: AnimateGalleryVideoRecord, title: String) {}
    func renameImageRecord(_ record: AnimateGalleryImageRecord, title: String) {
        imageRecords = imageRecords.map { $0.id == record.id ? $0.renamed(title) : $0 }
    }
    func deleteRecord(_ record: AnimateGalleryVideoRecord, deleteLocalFile: Bool) {
        deletedVideoIds.insert(record.id)
        existingVideoIds.remove(record.id)
        videoRecords.removeAll { $0.id == record.id }
    }
    func deleteImageRecord(_ record: AnimateGalleryImageRecord, deleteLocalFile: Bool) {
        existingImageIds.remove(record.id)
        imageRecords.removeAll { $0.id == record.id }
    }
}
