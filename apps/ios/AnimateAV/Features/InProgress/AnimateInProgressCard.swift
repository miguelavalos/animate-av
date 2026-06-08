import AVAppShellFoundation
import AVBrandFoundation
import AVKit
import SwiftUI

struct AnimateInProgressCard: View {
    let presentation: AnimateInProgressPresentation
    let balance: AnimateCreditBalance
    let creditBalanceLoadState: AnimateCreditBalanceLoadState
    let videosSummary: AnimateInProgressSummary
    let selectedVideoId: String?
    let isLoadingAnimateWorkspace: Bool
    let activeWorkspace: AnimateWorkspace?
    let isDeletingVideo: Bool
    let statusMessage: String?
    let localMediaForMoment: (AnimateVideo) -> [AnimateSelectedMedia]
    let selectMoment: (AnimateVideo) -> Void
    let continueVideo: (AnimateContinuationRequest) -> Void
    let requestRenameMoment: (AnimateVideo) -> Void
    let startMoment: () -> Void
    let startSignInFlow: () -> Void
    let openCredits: () -> Void
    let retryCredits: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            AnimateInProgressAviBlock(videosSummary: videosSummary)

            switch presentation.availability {
            case let .signedOut(unavailable):
                AnimateInProgressSignedOutState(
                    unavailable: unavailable,
                    startSignInFlow: startSignInFlow
                )
            case let .empty(unavailable):
                AnimateInProgressCreditStatus(
                    balance: balance,
                    creditBalanceLoadState: creditBalanceLoadState,
                    openCredits: openCredits,
                    retryCredits: retryCredits
                )
                AnimateInProgressEmptyContent(
                    unavailable: unavailable,
                    startMoment: startMoment
                )
            case .available:
                AnimateInProgressCreditStatus(
                    balance: balance,
                    creditBalanceLoadState: creditBalanceLoadState,
                    openCredits: openCredits,
                    retryCredits: retryCredits
                )
                AnimateInProgressContinueBlock(
                    videos: continueMoments,
                    localMediaForMoment: localMediaForMoment,
                    continueVideo: continueVideo,
                    requestRenameMoment: requestRenameMoment
                )
                AnimateInProgressStatusMessage(message: statusMessage)
            }
        }
    }

    private var continueMoments: [AnimateVideo] {
        videosSummary.videos.sorted { $0.updatedAt > $1.updatedAt }
    }
}

private struct AnimateInProgressCreditStatus: View {
    let balance: AnimateCreditBalance
    let creditBalanceLoadState: AnimateCreditBalanceLoadState
    let openCredits: () -> Void
    let retryCredits: () -> Void

    var body: some View {
        AVAppShellCard {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(iconColor)
                    .frame(width: 28, height: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(AVBrandColor.textPrimary)
                        .lineLimit(2)

                    Text(detail)
                        .font(AVBrandTypography.captionStrong)
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if !creditBalanceLoadState.isLoading {
                    Button(action: creditBalanceLoadState.hasLoadedBalance ? openCredits : retryCredits) {
                        Label(buttonTitle, systemImage: buttonSystemImage)
                            .font(.system(size: 13, weight: .black))
                    }
                    .buttonStyle(.bordered)
                    .padding(.top, 2)
                }
            }
            .redacted(reason: creditBalanceLoadState.isLoading ? .placeholder : [])
        }
    }

    private var systemImage: String {
        guard creditBalanceLoadState.hasLoadedBalance else {
            return creditBalanceLoadState.systemImage
        }
        return balance.spendable > 0 ? "creditcard.fill" : "exclamationmark.circle.fill"
    }

    private var iconColor: Color {
        creditBalanceLoadState.hasLoadedBalance && balance.spendable > 0 ? AVBrandColor.accent : AVBrandColor.textSecondary
    }

    private var title: String {
        guard creditBalanceLoadState.hasLoadedBalance else {
            return AnimateCreditCopy.balanceStatusTitle(creditBalanceLoadState)
        }
        return L10n.string("credits.available.detail", AnimateCreditCopy.countTitle(balance.spendable))
    }

    private var detail: String {
        guard creditBalanceLoadState.hasLoadedBalance else {
            return AnimateCreditCopy.balanceStatusDetail(creditBalanceLoadState)
        }
        return balance.spendable > 0 ? L10n.string("inProgress.credits.ready") : L10n.string("inProgress.credits.needed")
    }

