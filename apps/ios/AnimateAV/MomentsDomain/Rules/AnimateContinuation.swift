import Foundation

enum AnimateContinuationFocus: Hashable {
    case moment
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
    let moment: AnimateVideo
    let focus: AnimateContinuationFocus

    init(moment: AnimateVideo, focus: AnimateContinuationFocus = .moment) {
        self.moment = moment
        self.focus = focus
    }
}
