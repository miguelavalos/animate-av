import Foundation

struct AnimateInProgressPresentation: Equatable {
    let availability: AnimateInProgressAvailability
    let deletionMessage: String

    static func make(
        isSignedIn: Bool,
        videosSummary: AnimateInProgressSummary,
        momentPendingDeletion: AnimateVideo?
    ) -> AnimateInProgressPresentation {
        AnimateInProgressPresentation(
            availability: AnimateInProgressAvailability.make(
                isSignedIn: isSignedIn,
                videosSummary: videosSummary
            ),
            deletionMessage: L10n.string("inProgress.deleteVideo.message", momentPendingDeletion?.title ?? L10n.string("moment.this"))
        )
    }
}

enum AnimateInProgressAvailability: Equatable {
    case signedOut(AnimateInProgressUnavailablePresentation)
    case empty(AnimateInProgressUnavailablePresentation)
    case available

    static func make(
        isSignedIn: Bool,
        videosSummary: AnimateInProgressSummary
    ) -> AnimateInProgressAvailability {
        if !isSignedIn {
            return .signedOut(
                AnimateInProgressUnavailablePresentation(
                    systemImage: "person.crop.circle.fill",
                    title: L10n.string("inProgress.signIn.title"),
                    message: L10n.string("inProgress.signIn.message")
                )
            )
        }

        if !videosSummary.hasVideos {
            return .empty(
                AnimateInProgressUnavailablePresentation(
                    systemImage: "rectangle.stack.badge.plus",
                    title: L10n.string("inProgress.empty.title"),
                    message: L10n.string("inProgress.empty.message")
                )
            )
        }

        return .available
    }
}

struct AnimateInProgressUnavailablePresentation: Equatable {
    let systemImage: String
    let title: String
    let message: String
}
