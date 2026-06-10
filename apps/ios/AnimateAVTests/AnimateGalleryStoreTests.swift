import XCTest
@testable import AnimateAV

final class AnimateGalleryStoreTests: XCTestCase {
    func testSavingImageRecordsDoesNotOverwriteVideoRecords() {
        let baseDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AnimateGalleryStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: baseDirectory) }

        let store = AnimateGalleryStore(baseDirectory: baseDirectory)
        let video = AnimateGalleryVideoRecord(
            id: "video-record",
            videoId: "video-1",
            artifactId: "artifact-video",
            title: "Animate video",
            r2Key: "videos/final.mp4",
            localRelativePath: "Videos/final.mp4",
            createdAt: 1_780_000_000_000
        )
        let image = AnimateGalleryImageRecord(
            id: "image-record",
            artifactId: "artifact-image",
            title: "Stylized image",
            look: "pencil-sketch",
            r2Key: "images/source.jpg",
            localRelativePath: "Images/source.jpg",
            createdAt: 1_780_000_000_100
        )

        store.saveRecords([video])
        store.saveImageRecords([image])

        XCTAssertEqual(store.loadRecords(), [video])
        XCTAssertEqual(store.loadImageRecords(), [image])
    }

    func testSavingVideoCanReferenceLocalComparisonImages() throws {
        let baseDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AnimateGalleryStoreTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: baseDirectory) }

        let store = AnimateGalleryStore(baseDirectory: baseDirectory)
        let sourcePath = try store.saveSourceImage(
            data: Data("source-image".utf8),
            videoId: "video-1",
            artifactId: "artifact-video"
        )
        let videoURL = baseDirectory.appendingPathComponent("download.mp4")
        try Data("video".utf8).write(to: videoURL, options: .atomic)

        let record = try store.saveDownloadedVideo(
            temporaryFileURL: videoURL,
            videoId: "video-1",
            artifactId: "artifact-video",
            title: "Animate video",
            r2Key: "videos/final.mp4",
            sourceImageLocalRelativePath: sourcePath,
            generatedImageLocalRelativePath: "Images/generated.jpg",
            createdAt: Date(timeIntervalSince1970: 1_780_000_000)
        )

        XCTAssertEqual(record.sourceImageLocalRelativePath, sourcePath)
        XCTAssertEqual(record.generatedImageLocalRelativePath, "Images/generated.jpg")
        XCTAssertTrue(store.localFileExists(relativePath: sourcePath))
    }
}
