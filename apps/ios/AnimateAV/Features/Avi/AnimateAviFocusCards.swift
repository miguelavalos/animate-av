import AVAviFoundation
import SwiftUI

struct AnimateAviCurrentFocusCard: View {
    let workflowFocusTitle: String
    let workflowFocusMessage: String
    let workflowFocusSystemImage: String
    let momentsSummary: InProgressMomentsSummary
    let creditBalance: AnimateCreditBalance
    let creditBalanceLoadState: AnimateCreditBalanceLoadState

    var body: some View {
        AVAviGuidanceCard(
            title: L10n.string("avi.currentFocus.title"),
            detail: L10n.string("avi.currentFocus.detail")
        ) {
            AVAviInfoRow(
                title: workflowFocusTitle,
                detail: workflowFocusMessage,
                systemImage: workflowFocusSystemImage
            )

            HStack(spacing: 10) {
                AVAviStatPill(
                    title: L10n.string("avi.stat.active"),
                    value: "\(momentsSummary.inProgressCount)",
                    systemImage: "clock"
                )
                AVAviStatPill(
                    title: L10n.string("library.finished.title"),
                    value: "\(momentsSummary.finishedCount)",
                    systemImage: "checkmark.circle"
                )
                AVAviStatPill(
                    title: L10n.string("credits.title"),
                    value: creditValue,
                    systemImage: creditBalanceLoadState.systemImage
                )
                .redacted(reason: creditBalanceLoadState.isLoading ? .placeholder : [])
            }
        }
    }

    private var creditValue: String {
        guard creditBalanceLoadState.hasLoadedBalance else {
            return creditBalanceLoadState == .signedOut ? "--" : "..."
        }
        return "\(creditBalance.spendable)"
    }
}

struct AnimateAviCreditGuidanceCard: View {
    let message: String

    var body: some View {
        AVAviGuidanceCard(
            title: L10n.string("avi.creditGuidance.title"),
            detail: L10n.string("avi.creditGuidance.detail")
        ) {
            HStack(spacing: 10) {
                AVAviStatPill(title: L10n.string("avi.creditOrder.first"), value: L10n.string("credits.proMonthly.title"), systemImage: "calendar")
                AVAviStatPill(title: L10n.string("avi.creditOrder.then"), value: L10n.string("credits.purchased.title"), systemImage: "creditcard")
                AVAviStatPill(title: L10n.string("avi.creditOrder.then"), value: L10n.string("credits.other.title"), systemImage: "gift")
            }
            Text(message)
                .foregroundStyle(.secondary)
        }
    }
}
