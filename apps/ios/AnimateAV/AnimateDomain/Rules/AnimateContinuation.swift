import Foundation

enum AnimateContinuationFocus: Hashable {
    case video
    case media
    case story
    case finalRender
}

struct AnimateNextAction: Equatable {
    let title: String
    let message: String
    let systemImage: String
    let primaryButtonTitle: String
    let continuationFocus: AnimateContinuationFocus
}

struct AnimateContinuationRequest: Equatable {
    let video: AnimateVideo
    let focus: AnimateContinuationFocus

    init(video: AnimateVideo, focus: AnimateContinuationFocus = .video) {
        self.video = video
        self.focus = focus
    }
}
