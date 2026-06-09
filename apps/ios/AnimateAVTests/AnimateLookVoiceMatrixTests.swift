import UIKit
import XCTest
@testable import AnimateAV

@MainActor
final class AnimateLookVoiceMatrixTests: XCTestCase {
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

    func testLookLibraryIsOrganizedInCompleteVoiceBlocks() {
        XCTAssertEqual(AnimateVideoVoiceProfile.selectorOrder.count, 8)
        XCTAssertEqual(AnimateVideoLook.selectorOrder.count % AnimateVideoVoiceProfile.selectorOrder.count, 0)
    }

    func testEachLookBlockMapsToVoiceSelectorOrder() {
        let voiceOrder = AnimateVideoVoiceProfile.selectorOrder

        for (index, look) in AnimateVideoLook.selectorOrder.enumerated() {
            XCTAssertEqual(
                look.defaultVoiceProfile,
                voiceOrder[index % voiceOrder.count],
                "Look \(look.rawValue) at selector index \(index) should use the voice in the same block position."
            )
        }
    }

    func testEveryFamilyPositionMapsToVoiceSelectorOrder() {
        let voiceOrder = AnimateVideoVoiceProfile.selectorOrder

        for family in AnimateVideoLook.families {
            for (index, look) in family.looks.enumerated() {
                XCTAssertEqual(
                    look.defaultVoiceProfile,
                    voiceOrder[index],
                    "Look \(look.rawValue) in family \(family.id) position \(index) should use the matching voice."
                )
            }
        }
    }

    func testEachLookReferencesAvailablePreviewAssetAllowingPlaceholders() {
        let assetNames = AnimateVideoLook.selectorOrder.map(\.assetName)

        XCTAssertEqual(assetNames.count, 64)
        XCTAssertTrue(assetNames.allSatisfy { $0.hasPrefix("Look") })

        for assetName in Set(assetNames) {
            XCTAssertNotNil(UIImage(named: assetName), "Missing preview asset \(assetName).")
        }
    }

    func testFinishedPreviewAssetsKeepStableUniqueNames() {
        let existingLooks: [AnimateVideoLook] = [
            .anime, .cartoon, .comic, .clay, .watercolor, .cinematic3d,
            .manga, .paperCut, .plush, .sticker, .pixel, .neon,
            .storybook, .yellowComedy, .soft3d, .darkFantasy, .vintagePoster,
            .pencilSketch, .editorialCaricature, .euroComic, .americanComic,
            .stopMotion, .blackWhiteManga, .toyFigure, .chibi, .flatVector,
            .pastelDream, .heroicComic, .noirInk, .rubberHose, .fantasyQuest,
            .miniAvatar
        ]
        let finishedAssetNames = existingLooks.map(\.assetName)

        XCTAssertEqual(Set(finishedAssetNames).count, finishedAssetNames.count)
    }

    func testSelectingLookAppliesDefaultVoiceWhenVoiceWasNotManuallyChanged() {
        let viewModel = AnimateCreateViewModel()

        viewModel.selectLook(.anime)

        XCTAssertEqual(viewModel.form.look, .anime)
        XCTAssertEqual(viewModel.form.voiceProfile, AnimateVideoLook.anime.defaultVoiceProfile)
    }

    func testSelectingLookDoesNotOverrideManualVoiceSelection() {
        let viewModel = AnimateCreateViewModel()

        viewModel.updateVoiceProfile(.elderMan)
        viewModel.selectLook(.anime)

        XCTAssertEqual(viewModel.form.look, .anime)
        XCTAssertEqual(viewModel.form.voiceProfile, .elderMan)
    }
}
