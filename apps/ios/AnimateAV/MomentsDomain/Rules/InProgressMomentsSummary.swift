import Foundation

struct InProgressMomentGroups {
    let inProgress: [InProgressMoment]
    let finished: [InProgressMoment]
}

struct InProgressMomentsSummary: Equatable {
    var moments: [InProgressMoment] = []
    var groups = InProgressMomentGroups()
    var latestMoment: InProgressMoment?

    var momentCount: Int {
        moments.count
    }

    var inProgressCount: Int {
        groups.inProgress.count
    }

    var finishedCount: Int {
        groups.finished.count
    }

    var hasMoments: Bool {
        !moments.isEmpty
    }

    var latestInProgressMoment: InProgressMoment? {
        groups.inProgress.first
    }

    var latestInProgressContinuationRequest: MomentsContinuationRequest? {
        latestInProgressMoment.map { MomentsContinuationRequest(moment: $0) }
    }

    static func make(from moments: [InProgressMoment]) -> InProgressMomentsSummary {
        InProgressMomentsSummary(
            moments: moments,
            groups: MomentStatusRules.group(moments),
            latestMoment: moments.max { $0.updatedAt < $1.updatedAt }
        )
    }

    func removing(momentId: String) -> InProgressMomentsSummary {
        Self.make(from: moments.filter { $0.id != momentId })
    }
}

extension InProgressMomentGroups: Equatable {
    init() {
        self.init(inProgress: [], finished: [])
    }
}
