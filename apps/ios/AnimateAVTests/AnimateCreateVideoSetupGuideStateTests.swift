import XCTest
@testable import AnimateAV

final class AnimateCreateVideoSetupGuideStateTests: XCTestCase {
    func testSelectingNoMessageDoesNotCompleteGuide() {
        var state = AnimateCreateVideoSetupGuideState()
        state.selectScriptIdea(.none)

        XCTAssertEqual(state.selectedScriptIdea, .none)
        XCTAssertEqual(state.step, .photoFrame)
        XCTAssertFalse(state.isComplete)
    }

    func testNoMessageCompletesOnlyWhenContinuingFromMessageChoiceStep() {
        var state = AnimateCreateVideoSetupGuideState()

        var result = state.continueStep(
            hasSelectedLook: true,
            hasSelectedPhoto: true,
            hasMessage: false,
            canContinueMessageStep: false
        )
        XCTAssertEqual(result.activeSheet, .look)
        result = state.continueStep(
            hasSelectedLook: true,
            hasSelectedPhoto: true,
            hasMessage: false,
            canContinueMessageStep: false
        )
        XCTAssertEqual(result.activeSheet, .movement)
        result = state.continueStep(
            hasSelectedLook: true,
            hasSelectedPhoto: true,
            hasMessage: false,
            canContinueMessageStep: false
        )
        XCTAssertEqual(result.activeSheet, .scriptIdea)
        XCTAssertFalse(result.clearsMessage)
        XCTAssertFalse(state.isComplete)

        state.selectScriptIdea(.none)
        result = state.continueStep(
            hasSelectedLook: true,
            hasSelectedPhoto: true,
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

        XCTAssertEqual(continueReady(&state).activeSheet, .look)
        XCTAssertEqual(continueReady(&state).activeSheet, .movement)
        XCTAssertEqual(continueReady(&state).activeSheet, .scriptIdea)

        state.selectScriptIdea(.birthday)
        XCTAssertEqual(
            continueReady(&state, hasMessage: true, canContinueMessageStep: true).activeSheet,
            .scriptMessage
        )
        XCTAssertFalse(state.isComplete)

        XCTAssertEqual(
            continueReady(&state, hasMessage: true, canContinueMessageStep: true).activeSheet,
            .voice
        )
        XCTAssertFalse(state.isComplete)

        XCTAssertNil(
            continueReady(&state, hasMessage: true, canContinueMessageStep: true).activeSheet
        )
        XCTAssertTrue(state.isComplete)
    }

    private func continueReady(
        _ state: inout AnimateCreateVideoSetupGuideState,
        hasMessage: Bool = false,
        canContinueMessageStep: Bool = false
    ) -> AnimateCreateVideoSetupGuideState.ContinueResult {
        state.continueStep(
            hasSelectedLook: true,
            hasSelectedPhoto: true,
            hasMessage: hasMessage,
            canContinueMessageStep: canContinueMessageStep
        )
    }
}
