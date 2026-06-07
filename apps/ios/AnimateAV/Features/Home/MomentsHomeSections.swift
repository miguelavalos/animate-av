import AVAppShellFoundation
import SwiftUI

struct MomentsHomeAccountCard: View {
    let creditBalance: MomentsCreditBalance
    let creditBalanceLoadState: MomentsCreditBalanceLoadState
    let openCredits: () -> Void
    let retryCredits: () -> Void

    var body: some View {
        AVAppShellDashboardSection(
            title: L10n.string("credits.title"),
            detail: creditDetail
        ) {
            if creditBalanceLoadState.isLoading {
                AVAppShellMetricStrip(metrics: loadingCreditMetrics)
                    .redacted(reason: .placeholder)
            } else if creditBalanceLoadState.hasLoadedBalance {
                AVAppShellMetricStrip(metrics: creditMetrics)
                AVAppShellActionRow(
                    title: creditBalance.spendable > 0 ? L10n.string("credits.manage.title") : L10n.string("credits.get.title"),
                    detail: creditBalance.spendable > 0 ? L10n.string("credits.manage.detail") : L10n.string("credits.get.detail"),
                    systemImage: creditBalance.spendable > 0 ? "creditcard.fill" : "plus.circle.fill",
                    isProminent: creditBalance.spendable == 0,
                    accessibilityIdentifier: "animate.home.credits.open",
                    action: openCredits
                )
            } else {
                AVAppShellActionRow(
                    title: L10n.string("credits.balance.retry.title"),
                    detail: L10n.string("credits.balance.retry.detail"),
                    systemImage: creditBalanceLoadState.systemImage,
                    isProminent: false,
                    accessibilityIdentifier: "animate.home.credits.retry",
                    action: retryCredits
                )
            }
        }
    }

    private var creditMetrics: [AVAppShellMetric] {
        [
            AVAppShellMetric(
                id: "spendable",
                title: L10n.string("credits.available.title"),
                value: "\(creditBalance.spendable)",
                systemImage: "creditcard"
            )
        ]
    }

    private var creditDetail: String {
        guard creditBalanceLoadState.hasLoadedBalance else {
            return MomentsCreditCopy.balanceStatusDetail(creditBalanceLoadState)
        }
        if creditBalance.spendable == 0 {
            return L10n.string("credits.home.none")
        }

        return L10n.string("credits.home.ready")
    }

    private var loadingCreditMetrics: [AVAppShellMetric] {
        [
            AVAppShellMetric(
                id: "spendable-loading",
                title: L10n.string("credits.available.title"),
                value: "...",
                systemImage: "creditcard"
            )
        ]
    }
}

struct MomentsHomeSignInCard: View {
    let startSignInFlow: () -> Void

    var body: some View {
        AVAppShellDashboardSection(
            title: L10n.string("home.signIn.title"),
            detail: L10n.string("home.signIn.detail")
        ) {
            AVAppShellActionRow(
                title: L10n.string("common.signIn"),
                detail: L10n.string("home.signIn.action.detail"),
                systemImage: "person.crop.circle.fill",
                isProminent: true,
                accessibilityIdentifier: "animate.home.signin",
                action: startSignInFlow
            )
        }
    }
}

struct MomentsHomeMomentStatusCard: View {
    let isSignedIn: Bool
    let momentsSummary: InProgressMomentsSummary
    let presentation: MomentsHomePresentation
    let openInProgress: () -> Void

    var body: some View {
        AVAppShellDashboardSection(
            title: L10n.string("library.inProgressAndGallery.title"),
            detail: presentation.momentStatusDetail
        ) {
            if let latestMoment = momentsSummary.latestMoment {
                MomentsHomeLatestMomentRow(
                    title: latestMoment.title,
                    detail: MomentsMomentFormatting.compactDetail(for: latestMoment),
                    openMoment: openInProgress
                )
            } else if isSignedIn {
                MomentsHomeEmptyMomentRow()
            }

            AVAppShellMetricStrip(metrics: momentMetrics)
        }
    }

    private var momentMetrics: [AVAppShellMetric] {
        [
            AVAppShellMetric(
                id: "in-progress",
                title: L10n.string("inProgress.title"),
                value: "\(momentsSummary.inProgressCount)",
                systemImage: "clock"
            ),
            AVAppShellMetric(
                id: "finished",
                title: L10n.string("library.finished.title"),
                value: "\(momentsSummary.finishedCount)",
                systemImage: "checkmark.circle"
            )
        ]
    }
}

struct MomentsHomeNextActionsCard: View {
    let presentation: MomentsHomePresentation
    let continueMoment: (MomentsContinuationRequest) -> Void
    let startMoment: () -> Void
    let selectTab: (MomentsRootTab) -> Void

    var body: some View {
        AVAppShellDashboardSection(
            title: L10n.string("home.nextActions.title"),
            detail: L10n.string("home.nextActions.detail")
        ) {
            VStack(spacing: 10) {
                if let latestInProgressAction = presentation.latestInProgressAction {
                    homeActionRow(
                        action: latestInProgressAction,
                        perform: continueLatestMoment
                    )
                }

                homeActionRow(action: presentation.createAction, perform: startMoment)

                homeActionRow(action: presentation.openInProgressAction) {
                    selectTab(.inProgress)
                }

                homeActionRow(action: presentation.aviGuidanceAction) {
                    selectTab(.avi)
                }
            }
        }
    }

    private func homeActionRow(action: MomentsHomeAction, perform: @escaping () -> Void) -> some View {
        AVAppShellActionRow(
            title: action.title,
            detail: action.detail,
            systemImage: action.systemImage,
            isProminent: action.isProminent,
            isDisabled: action.isDisabled,
            accessibilityIdentifier: "animate.home.action.\(action.title.lowercased().replacingOccurrences(of: " ", with: "."))",
            action: perform
        )
    }

    private func continueLatestMoment() {
        if let request = presentation.latestInProgressContinuationRequest {
            continueMoment(request)
        }
    }
}