    private var buttonTitle: String {
        if creditBalanceLoadState.hasLoadedBalance {
            return balance.spendable > 0 ? L10n.string("common.manage") : L10n.string("common.get")
        }
        return L10n.string("credits.balance.retry.title")
    }

    private var buttonSystemImage: String {
        if creditBalanceLoadState.hasLoadedBalance {
            return "plus.circle.fill"
        }
        return "arrow.clockwise"
    }
}

private struct AnimateInProgressSignedOutState: View {
    let unavailable: AnimateInProgressUnavailablePresentation
    let startSignInFlow: () -> Void

    var body: some View {
        AnimateInProgressInlineEmptyState(
            systemImage: unavailable.systemImage,
            title: unavailable.title,
            message: unavailable.message,
            actionTitle: L10n.string("common.signIn"),
            actionSystemImage: "person.crop.circle.fill",
            action: startSignInFlow
        )
    }
}

private struct AnimateInProgressEmptyContent: View {
    let unavailable: AnimateInProgressUnavailablePresentation
    let startMoment: () -> Void

    var body: some View {
        AnimateInProgressInlineEmptyState(
            systemImage: "photo.badge.plus",
            title: L10n.string("inProgress.empty.inProgress.title"),
            message: L10n.string("inProgress.empty.inProgress.detail"),
            actionTitle: L10n.string("inProgress.newMoment"),
            actionSystemImage: "plus",
            action: startMoment
        )
    }
}

private struct AnimateInProgressAviBlock: View {
    let videosSummary: AnimateInProgressSummary

    var body: some View {
        HStack(spacing: 16) {
            Image("AviFullBody")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .padding(6)
                .background(Circle().fill(AVBrandColor.accent.opacity(0.10)))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)
                    .lineLimit(2)

                Text(message)
                    .font(AVBrandTypography.captionStrong)
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .lineLimit(3)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AVBrandRadius.card, style: .continuous)
                .fill(AVBrandColor.elevatedSurface)
        )
    }

    private var title: String {
        if videosSummary.latestAnimateVideo != nil {
            return L10n.string("inProgress.avi.momentInProgress.title")
        }
        if videosSummary.finishedCount > 0 {
            return L10n.string("inProgress.avi.galleryStarts.title")
        }
        return L10n.string("inProgress.avi.ready.title")
    }

    private var message: String {
        if let moment = videosSummary.latestAnimateVideo {
            return L10n.string("inProgress.avi.momentInProgress.message", moment.title)
        }
        if videosSummary.finishedCount > 0 {
            return L10n.string("inProgress.avi.galleryStarts.message")
        }
        return L10n.string("inProgress.avi.ready.message")
    }
}

private struct AnimateInProgressContinueBlock: View {
    let videos: [AnimateVideo]
    let localMediaForMoment: (AnimateVideo) -> [AnimateSelectedMedia]
    let continueVideo: (AnimateContinuationRequest) -> Void
    let requestRenameMoment: (AnimateVideo) -> Void

    var body: some View {
        if videos.isEmpty {
            AnimateInProgressInlineEmptyState(
                systemImage: "photo.badge.plus",
                title: L10n.string("inProgress.empty.inProgress.title"),
                message: L10n.string("inProgress.empty.inProgress.fullDetail"),
                actionTitle: nil,
                actionSystemImage: nil,
                action: nil
            )
        } else {
            VStack(alignment: .leading, spacing: 12) {
                AVAppShellSectionHeader(title: L10n.string("inProgress.title"))

                ForEach(videos) { video in
                    AnimateAnimateVideoCard(
                        video: video,
                        localMedia: localMediaForMoment(video),
                        continueVideo: {
                            continueVideo(AnimateContinuationRequest(video: video))
                        },
                        renameVideo: {
                            requestRenameMoment(video)
                        }
                    )
                }
            }
        }
    }
}

private struct AnimateAnimateVideoCard: View {
    let video: AnimateVideo
    let localMedia: [AnimateSelectedMedia]
    let continueVideo: () -> Void
    let renameVideo: () -> Void

