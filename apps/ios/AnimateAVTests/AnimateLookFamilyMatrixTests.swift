import UIKit
import XCTest
@testable import AnimateAV

@MainActor
final class AnimateLookFamilyMatrixTests: XCTestCase {
    func testLookLibraryHasEightCompleteFamilies() {
        XCTAssertEqual(AnimateVideoLook.families.count, 8)
        XCTAssertEqual(AnimateVideoLook.selectorOrder.count, 64)

        for family in AnimateVideoLook.families {
            XCTAssertEqual(family.looks.count, 8, "Family \(family.id) should contain exactly 8 looks.")
        }
    }

    func testLookFamiliesContainUniqueLooks() {
        let familyLooks = AnimateVideoLook.families.flatMap(\.looks)

        XCTAssertEqual(familyLooks, AnimateVideoLook.selectorOrder)
        XCTAssertEqual(Set(familyLooks).count, 64)
        XCTAssertEqual(Set(AnimateVideoLook.allCases).count, 64)
    }

    func testFamilyHeroAssetsUseCuratedFirstScreenProgression() {
        let expectedHeroAssets = [
            "LookCartoon",
            "LookSticker",
            "LookNoirInk",
            "LookCyberAnime",
            "LookStorybook",
            "LookSynthwave",
            "LookMythicEpic",
            "LookInkWash",
        ]

        XCTAssertEqual(AnimateVideoLook.families.map(\.heroAssetName), expectedHeroAssets)
    }

    func testEachLookReferencesUniqueAvailablePreviewAsset() {
        let assetNames = AnimateVideoLook.selectorOrder.map(\.assetName)

        XCTAssertEqual(assetNames.count, 64)
        XCTAssertEqual(Set(assetNames).count, 64)
        XCTAssertTrue(assetNames.allSatisfy { $0.hasPrefix("Look") })

        for assetName in assetNames {
            XCTAssertNotNil(UIImage(named: assetName), "Missing preview asset \(assetName).")
        }
    }

    func testPublishedLookNamesMatchCurrentProductGuide() {
        XCTAssertEqual(AnimateVideoLook.rubberHose.title, L10n.string("create.look.rubberHose.title"))
        XCTAssertEqual(AnimateVideoLook.rubberHose.title, "Bubble Cartoon")
        XCTAssertEqual(AnimateVideoLook.flatVector.title, "HD-2D Adventure")
        XCTAssertEqual(AnimateVideoLook.yellowComedy.title, "Cozy Magic")
    }
}
