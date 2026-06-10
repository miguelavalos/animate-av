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
}

private final class TestAnimateGalleryArtifactsProvider: AnimateGalleryListProviding {
    private let artifactsSubject = CurrentValueSubject<[AnimateArtifact], Never>([])
    private let errorSubject = CurrentValueSubject<String?, Never>(nil)

    var galleryArtifactsPublisher: AnyPublisher<[AnimateArtifact], Never> {
        artifactsSubject.eraseToAnyPublisher()
    }

    var galleryArtifactsErrorPublisher: AnyPublisher<String?, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    func observeGalleryArtifacts(ownerUserId: String?) {}
    func clearGalleryArtifacts() {
        artifactsSubject.send([])
    }

    func send(_ artifacts: [AnimateArtifact]) {
        artifactsSubject.send(artifacts)
    }
}

private final class TestAnimateGalleryStore: AnimateGalleryStoring {
    private var videoRecords: [AnimateGalleryVideoRecord]
    private var imageRecords: [AnimateGalleryImageRecord] = []
    private var existingVideoIds: Set<String>
    private var existingImageIds: Set<String> = []
    private(set) var deletedVideoIds = Set<String>()

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
