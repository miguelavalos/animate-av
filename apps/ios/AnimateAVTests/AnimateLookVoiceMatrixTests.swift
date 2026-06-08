import XCTest
@testable import AnimateAV

@MainActor
final class AnimateLookVoiceMatrixTests: XCTestCase {
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
