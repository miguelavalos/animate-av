import Foundation

struct AnimateInProgressListPresentation: Equatable {
    let summaryPills: [AnimateInProgressSummaryPresentation]
    let groups: [AnimateInProgressListGroupPresentation]

    static func make(
        videosSummary: AnimateInProgressSummary,
        selectedVideoId: String?
    ) -> AnimateInProgressListPresentation {
        AnimateInProgressListPresentation(
            summaryPills: [
                AnimateInProgressSummaryPresentation(
                    title: L10n.string("inProgress.summary.total"),
                    value: videosSummary.videoCount,
                    systemImage: "rectangle.stack"
                ),
                AnimateInProgressSummaryPresentation(
                    title: L10n.string("inProgress.summary.active"),
                    value: videosSummary.inProgressCount,
                    systemImage: "clock"
                ),
                AnimateInProgressSummaryPresentation(
                    title: L10n.string("inProgress.summary.done"),
                    value: videosSummary.finishedCount,
                    systemImage: "checkmark.circle"
                )
            ],
            groups: [
                AnimateInProgressListGroupPresentation(
                    title: L10n.string("inProgress.group.inProgress"),
                    rows: videosSummary.groups.inProgress.map {
                        AnimateInProgressListRowPresentation(video: $0, isSelected: selectedVideoId == $0.id)
                    }
                ),
                AnimateInProgressListGroupPresentation(
                    title: L10n.string("inProgress.group.finished"),
                    rows: videosSummary.groups.finished.map {
                        AnimateInProgressListRowPresentation(video: $0, isSelected: selectedVideoId == $0.id)
                    }
                )
            ].filter { !$0.rows.isEmpty }
        )
    }
}

struct AnimateInProgressSummaryPresentation: Identifiable, Equatable {
    let title: String
    let value: Int
    let systemImage: String

    var id: String { title }
}

struct AnimateInProgressListGroupPresentation: Identifiable, Equatable {
    let title: String
    let rows: [AnimateInProgressListRowPresentation]

    var id: String { title }
    var count: Int { rows.count }
}

struct AnimateInProgressListRowPresentation: Identifiable, Equatable {
    let video: AnimateVideo
    let title: String
    let statusSystemImage: String
    let isFinished: Bool
    let metadata: [AnimateInProgressListMetadataPresentation]
    let statusTitle: String
    let accessorySystemImage: String
    let isSelected: Bool

    var id: String { video.id }

    init(video: AnimateVideo, isSelected: Bool) {
        self.video = video
        self.title = video.title
        self.isFinished = AnimateStatusRules.isFinished(video)
        self.statusSystemImage = isFinished ? "checkmark.circle.fill" : "circle.dashed"
        self.metadata = [
            AnimateInProgressListMetadataPresentation(
                systemImage: "clock",
                text: AnimateVideoFormatting.updatedAt(video)
            ),
            AnimateInProgressListMetadataPresentation(
                systemImage: "text.bubble",
                text: AnimateVideoFormatting.storyUsage(video)
            )
        ]
        self.statusTitle = AnimateVideoFormatting.statusTitle(video)
        self.accessorySystemImage = isSelected ? "chevron.up.circle.fill" : "chevron.right.circle"
        self.isSelected = isSelected
    }
}

struct AnimateInProgressListMetadataPresentation: Identifiable, Equatable {
    let systemImage: String
    let text: String

    var id: String { "\(systemImage)-\(text)" }
}
