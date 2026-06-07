import Foundation

struct AnimateVideoGroups {
    let inProgress: [AnimateVideo]
    let finished: [AnimateVideo]
}

struct AnimateInProgressSummary: Equatable {
    var moments: [AnimateVideo] = []
    var groups = AnimateVideoGroups()
    var latestMoment: AnimateVideo?

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

    var latestAnimateVideo: AnimateVideo? {
        groups.inProgress.first
    }

    var latestInProgressContinuationRequest: AnimateContinuationRequest? {
        latestAnimateVideo.map { AnimateContinuationRequest(moment: $0) }
    }

    var videoSummary: AnimateInProgressSummary {
        Self.make(from: moments.filter { $0.assetKind == "video" })
    }

    var imageSummary: AnimateInProgressSummary {
        Self.make(from: moments.filter { $0.assetKind == "image" })
    }

    static func make(from moments: [AnimateVideo]) -> AnimateInProgressSummary {
        AnimateInProgressSummary(
            moments: moments,
            groups: AnimateStatusRules.group(moments),
            latestMoment: moments.max { $0.updatedAt < $1.updatedAt }
        )
    }

    func removing(momentId: String) -> AnimateInProgressSummary {
        Self.make(from: moments.filter { $0.id != momentId })
    }
}

extension AnimateVideoGroups: Equatable {
    init() {
        self.init(inProgress: [], finished: [])
    }
}
