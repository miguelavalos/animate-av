import XCTest
@testable import AnimateAV

final class AnimateInProgressProgressModelTests: XCTestCase {
    func testEmptyWorkspaceMarksVideoCreatedAndRemainingStepsWaiting() {
        let model = AnimateInProgressProgressModel(workspace: makeWorkspace())

        XCTAssertEqual(model.phases.map(\.title), ["Video", "Photo", "Direction", "Create Video"])
        XCTAssertEqual(model.phases.map(\.state), [.complete, .waiting, .waiting, .waiting])
        XCTAssertEqual(model.phases.map(\.detail), [
            "In Progress",
            "No photo yet",
            "Not ready",
            "Not created"
        ])
    }

    func testRenderJobStatusDrivesFinalProgressUntilArtifactIsAvailable() {
        let model = AnimateInProgressProgressModel(
            workspace: makeWorkspace(renderJobs: [makeRenderJob(kind: "final", status: "running")])
        )

        let final = model.phases.first { $0.title == "Create Video" }
        XCTAssertEqual(final?.state, .active)
        XCTAssertEqual(final?.detail, "Running")
    }

    func testAvailableFinalExportArtifactCompletesFinalProgress() {
        let model = AnimateInProgressProgressModel(
            workspace: makeWorkspace(
                renderJobs: [makeRenderJob(kind: "final", status: "failed")],
                artifacts: [makeArtifact(kind: "final_export", status: "available")]
            )
        )

        let final = model.phases.first { $0.title == "Create Video" }
        XCTAssertEqual(final?.state, .complete)
        XCTAssertEqual(final?.detail, "Available")
    }

    private func makeWorkspace(
        mediaAssets: [AnimateMediaAsset] = [],
        storyScenes: [AnimateVideoDirectionScene] = [],
        renderJobs: [AnimateRenderJob] = [],
        artifacts: [AnimateArtifact] = []
    ) -> AnimateWorkspace {
        AnimateWorkspace(
            video: makeVideo(id: "video-1", status: "in_progress", updatedAt: 10),
            mediaAssets: mediaAssets,
            storyScenes: storyScenes,
            renderJobs: renderJobs,
            artifacts: artifacts
        )
    }

    private func makeVideo(id: String, status: String, updatedAt: Double) -> AnimateVideo {
        AnimateVideo(
            id: id,
            template: .birthdayMessage,
            status: status,
            title: id,
            tone: nil,
            tempo: nil,
            occasion: nil,
            details: nil,
            durationSeconds: 30,
            creditCost: 2,
            updatedAt: updatedAt
        )
    }

    private func makeArtifact(kind: String, status: String) -> AnimateArtifact {
        AnimateArtifact(
            id: "\(kind)-1",
            kind: kind,
            r2Key: "animateav/user/video/\(kind).mp4",
            status: status,
            hasWatermark: false,
            expiresAt: 1_781_592_000_000
        )
    }

    private func makeRenderJob(kind: String, status: String) -> AnimateRenderJob {
        AnimateRenderJob(
            id: "\(kind)-job-1",
            kind: kind,
            status: status,
            workflowRunId: "workflow-1",
            provider: "mock-provider",
            model: "mock-model",
            providerRequestId: "provider-request-1",
            errorCode: status == "failed" ? "provider_failed" : nil,
            errorMessage: status == "failed" ? "Render failed." : nil,
            createdAt: 1_779_000_000_000,
            updatedAt: 1_779_000_001_000
        )
    }
}
