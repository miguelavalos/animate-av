import AVAviFoundation
import AVAppShellFoundation
import AVBrandFoundation
import AVSettingsFoundation
import SwiftUI

struct AnimateHomeScreen: View {
    @EnvironmentObject private var viewModel: AnimateHomeViewModel
    @EnvironmentObject private var createViewModel: AnimateCreateViewModel

    let openSettings: () -> Void
    let openAccount: () -> Void
    let startSignInFlow: () -> Void
    let openCredits: () -> Void
    let retryCredits: () -> Void
    let selectTab: (AnimateRootTab) -> Void
    let startVideoCreation: () -> Void
    let continueVideo: (AnimateContinuationRequest) -> Void
    private var videosSummary: AnimateInProgressSummary { viewModel.videosSummary }
    private var presentation: AnimateHomePresentation {
        AnimateHomePresentation.make(
            isSignedIn: viewModel.isSignedIn,
            displayName: viewModel.displayName,
            videosSummary: videosSummary
        )
    }

    init(
        openSettings: @escaping () -> Void,
        openAccount: @escaping () -> Void,
        startSignInFlow: @escaping () -> Void,
        openCredits: @escaping () -> Void,
        retryCredits: @escaping () -> Void,
        selectTab: @escaping (AnimateRootTab) -> Void,
        startVideoCreation: @escaping () -> Void,
        continueVideo: @escaping (AnimateContinuationRequest) -> Void
    ) {
        self.openSettings = openSettings
        self.openAccount = openAccount
        self.startSignInFlow = startSignInFlow
        self.openCredits = openCredits
        self.retryCredits = retryCredits
        self.selectTab = selectTab
        self.startVideoCreation = startVideoCreation
        self.continueVideo = continueVideo
    }

    var body: some View {
        AVAppShellScrollableScreenScaffold {
            AnimateTheme.shellBackground
        } content: {
            AVAppShellHomeHeader(
                title: L10n.string("home.header.title"),
                subtitle: L10n.string("home.header.subtitle")
            ) {
                AVAppShellConfiguredBrandHeader(
                    activeItem: nil,
                    openSettings: openSettings,
                    openAccount: openAccount
                )
            } content: {
                AnimateHomeAviContextCard(
                    title: aviContextTitle,
                    detail: aviContextDetail,
                    buttonTitle: aviContextButtonTitle,
                    hasVideoContext: createViewModel.hasRecoverableMomentContext,
                    isSignedIn: viewModel.isSignedIn,
                    action: viewModel.isSignedIn ? startVideoCreation : startSignInFlow
                )
            }

            if viewModel.isSignedIn {
                AnimateHomeAccountCard(
                    creditBalance: viewModel.creditBalance,
                    creditBalanceLoadState: viewModel.creditBalanceLoadState,
                    openCredits: openCredits,
                    retryCredits: retryCredits
                )
            } else {
                AnimateHomeSignInCard(startSignInFlow: startSignInFlow)
            }

            AnimateHomeVideoStatusCard(
                isSignedIn: viewModel.isSignedIn,
                videosSummary: videosSummary,
                presentation: presentation,
                openInProgress: { selectTab(.inProgress) }
            )

            AnimateHomeNextActionsCard(
                presentation: presentation,
                continueVideo: continueVideo,
                startVideoCreation: startVideoCreation,
                selectTab: selectTab
            )
        }
    }

    @Environment(\.avCommonAppExperience) private var appExperience

    private var aviContextTitle: String {
        guard viewModel.isSignedIn else { return L10n.string("home.avi.signIn.title") }
        if createViewModel.hasRecoverableMomentContext {
            if createViewModel.finalRenderSummary.latestFinalJob != nil || createViewModel.finalRenderSummary.isGenerating {
                return L10n.string("home.avi.creating.title")
            }
            if createViewModel.videoDirectionSummary.isPlanning {
                return L10n.string("home.avi.preparing.title")
            }
            return L10n.string("home.avi.currentVideo.title")
        }
        return L10n.string("home.avi.createVideo.title")
    }

    private var aviContextDetail: String {
        guard viewModel.isSignedIn else {
            return L10n.string("home.avi.signIn.detail")
        }
        if createViewModel.hasRecoverableMomentContext {
            let count = createViewModel.mediaSelectedCount
            if createViewModel.finalRenderSummary.latestFinalJob != nil || createViewModel.finalRenderSummary.isGenerating {
                return createViewModel.finalRenderSummary.statusMessage ?? L10n.string("home.avi.creating.detail")
            }
            if createViewModel.videoDirectionSummary.isPlanning {
                return L10n.string("home.avi.preparing.detail")
            }
            if count > 0 {
                return L10n.string("home.avi.selected.detail", count, count == 1 ? L10n.string("media.item.one") : L10n.string("media.item.other"))
            }
            return L10n.string("home.avi.addMedia.detail")
        }
        return L10n.string("home.avi.createVideo.detail")
    }

    private var aviContextButtonTitle: String {
        guard viewModel.isSignedIn else { return L10n.string("common.signIn") }
        return createViewModel.hasRecoverableMomentContext ? L10n.string("common.continue") : L10n.string("common.create")
    }
}

private struct AnimateHomeAviContextCard: View {
    let title: String
    let detail: String
    let buttonTitle: String
    let hasVideoContext: Bool
    let isSignedIn: Bool
    let action: () -> Void

    private var actionSystemImage: String {
        if !isSignedIn { return "person.crop.circle" }
        return hasVideoContext ? "video.fill" : "plus"
    }

    var body: some View {
        Button(action: action) {
            AVAppShellCard {
                HStack(spacing: 14) {
                    Image("AviFullBody")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 54, height: 68)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.system(size: 15, weight: .black))
                            .foregroundStyle(AVBrandColor.textPrimary)

                        Text(detail)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AVBrandColor.textSecondary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: actionSystemImage)
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(isSignedIn ? AVBrandColor.textInverse : AVBrandColor.textPrimary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(isSignedIn ? AVBrandColor.accent : AVBrandColor.neutral100)
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("animate.home.aviContext.open")
        .accessibilityLabel("\(title). \(detail). \(buttonTitle)")
    }
}
