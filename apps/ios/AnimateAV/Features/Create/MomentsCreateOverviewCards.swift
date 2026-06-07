import AVAppShellFoundation
import AVBrandFoundation
import SwiftUI

struct MomentsCreateIntroCard: View {
    let isSignedIn: Bool

    var body: some View {
        AVAppShellCard {
            AVAppShellContentHeader(
                title: L10n.string("create.intro.title"),
                detail: L10n.string("create.intro.detail")
            )
            AVStatusPill(title: isSignedIn ? L10n.string("create.status.ready") : L10n.string("create.status.loginRequired"), isUppercased: false)
        }
    }
}

struct MomentsCreateActiveMomentCard: View {
    let activeMoment: InProgressMoment?

    var body: some View {
        if let activeMoment {
            AVAppShellCard {
                AVAppShellInfoRow(
                    title: activeMoment.title,
                    detail: AnimateVideoFormatting.updatedAt(activeMoment),
                    systemImage: "rectangle.stack",
                    eyebrow: AnimateVideoFormatting.statusTitle(activeMoment)
                )
            }
        }
    }
}

struct MomentsCreateContinuationHintCard: View {
    let focus: MomentsContinuationFocus?
    let dismiss: () -> Void

    var body: some View {
        if let focus {
            AVAppShellCard {
                AVAppShellInfoRow(
                    title: focus.title,
                    detail: focus.message,
                    systemImage: focus.systemImage
                ) {
                    Button(action: dismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel(L10n.string("create.continuation.dismiss"))
                }
            }
        }
    }
}

struct MomentsCreateCreditsCard: View {
    let balance: AnimateCreditBalance

    var body: some View {
        AVAppShellCard {
            AVAppShellContentHeader(
                title: L10n.string("credits.available.title"),
                detail: L10n.string("create.credits.detail")
            )
            AVAppShellInfoRow(
                title: AnimateCreditCopy.countTitle(balance.spendable),
                detail: balance.spendable > 0 ? L10n.string("create.credits.ready") : L10n.string("create.credits.setupNow"),
                systemImage: "creditcard"
            )
        }
    }
}

struct MomentsCurrentCreationCard: View {
    let selectedCount: Int
    let continueCreation: () -> Void

    var body: some View {
        Button(action: continueCreation) {
            AVAppShellCard {
                HStack(spacing: 12) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AVBrandColor.accent)
                        .frame(width: 38, height: 38)
                        .background(AVBrandColor.accent.opacity(0.10), in: Circle())

                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.string("create.current.continue"))
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(AVBrandColor.textPrimary)
                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(AVBrandColor.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AVBrandColor.textSecondary)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var detail: String {
        selectedCount == 0
            ? L10n.string("create.current.addMedia")
            : L10n.string("create.current.selected", selectedCount)
    }
}

private extension MomentsContinuationFocus {
    var title: String {
        switch self {
        case .moment:
            L10n.string("create.continuation.moment.title")
        case .media:
            L10n.string("create.continuation.media.title")
        case .story:
            L10n.string("create.continuation.story.title")
        case .finalRender:
            L10n.string("create.continuation.final.title")
        }
    }

    var message: String {
        switch self {
        case .moment:
            L10n.string("create.continuation.moment.message")
        case .media:
            L10n.string("create.continuation.media.message")
        case .story:
            L10n.string("create.continuation.story.message")
        case .finalRender:
            L10n.string("create.continuation.final.message")
        }
    }

    var systemImage: String {
        switch self {
        case .moment:
            "rectangle.stack"
        case .media:
            "photo.badge.plus"
        case .story:
            "text.bubble"
        case .finalRender:
            "square.and.arrow.up"
        }
    }
}
