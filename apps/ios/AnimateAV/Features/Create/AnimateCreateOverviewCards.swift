import AVAppShellFoundation
import AVBrandFoundation
import SwiftUI

struct AnimateCurrentCreationCard: View {
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

private extension AnimateContinuationFocus {
    var title: String {
        switch self {
        case .video:
            L10n.string("create.continuation.video.title")
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
        case .video:
            L10n.string("create.continuation.video.message")
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
        case .video:
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
