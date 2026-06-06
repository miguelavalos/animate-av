import Foundation
import AVMediaAnalysisFoundation
import XCTest
@testable import AnimateAV

final class MomentsMediaRulesTests: XCTestCase {
    func testSelectedCountUsesSyncedMediaWhenLocalSelectionIsEmpty() {
        let syncedMedia = [
            makeSyncedMedia(id: "media-1", selected: true),
            makeSyncedMedia(id: "media-2", selected: false),
            makeSyncedMedia(id: "media-3", selected: true)
        ]

        XCTAssertEqual(
            MomentsMediaRules.selectedCount(localMedia: [], syncedMedia: syncedMedia),
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
            MomentsMediaRules.selectedCount(localMedia: localMedia, syncedMedia: syncedMedia),
            1
        )
    }

    func testRemainingSlotsNeverReturnsNegativeCount() {
        XCTAssertEqual(
            MomentsMediaRules.remainingSlots(template: .birthdayMessage, selectedCount: 11),
            0
        )
        XCTAssertEqual(
            MomentsMediaRules.remainingSlots(template: .birthdayMessage, selectedCount: 12),
            0
        )
        XCTAssertEqual(
            MomentsMediaRules.remainingSlots(template: .birthdayMessage, selectedCount: 13),
            0
        )
    }

    func testAutoStyleSuggestionUsesLocalSceneryAnalysisForTravel() {
        let media = (0..<5).map { index in
            makeLocalMedia(
                id: "00000000-0000-0000-0000-00000000010\(index)",
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
        }

        let suggestion = MomentsMediaAutoStyleSuggester.suggest(
            media: media,
            styles: MomentCreationStyle.launchStyles
        )

        XCTAssertEqual(suggestion?.styleID, .travel)
        XCTAssertEqual(suggestion?.musicPreset, .cinematic)
        XCTAssertEqual(suggestion?.metrics.sceneryAssetCount, 5)
    }

    private func makeLocalMedia(
        id: String,
        selected: Bool,
        analysis: AVLocalMediaAnalysis? = nil
    ) -> MomentsSelectedMedia {
        MomentsSelectedMedia(
            id: UUID(uuidString: id)!,
            sourceLocalIdentifier: id,
            originalFilename: "\(id).jpg",
            contentType: "image/jpeg",
            kind: "photo",
            byteSize: 4,
            sha256: "abcd",
            data: Data([1, 2, 3, 4]),
            capturedAt: nil,
            analysis: analysis,
            sortOrder: 0,
            selected: selected
        )
    }

    private func makeSyncedMedia(id: String, selected: Bool) -> MomentMediaAsset {
        MomentMediaAsset(
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
