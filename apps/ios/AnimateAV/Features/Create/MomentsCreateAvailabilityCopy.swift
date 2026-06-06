import Foundation

enum MomentsCreateAvailabilityCopy {
    static var momentSignInRequired: String { L10n.string("create.availability.momentSignInRequired") }
    static var momentSyncNotConfigured: String { L10n.string("create.availability.momentSyncNotConfigured") }
    static var mediaMissingMoment: String { L10n.string("create.availability.mediaMissingMoment") }
    static var mediaUploadNotConfigured: String { L10n.string("create.availability.mediaUploadNotConfigured") }
    static var mediaTemplateFull: String { L10n.string("create.availability.mediaTemplateFull") }
    static var storySignInRequired: String { L10n.string("create.availability.storySignInRequired") }
    static var storyMissingMoment: String { L10n.string("create.availability.storyMissingMoment") }
    static var storyUnavailable: String { L10n.string("create.availability.storyUnavailable") }
    static var storyNotConfigured: String { L10n.string("create.availability.storyNotConfigured") }
    static var storyMissingMedia: String { L10n.string("create.availability.storyMissingMedia") }
    static var finalRenderMissingMoment: String { L10n.string("create.availability.finalRenderMissingMoment") }
    static var finalRenderUnavailable: String { L10n.string("create.availability.finalRenderUnavailable") }
    static var finalRenderNotConfigured: String { L10n.string("create.availability.finalRenderNotConfigured") }
    static var finalRenderMissingWorkspace: String { L10n.string("create.availability.finalRenderMissingWorkspace") }

    static func finalRenderCreditBalanceUnavailable(_ loadState: MomentsCreditBalanceLoadState) -> String {
        switch loadState {
        case .loading:
            L10n.string("create.availability.finalRenderCreditsLoading")
        case .offline:
            L10n.string("create.availability.finalRenderCreditsOffline")
        case .unavailable:
            L10n.string("create.availability.finalRenderCreditsUnavailable")
        case .signedOut:
            momentSignInRequired
        case .loaded:
            ""
        }
    }

    static func finalRenderInsufficientCredits(missingCredits: Int) -> String {
        L10n.string("create.availability.finalRenderInsufficientCredits", missingCredits, MomentsCreditCopy.noun(missingCredits))
    }
}