    var body: some View {
        Button(action: continueVideo) {
            HStack(alignment: .center, spacing: 14) {
                mediaPreview

                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(video.title)
                            .font(.system(size: 19, weight: .black))
                            .foregroundStyle(AVBrandColor.textPrimary)
                            .lineLimit(2)

                        Spacer(minLength: 0)

                        Menu {
                            Button(action: renameVideo) {
                                Label(L10n.string("common.rename"), systemImage: "pencil")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 13, weight: .black))
                                .foregroundStyle(AVBrandColor.textSecondary)
                                .frame(width: 34, height: 34)
                                .background(AVBrandColor.neutral100, in: Circle())
                        }
                    }

                    Text(AnimateStatusRules.displayTitle(for: video.status))
                        .font(AVBrandTypography.captionStrong)
                        .foregroundStyle(AVBrandColor.textSecondary)

                    HStack(spacing: 8) {
                        AnimateAnimateVideoPill(
                            systemImage: "photo.on.rectangle",
                            text: L10n.string("inProgress.card.mediaCount", effectiveMediaCount)
                        )
                        AnimateAnimateVideoPill(
                            systemImage: iconName,
                            text: AnimateVideoFormatting.updatedAt(video)
                        )
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .black))
                    .foregroundStyle(AVBrandColor.textSecondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AVBrandRadius.card, style: .continuous)
                    .fill(AVBrandColor.elevatedSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AVBrandRadius.card, style: .continuous)
                    .stroke(AVBrandColor.borderSubtle.opacity(0.55), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var mediaPreview: some View {
        if !localMedia.isEmpty {
            AnimateSharedMediaSummaryStack(localMedia: localMedia, syncedMedia: [])
        } else if video.mediaPreview.isEmpty {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AVBrandColor.accent.opacity(0.12))
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(AVBrandColor.accent)
            }
            .frame(width: 92, height: 92)
        } else {
            AnimateSharedMediaSummaryStack(localMedia: [], syncedMedia: video.mediaPreview)
        }
    }

    private var effectiveMediaCount: Int {
        if !localMedia.isEmpty {
            let selectedCount = localMedia.filter(\.selected).count
            return selectedCount > 0 ? selectedCount : localMedia.count
        }

        return video.mediaCount
    }

    private var iconName: String {
        switch video.status {
        case "final_render_pending", "final_rendering":
            "gearshape.2.fill"
        case "gallery_ready":
            "arrow.down.circle.fill"
        case "story_ready":
            "text.bubble.fill"
        default:
            "sparkles.rectangle.stack.fill"
        }
    }
}

private struct AnimateAnimateVideoPill: View {
    let systemImage: String
    let text: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.system(size: 11, weight: .black))
            .foregroundStyle(AVBrandColor.textSecondary)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(AVBrandColor.neutral100, in: Capsule())
    }
}

struct AnimateInProgressInlineEmptyState: View {
    let systemImage: String
    let title: String
    let message: String
    let actionTitle: String?
    let actionSystemImage: String?
    let action: (() -> Void)?

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .fill(AVBrandColor.accent.opacity(0.10))
                    .frame(width: 70, height: 70)
                Image(systemName: systemImage)
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(AVBrandColor.accent)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(AVBrandColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(AVBrandTypography.captionStrong)
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Label(actionTitle, systemImage: actionSystemImage ?? "plus")
                        .font(.system(size: 15, weight: .black))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                }
                .buttonStyle(.plain)
                .foregroundStyle(AVBrandColor.textInverse)
                .background(
                    Capsule(style: .continuous)
                        .fill(AVBrandColor.accent)
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AVBrandRadius.card, style: .continuous)
                .fill(AVBrandColor.elevatedSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AVBrandRadius.card, style: .continuous)
                .stroke(AVBrandColor.borderSubtle.opacity(0.55), lineWidth: 1)
        )
    }
}

private struct AnimateInProgressGalleryEmptyState: View {
    var body: some View {
        AnimateInProgressInlineEmptyState(
            systemImage: "play.square.stack.fill",
            title: L10n.string("gallery.empty.shortTitle"),
            message: L10n.string("gallery.empty.downloadDetail"),
            actionTitle: nil,
            actionSystemImage: nil,
            action: nil
        )
    }
}

private struct AnimateInProgressNoMomentsEmptyState: View {
    let startMoment: (() -> Void)?

    var body: some View {
        AnimateInProgressInlineEmptyState(
            systemImage: "photo.badge.plus",
            title: L10n.string("inProgress.empty.inProgress.title"),
            message: L10n.string("inProgress.empty.inProgress.detail"),
            actionTitle: startMoment == nil ? nil : L10n.string("inProgress.newMoment"),
            actionSystemImage: "plus",
            action: startMoment
        )
    }
}
