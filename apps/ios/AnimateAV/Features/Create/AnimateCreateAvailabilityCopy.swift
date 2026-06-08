import Foundation

enum AnimateCreateAvailabilityCopy {
    static var videoCreationSignInRequired: String { L10n.string("create.availability.momentSignInRequired") }
    static var videoCreationSyncNotConfigured: String { L10n.string("create.availability.momentSyncNotConfigured") }
    static var mediaMissingVideo: String { L10n.string("create.availability.mediaMissingMoment") }
    static var mediaUploadNotConfigured: String { L10n.string("create.availability.mediaUploadNotConfigured") }
    static var mediaTemplateFull: String { L10n.string("create.availability.mediaTemplateFull") }
    static var videoDirectionSignInRequired: String { L10n.string("create.availability.storySignInRequired") }
    static var videoDirectionMissingVideo: String { L10n.string("create.availability.storyMissingMoment") }
    static var videoDirectionUnavailable: String { L10n.string("create.availability.storyUnavailable") }
    static var videoDirectionNotConfigured: String { L10n.string("create.availability.storyNotConfigured") }
    static var videoDirectionMissingMedia: String { L10n.string("create.availability.storyMissingMedia") }
    static var finalRenderMissingVideo: String { L10n.string("create.availability.finalRenderMissingMoment") }
    static var finalRenderUnavailable: String { L10n.string("create.availability.finalRenderUnavailable") }
    static var finalRenderNotConfigured: String { L10n.string("create.availability.finalRenderNotConfigured") }
    static var finalRenderMissingVideoWorkspace: String { L10n.string("create.availability.finalRenderMissingWorkspace") }

    static func finalRenderCreditBalanceUnavailable(_ loadState: AnimateCreditBalanceLoadState) -> String {
        switch loadState {
        case .loading:
            L10n.string("create.availability.finalRenderCreditsLoading")
        case .offline:
            L10n.string("create.availability.finalRenderCreditsOffline")
        case .unavailable:
            L10n.string("create.availability.finalRenderCreditsUnavailable")
        case .signedOut:
            videoCreationSignInRequired
        case .loaded:
            ""
        }
    }

    static func finalRenderInsufficientCredits(missingCredits: Int) -> String {
        L10n.string("create.availability.finalRenderInsufficientCredits", missingCredits, AnimateCreditCopy.noun(missingCredits))
    }
}
