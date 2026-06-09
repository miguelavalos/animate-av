import XCTest
@testable import AnimateAV

final class AnimateCreateVideoSetupGuideStateTests: XCTestCase {
    func testSelectingNoMessageDoesNotCompleteGuide() {
        var state = AnimateCreateVideoSetupGuideState()
        state.selectScriptIdea(.none)

        XCTAssertEqual(state.selectedScriptIdea, .none)
        XCTAssertEqual(state.step, .look)
        XCTAssertFalse(state.isComplete)
    }

    func testNoMessageCompletesOnlyWhenContinuingFromMessageChoiceStep() {
        var state = AnimateCreateVideoSetupGuideState()

        var result = state.continueStep(
            hasSelectedLook: true,
            hasMessage: false,
            canContinueMessageStep: false
        )
        XCTAssertEqual(result.activeSheet, .scriptIdea)
        XCTAssertFalse(result.clearsMessage)
        XCTAssertFalse(state.isComplete)

        state.selectScriptIdea(.none)
        result = state.continueStep(
            hasSelectedLook: true,
            hasMessage: false,
            canContinueMessageStep: false
        )

        XCTAssertNil(result.activeSheet)
        XCTAssertTrue(result.clearsMessage)
        XCTAssertTrue(state.isComplete)
        XCTAssertEqual(state.step, .scriptIdea)
    }

    func testMessageFlowRequiresVoiceStepBeforeCompletion() {
        var state = AnimateCreateVideoSetupGuideState()

        XCTAssertEqual(
            state.continueStep(hasSelectedLook: true, hasMessage: false, canContinueMessageStep: false).activeSheet,
            .scriptIdea
        )

        state.selectScriptIdea(.birthday)
        XCTAssertEqual(
            state.continueStep(hasSelectedLook: true, hasMessage: true, canContinueMessageStep: true).activeSheet,
            .scriptMessage
        )
        XCTAssertFalse(state.isComplete)

        XCTAssertEqual(
            state.continueStep(hasSelectedLook: true, hasMessage: true, canContinueMessageStep: true).activeSheet,
            .voice
        )
        XCTAssertFalse(state.isComplete)

        XCTAssertNil(
            state.continueStep(hasSelectedLook: true, hasMessage: true, canContinueMessageStep: true).activeSheet
        )
        XCTAssertTrue(state.isComplete)
    }
}
