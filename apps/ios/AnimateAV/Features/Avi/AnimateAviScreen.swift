import AVAviFoundation
import AVAppShellFoundation
import AVSettingsFoundation
import SwiftUI

struct AnimateAviScreen: View {
    let selectTab: (AnimateRootTab) -> Void
    let startMoment: () -> Void
    let startSignInFlow: () -> Void
    @Environment(\.avCommonAppExperience) private var appExperience
    @EnvironmentObject private var viewModel: AnimateAviViewModel

    private var presentation: AnimateAviPresentation {
        viewModel.presentation
    }

    private var landingContent: AVAviLandingContent {
        AVAviLandingContent(
            eyebrow: L10n.string("avi.landing.eyebrow"),
            title: L10n.string("avi.landing.title"),
            detail: L10n.string("avi.landing.detail"),
            chips: [
                AVAviLandingChip(title: L10n.string("avi.landing.choose"), systemImage: "photo.on.rectangle"),
                AVAviLandingChip(title: L10n.string("avi.landing.story"), systemImage: "text.bubble"),
                AVAviLandingChip(title: L10n.string("avi.landing.create"), systemImage: "video.fill")
            ],
            accessibilityIdentifier: "animate.avi.hero"
        )
    }

    var body: some View {
        AVAviGuidanceScreenScaffold(
            identity: appExperience.identity,
            summary: L10n.string("avi.summary"),
            status: L10n.string("avi.status"),
            headerAccessibilityIdentifier: "animate.avi.header",
            landingContent: landingContent,
            backgroundStyle: AnyShapeStyle(AnimateTheme.shellBackground)
        ) {
            EmptyView()
        } heroAvatar: {
            Image("AviFullBody")
                .resizable()
                .scaledToFit()
                .frame(width: 82, height: 82)
                .accessibilityLabel("Avi")
        } content: {
            AnimateAviGuidanceContent(
                presentation: presentation,
                momentsSummary: viewModel.momentsSummary,
                creditBalance: viewModel.creditBalance,
                creditBalanceLoadState: viewModel.creditBalanceLoadState,
                isSignedIn: viewModel.isSignedIn,
                startSignInFlow: startSignInFlow,
                startMoment: startMoment,
                selectTab: selectTab
            )
        }
    }
}

private struct AnimateAviGuidanceContent: View {
    let presentation: AnimateAviPresentation
    let momentsSummary: InProgressMomentsSummary
    let creditBalance: AnimateCreditBalance
    let creditBalanceLoadState: AnimateCreditBalanceLoadState
    let isSignedIn: Bool
    let startSignInFlow: () -> Void
    let startMoment: () -> Void
    let selectTab: (AnimateRootTab) -> Void

    var body: some View {
        if !isSignedIn {
            AnimateAviSignInCard(startSignInFlow: startSignInFlow)
        }

        AnimateAviPreparationCard(openCreate: startMoment)

        AnimateAviCurrentFocusCard(
            workflowFocusTitle: presentation.workflowFocusTitle,
            workflowFocusMessage: presentation.workflowFocusMessage,
            workflowFocusSystemImage: presentation.workflowFocusSystemImage,
            momentsSummary: momentsSummary,
            creditBalance: creditBalance,
            creditBalanceLoadState: creditBalanceLoadState
        )

        AnimateAviCreditGuidanceCard(message: presentation.creditGuidanceMessage)

        AnimateAviHelpCard()

        AnimateAviLibraryGuidanceCard {
            selectTab(.gallery)
        }
    }
}

private struct AnimateAviSignInCard: View {
    let startSignInFlow: () -> Void

    var body: some View {
        AVAppShellCard {
            VStack(alignment: .leading, spacing: 12) {
                AVAppShellContentHeader(
                    title: L10n.string("avi.signIn.title"),
                    detail: L10n.string("avi.signIn.detail")
                )

                AVAppShellActionRow(
                    title: L10n.string("common.signIn"),
                    detail: L10n.string("avi.signIn.action.detail"),
                    systemImage: "person.crop.circle.fill",
                    isProminent: true,
                    accessibilityIdentifier: "animate.avi.signin",
                    action: startSignInFlow
                )
            }
        }
    }
}
