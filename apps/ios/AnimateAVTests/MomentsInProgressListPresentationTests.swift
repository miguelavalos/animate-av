import XCTest
@testable import AnimateAV

final class MomentsInProgressListPresentationTests: XCTestCase {
    func testSummaryPillsUseMomentsSummaryCounts() {
        let presentation = MomentsInProgressListPresentation.make(
            momentsSummary: InProgressMomentsSummary.make(from: [
                makeMoment(id: "active", status: "story_ready", updatedAt: 20),
                makeMoment(id: "done", status: "gallery_ready", updatedAt: 10)
            ]),
            selectedMomentId: nil
        )

        XCTAssertEqual(presentation.summaryPills.map(\.title), ["Total", "Active", "Done"])
        XCTAssertEqual(presentation.summaryPills.map(\.value), [2, 1, 1])
        XCTAssertEqual(presentation.summaryPills.map(\.systemImage), ["rectangle.stack", "clock", "checkmark.circle"])
    }

    func testGroupsOmitEmptySectionsAndPreserveStatusRulesOrder() {
        let presentation = MomentsInProgressListPresentation.make(
            momentsSummary: InProgressMomentsSummary.make(from: [
                makeMoment(id: "older-active", status: "in_progress", updatedAt: 10),
                makeMoment(id: "newer-active", status: "story_ready", updatedAt: 30),
                makeMoment(id: "done", status: "gallery_ready", updatedAt: 20)
            ]),
            selectedMomentId: nil
        )

        XCTAssertEqual(presentation.groups.map(\.title), ["In progress", "Finished"])
        XCTAssertEqual(presentation.groups[0].rows.map(\.id), ["newer-active", "older-active"])
        XCTAssertEqual(presentation.groups[1].rows.map(\.id), ["done"])
    }

    func testRowPresentationFormatsMomentMetadataAndSelection() {
        let moment = makeMoment(
            id: "moment-1",
            status: "story_ready",
            title: "Family Weekend",
            creditCost: 3,
        )
        let row = MomentsInProgressListRowPresentation(moment: moment, isSelected: true)

        XCTAssertEqual(row.id, "moment-1")
        XCTAssertEqual(row.title, "Family Weekend")
        XCTAssertEqual(row.statusSystemImage, "circle.dashed")
        XCTAssertFalse(row.isFinished)
        XCTAssertEqual(row.metadata.map(\.systemImage), ["clock", "text.bubble"])
        XCTAssertTrue(row.metadata[0].text.hasPrefix("Updated "))
        XCTAssertEqual(row.metadata[1].text, "Direction")
        XCTAssertEqual(row.statusTitle, "Direction ready")
        XCTAssertEqual(row.accessorySystemImage, "chevron.up.circle.fill")
    }

    func testFinishedRowUsesFinishedMarkerAndCollapsedAccessoryWhenNotSelected() {
        let row = MomentsInProgressListRowPresentation(
            moment: makeMoment(id: "done", status: "gallery_ready"),
            isSelected: false
        )

        XCTAssertTrue(row.isFinished)
        XCTAssertEqual(row.statusSystemImage, "checkmark.circle.fill")
        XCTAssertEqual(row.accessorySystemImage, "chevron.right.circle")
    }

    private func makeMoment(
        id: String,
        status: String,
        title: String? = nil,
        creditCost: Double = 2,
        updatedAt: Double = 10
    ) -> InProgressMoment {
        InProgressMoment(
            id: id,
            template: .birthdayMessage,
            status: status,
            title: title ?? id,
            tone: nil,
            tempo: nil,
            occasion: nil,
            details: nil,
            durationSeconds: 30,
            creditCost: creditCost,
            updatedAt: updatedAt
        )
    }
}
