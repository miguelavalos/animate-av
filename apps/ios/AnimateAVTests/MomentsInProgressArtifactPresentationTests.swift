import XCTest
@testable import AnimateAV

final class MomentsInProgressArtifactPresentationTests: XCTestCase {
    func testRenderJobsSectionPresentationFormatsTitleEmptyStateAndJobs() {
        let presentation = MomentsInProgressRenderJobsSectionPresentation(renderJobs: [
            makeRenderJob(id: "old", kind: "final", status: "queued", updatedAt: 10),
            makeRenderJob(id: "new", kind: "final", status: "failed", updatedAt: 20)
        ])

        XCTAssertEqual(presentation.title, "Video activity")
        XCTAssertEqual(presentation.emptySystemImage, "gearshape.2")
        XCTAssertEqual(presentation.emptyMessage, "Plan and video creation will appear here.")
        XCTAssertEqual(presentation.jobs.map(\.id), ["new", "old"])
    }

    func testArtifactSectionPresentationsFormatTitlesEmptyStatesAndSelectedArtifacts() {
        let artifacts = [
            makeArtifact(id: "thumb-1", kind: "thumbnail", status: "expired"),
            makeArtifact(id: "final-1", kind: "final_export", status: "available"),
            makeArtifact(id: "thumb-2", kind: "thumbnail", status: "available")
        ]

        let finalExport = MomentsInProgressArtifactSectionPresentation.finalExport(artifacts: artifacts)

        XCTAssertEqual(finalExport.title, "Final video")
        XCTAssertEqual(finalExport.emptySystemImage, "video.fill")
        XCTAssertEqual(finalExport.emptyMessage, "Create the final video after preparing the plan.")
        XCTAssertEqual(finalExport.artifact?.storageKey, "animateav/final-1.mp4")
    }

    func testArtifactSectionPresentationsUseEmptyArtifactWhenMissing() {
        XCTAssertNil(MomentsInProgressArtifactSectionPresentation.finalExport(artifacts: []).artifact)
    }

    func testFinalExportPicksLatestMatchingArtifact() {
        let artifacts = [
            makeArtifact(id: "thumb-1", kind: "thumbnail", status: "expired"),
            makeArtifact(id: "final-1", kind: "final_export", status: "available"),
            makeArtifact(id: "thumb-2", kind: "thumbnail", status: "available")
        ]

        XCTAssertEqual(MomentsInProgressArtifactPresentation.finalExport(in: artifacts)?.storageKey, "animateav/final-1.mp4")
    }

    func testArtifactPresentationFormatsKindWatermarkAndExpiry() {
        let presentation = MomentsInProgressArtifactPresentation(
            artifact: makeArtifact(
                id: "final-1",
                kind: "final_export",
                status: "available",
                hasWatermark: false,
                expiresAt: 1_781_592_000_000
            )
        )

        XCTAssertEqual(presentation.kindTitle, "Final Export")
        XCTAssertEqual(presentation.watermarkTitle, "None")
        XCTAssertEqual(presentation.expiresAtTitle, MomentsDateFormatting.formattedDate(milliseconds: 1_781_592_000_000))
        XCTAssertEqual(presentation.actionDetail, "Your finished video is ready to save or share.")
    }

    func testFinalArtifactPresentationProvidesExportAndRecoveryCopy() {
        let availableFinal = MomentsInProgressArtifactPresentation(
            artifact: makeArtifact(id: "final-1", kind: "final_export", status: "available")
        )
        let expiredFinal = MomentsInProgressArtifactPresentation(
            artifact: makeArtifact(id: "final-2", kind: "final_export", status: "expired")
        )
        let failedFinal = MomentsInProgressArtifactPresentation(
            artifact: makeArtifact(id: "final-3", kind: "final_export", status: "failed")
        )
        let queuedFinal = MomentsInProgressArtifactPresentation(
            artifact: makeArtifact(id: "final-4", kind: "final_export", status: "queued")
        )

        XCTAssertEqual(availableFinal.actionDetail, "Your finished video is ready to save or share.")
        XCTAssertEqual(expiredFinal.actionDetail, "Final Export is no longer available. Return to Create and generate it again.")
        XCTAssertEqual(
            failedFinal.actionDetail,
            "Final Export is not available. Credits are only finalized after a usable final video is ready. Please retry in Create or contact support."
        )
        XCTAssertEqual(queuedFinal.actionDetail, "Final Export is still being prepared. Refresh in a moment.")
    }

    func testRenderJobPresentationSortsNewestFirstAndUsesFallbacks() {
        let presentations = MomentsInProgressRenderJobPresentation.sorted([
            makeRenderJob(id: "old", kind: "final", status: "queued", updatedAt: 10),
            makeRenderJob(
                id: "new",
                kind: "final",
                status: "failed",
                updatedAt: 20,
                provider: nil,
                model: nil,
                errorMessage: "provider stack trace"
            )
        ])

        XCTAssertEqual(presentations.map(\.id), ["new", "old"])
        XCTAssertEqual(presentations[0].kindTitle, "Final")
        XCTAssertEqual(presentations[0].providerTitle, "Not recorded")
        XCTAssertEqual(presentations[0].modelTitle, "Not recorded")
        XCTAssertEqual(presentations[1].providerTitle, "Recorded")
        XCTAssertEqual(presentations[1].modelTitle, "Configured")
        XCTAssertEqual(
            presentations[0].errorMessage,
            "Video creation hit a problem. If the final video was not completed, credits will not be charged. Please try again or contact support."
        )
    }

    func testRenderJobPresentationPreservesSafeFailedUserMessage() {
        let presentation = MomentsInProgressRenderJobPresentation(
            renderJob: makeRenderJob(
                id: "final",
                kind: "final",
                status: "failed",
                updatedAt: 20,
                userMessage: "We couldn’t finish this video. No credits were charged.",
                errorMessage: "provider stack trace"
            )
        )

        XCTAssertEqual(presentation.errorMessage, "We couldn’t finish this video. No credits were charged.")
    }

    private func makeArtifact(
        id: String,
        kind: String,
        status: String,
        hasWatermark: Bool = false,
        expiresAt: Double = 1_781_592_000_000
    ) -> MomentArtifact {
        MomentArtifact(
            id: id,
            kind: kind,
            r2Key: "animateav/\(id).mp4",
            status: status,
            hasWatermark: hasWatermark,
            expiresAt: expiresAt
        )
    }

    private func makeRenderJob(
        id: String,
        kind: String,
        status: String,
        updatedAt: Double,
        provider: String? = "mock-provider",
        model: String? = "mock-model",
        userMessage: String? = nil,
        errorMessage: String? = nil
    ) -> MomentRenderJob {
        MomentRenderJob(
            id: id,
            kind: kind,
            status: status,
            userMessage: userMessage,
            workflowRunId: "workflow-\(id)",
            provider: provider,
            model: model,
            providerRequestId: "request-\(id)",
            errorCode: status == "failed" ? "provider_failed" : nil,
            errorMessage: status == "failed" ? (errorMessage ?? "Render failed.") : errorMessage,
            createdAt: updatedAt - 1,
            updatedAt: updatedAt
        )
    }
}
