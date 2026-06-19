import Foundation
import AVMediaAnalysisFoundation
import XCTest
@testable import AnimateAV

final class AnimateMediaRulesTests: XCTestCase {
    func testSelectedCountUsesSyncedMediaWhenLocalSelectionIsEmpty() {
        let syncedMedia = [
            makeSyncedMedia(id: "media-1", selected: true),
            makeSyncedMedia(id: "media-2", selected: false),
            makeSyncedMedia(id: "media-3", selected: true)
        ]

        XCTAssertEqual(
            AnimateMediaRules.selectedCount(localMedia: [], syncedMedia: syncedMedia),
            2
        )
    }

    func testSelectedCountPrefersLocalMediaWhenPresent() {
        let localMedia = [
            makeLocalMedia(id: "00000000-0000-0000-0000-000000000001", selected: true),
            makeLocalMedia(id: "00000000-0000-0000-0000-000000000002", selected: false)
        ]
        let syncedMedia = [
            makeSyncedMedia(id: "media-1", selected: true),
            makeSyncedMedia(id: "media-2", selected: true),
            makeSyncedMedia(id: "media-3", selected: true)
        ]

        XCTAssertEqual(
            AnimateMediaRules.selectedCount(localMedia: localMedia, syncedMedia: syncedMedia),
            1
        )
    }

    func testRemainingSlotsNeverReturnsNegativeCount() {
        XCTAssertEqual(
            AnimateMediaRules.remainingSlots(template: .birthdayMessage, selectedCount: 0),
            1
        )
        XCTAssertEqual(
            AnimateMediaRules.remainingSlots(template: .birthdayMessage, selectedCount: 1),
            0
        )
        XCTAssertEqual(
            AnimateMediaRules.remainingSlots(template: .birthdayMessage, selectedCount: 2),
            0
        )
    }

    func testPhotoFrameAdjustmentKeepsOriginalDataForLaterEditing() {
        let original = Data([1, 2, 3, 4])
        let cropped = Data([9, 8, 7])
        let media = makeLocalMedia(
            id: "00000000-0000-0000-0000-000000000301",
            selected: true,
            data: original
        )

        let adjusted = media.updatedPhotoData(cropped, sha256: "croppedhash")

        XCTAssertEqual(adjusted.data, cropped)
        XCTAssertEqual(adjusted.sourceImageDataForEditing, original)
        XCTAssertEqual(adjusted.activeSourceImageData, cropped)
        XCTAssertTrue(adjusted.hasFrameAdjustment)
        XCTAssertTrue(adjusted.sourceLocalIdentifier.contains(":crop:"))
    }

    func testRestoringOriginalPhotoDataClearsFrameAdjustment() {
        let original = Data([1, 2, 3, 4])
        let cropped = Data([9, 8, 7])
        let media = makeLocalMedia(
            id: "00000000-0000-0000-0000-000000000302",
            selected: true,
            data: original
        )
        let adjusted = media.updatedPhotoData(cropped, sha256: "croppedhash")

        let restored = adjusted.restoredOriginalPhotoData(sha256: "originalhash")

        XCTAssertEqual(restored.data, original)
        XCTAssertEqual(restored.sourceImageDataForEditing, original)
        XCTAssertFalse(restored.hasFrameAdjustment)
        XCTAssertEqual(restored.sourceLocalIdentifier, media.sourceLocalIdentifier)
    }

    func testAutoStyleSuggestionUsesSingleLocalSceneryImageForTravel() {
        let media = [
            makeLocalMedia(
                id: "00000000-0000-0000-0000-000000000101",
                selected: true,
                analysis: AVLocalMediaAnalysis(
                    faceCount: 0,
                    hasPeople: false,
                    brightnessScore: 0.62,
                    sharpnessScore: 0.72,
                    qualityScore: 0.68,
                    orientation: .landscape,
                    sceneRole: .scenery
                )
            )
        ]

        let suggestion = AnimateMediaAutoStyleSuggester.suggest(
            media: media,
            styles: AnimateVideoCreationStyle.launchStyles
        )

        XCTAssertEqual(suggestion?.styleID, .travel)
        XCTAssertEqual(suggestion?.musicPreset, .cinematic)
        XCTAssertEqual(suggestion?.metrics.sceneryAssetCount, 1)
        XCTAssertEqual(suggestion?.metrics.sampleCount, 1)
    }

    private func makeLocalMedia(
        id: String,
        selected: Bool,
        data: Data = Data([1, 2, 3, 4]),
        analysis: AVLocalMediaAnalysis? = nil
    ) -> AnimateSelectedMedia {
        AnimateSelectedMedia(
            id: UUID(uuidString: id)!,
            sourceLocalIdentifier: id,
            originalFilename: "\(id).jpg",
            contentType: "image/jpeg",
            kind: "photo",
            byteSize: 4,
            sha256: "abcd",
            data: data,
            capturedAt: nil,
            analysis: analysis,
            sortOrder: 0,
            selected: selected
        )
    }

    private func makeSyncedMedia(id: String, selected: Bool) -> AnimateMediaAsset {
        AnimateMediaAsset(
            id: id,
            platformMediaAssetId: "platform-\(id)",
            uploadId: "upload-\(id)",
            kind: "photo",
            sortOrder: 0,
            selected: selected,
            moderationStatus: "pending",
            uploadedAt: 1_779_000_000_000,
            sourceExpiresAt: 1_781_592_000_000
        )
    }
}
