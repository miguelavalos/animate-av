import Foundation

struct MomentsInProgressPresentation: Equatable {
    let availability: MomentsInProgressAvailability
    let deletionMessage: String

    static func make(
        isSignedIn: Bool,
        momentsSummary: InProgressMomentsSummary,
        momentPendingDeletion: InProgressMoment?
    ) -> MomentsInProgressPresentation {
        MomentsInProgressPresentation(
            availability: MomentsInProgressAvailability.make(
                isSignedIn: isSignedIn,
                momentsSummary: momentsSummary
            ),
            deletionMessage: L10n.string("inProgress.deleteMoment.message", momentPendingDeletion?.title ?? L10n.string("moment.this"))
        )
    }
}

enum MomentsInProgressAvailability: Equatable {
    case signedOut(MomentsInProgressUnavailablePresentation)
    case empty(MomentsInProgressUnavailablePresentation)
    case available

    static func make(
        isSignedIn: Bool,
        momentsSummary: InProgressMomentsSummary
    ) -> MomentsInProgressAvailability {
        if !isSignedIn {
            return .signedOut(
                MomentsInProgressUnavailablePresentation(
                    systemImage: "person.crop.circle.fill",
                    title: L10n.string("inProgress.signIn.title"),
                    message: L10n.string("inProgress.signIn.message")
                )
            )
        }

        if !momentsSummary.hasMoments {
            return .empty(
                MomentsInProgressUnavailablePresentation(
                    systemImage: "rectangle.stack.badge.plus",
                    title: L10n.string("inProgress.empty.title"),
                    message: L10n.string("inProgress.empty.message")
                )
            )
        }

        return .available
    }
}

struct MomentsInProgressUnavailablePresentation: Equatable {
    let systemImage: String
    let title: String
    let message: String
}
