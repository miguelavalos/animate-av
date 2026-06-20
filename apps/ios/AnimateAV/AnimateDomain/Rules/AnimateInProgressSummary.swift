import Foundation

struct AnimateVideoGroups {
    let inProgress: [AnimateVideo]
    let finished: [AnimateVideo]
}

struct AnimateInProgressSummary: Equatable {
    var videos: [AnimateVideo] = []
    var groups = AnimateVideoGroups()
    var latestVideo: AnimateVideo?

    var videoCount: Int {
        videos.count
    }

    var inProgressCount: Int {
        groups.inProgress.count
    }

    var finishedCount: Int {
        groups.finished.count
    }

    var hasVideos: Bool {
        !videos.isEmpty
    }

    var latestAnimateVideo: AnimateVideo? {
        groups.inProgress.first
    }

    var latestContinuableVideo: AnimateVideo? {
        groups.inProgress.first(where: AnimateStatusRules.isContinuableInCreate)
    }

    var latestInProgressContinuationRequest: AnimateContinuationRequest? {
        latestContinuableVideo.map { AnimateContinuationRequest(video: $0) }
    }

    var videoSummary: AnimateInProgressSummary {
        Self.make(from: videos.filter { $0.assetKind == "video" })
    }

    var imageSummary: AnimateInProgressSummary {
        Self.make(from: videos.filter { $0.assetKind == "image" })
    }

    static func make(from videos: [AnimateVideo]) -> AnimateInProgressSummary {
        AnimateInProgressSummary(
            videos: videos,
            groups: AnimateStatusRules.group(videos),
            latestVideo: videos.max { $0.updatedAt < $1.updatedAt }
        )
    }

    func removing(videoId: String) -> AnimateInProgressSummary {
        Self.make(from: videos.filter { $0.id != videoId })
    }
}

extension AnimateVideoGroups: Equatable {
    init() {
        self.init(inProgress: [], finished: [])
    }
}
