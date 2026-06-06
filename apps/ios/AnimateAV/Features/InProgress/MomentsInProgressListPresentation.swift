import Foundation

struct MomentsInProgressListPresentation: Equatable {
    let summaryPills: [InProgressMomentsSummaryPresentation]
    let groups: [MomentsInProgressListGroupPresentation]

    static func make(
        momentsSummary: InProgressMomentsSummary,
        selectedMomentId: String?
    ) -> MomentsInProgressListPresentation {
        MomentsInProgressListPresentation(
            summaryPills: [
                InProgressMomentsSummaryPresentation(
                    title: L10n.string("inProgress.summary.total"),
                    value: momentsSummary.momentCount,
                    systemImage: "rectangle.stack"
                ),
                InProgressMomentsSummaryPresentation(
                    title: L10n.string("inProgress.summary.active"),
                    value: momentsSummary.inProgressCount,
                    systemImage: "clock"
                ),
                InProgressMomentsSummaryPresentation(
                    title: L10n.string("inProgress.summary.done"),
                    value: momentsSummary.finishedCount,
                    systemImage: "checkmark.circle"
                )
            ],
            groups: [
                MomentsInProgressListGroupPresentation(
                    title: L10n.string("inProgress.group.inProgress"),
                    rows: momentsSummary.groups.inProgress.map {
                        MomentsInProgressListRowPresentation(moment: $0, isSelected: selectedMomentId == $0.id)
                    }
                ),
                MomentsInProgressListGroupPresentation(
                    title: L10n.string("inProgress.group.finished"),
                    rows: momentsSummary.groups.finished.map {
                        MomentsInProgressListRowPresentation(moment: $0, isSelected: selectedMomentId == $0.id)
                    }
                )
            ].filter { !$0.rows.isEmpty }
        )
    }
}

struct InProgressMomentsSummaryPresentation: Identifiable, Equatable {
    let title: String
    let value: Int
    let systemImage: String

    var id: String { title }
}

struct MomentsInProgressListGroupPresentation: Identifiable, Equatable {
    let title: String
    let rows: [MomentsInProgressListRowPresentation]

    var id: String { title }
    var count: Int { rows.count }
}

struct MomentsInProgressListRowPresentation: Identifiable, Equatable {
    let moment: InProgressMoment
    let title: String
    let statusSystemImage: String
    let isFinished: Bool
    let metadata: [MomentsInProgressListMetadataPresentation]
    let statusTitle: String
    let accessorySystemImage: String
    let isSelected: Bool

    var id: String { moment.id }

    init(moment: InProgressMoment, isSelected: Bool) {
        self.moment = moment
        self.title = moment.title
        self.isFinished = MomentStatusRules.isFinished(moment)
        self.statusSystemImage = isFinished ? "checkmark.circle.fill" : "circle.dashed"
        self.metadata = [
            MomentsInProgressListMetadataPresentation(
                systemImage: "clock",
                text: MomentsMomentFormatting.updatedAt(moment)
            ),
            MomentsInProgressListMetadataPresentation(
                systemImage: "text.bubble",
                text: MomentsMomentFormatting.storyUsage(moment)
            )
        ]
        self.statusTitle = MomentsMomentFormatting.statusTitle(moment)
        self.accessorySystemImage = isSelected ? "chevron.up.circle.fill" : "chevron.right.circle"
        self.isSelected = isSelected
    }
}

struct MomentsInProgressListMetadataPresentation: Identifiable, Equatable {
    let systemImage: String
    let text: String

    var id: String { "\(systemImage)-\(text)" }
}
