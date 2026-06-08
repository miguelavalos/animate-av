enum AnimateCreditCopy {
    static let monthlyCreditsIncluded = 6

    static func noun(_ count: Int) -> String {
        count == 1 ? L10n.string("credits.noun.one") : L10n.string("credits.noun.other")
    }

    static func countTitle(_ count: Int) -> String {
        L10n.string("credits.countTitle", count, noun(count))
    }

    static func availableTitle(_ balance: AnimateCreditBalance) -> String {
        countTitle(balance.spendable)
    }

    static func availableDetail(_ balance: AnimateCreditBalance) -> String {
        balance.spendable == 0
            ? L10n.string("credits.available.none")
            : L10n.string("credits.available.detail", availableTitle(balance))
    }

    static func walletSubtitle(_ balance: AnimateCreditBalance) -> String {
        guard let summary = balance.walletSummary else {
            return availableDetail(balance)
        }

        let available = countTitle(summary.credits.available)
        if summary.plan.isProActive {
            let plan = planTitle(summary.plan)
            return L10n.string("credits.wallet.subtitle.pro", plan, available)
        }

        return L10n.string("credits.wallet.subtitle.free", available)
    }

    static func accessDetail(_ balance: AnimateCreditBalance) -> String {
        guard let summary = balance.walletSummary else {
            return availableDetail(balance)
        }

        if summary.plan.isProActive {
            return planTitle(summary.plan)
        }

        return L10n.string("profile.summary.plan.detail.free")
    }

    static func balanceStatusTitle(_ loadState: AnimateCreditBalanceLoadState) -> String {
        switch loadState {
        case .signedOut:
            L10n.string("credits.balance.signedOut.title")
        case .loading:
            L10n.string("credits.balance.loading.title")
        case .loaded:
            L10n.string("credits.available.title")
        case .offline:
            L10n.string("credits.balance.offline.title")
        case .unavailable:
            L10n.string("credits.balance.unavailable.title")
        }
    }

    static func balanceStatusDetail(_ loadState: AnimateCreditBalanceLoadState) -> String {
        switch loadState {
        case .signedOut:
            L10n.string("credits.balance.signedOut.detail")
        case .loading:
            L10n.string("credits.balance.loading.detail")
        case .loaded:
            L10n.string("credits.home.ready")
        case .offline:
            L10n.string("credits.balance.offline.detail")
        case .unavailable:
            L10n.string("credits.balance.unavailable.detail")
        }
    }

    static func balanceStatusDetail(
        _ loadState: AnimateCreditBalanceLoadState,
        balance: AnimateCreditBalance
    ) -> String {
        loadState.hasLoadedBalance ? availableDetail(balance) : balanceStatusDetail(loadState)
    }

    static func proMonthlyDetail(_ balance: AnimateCreditBalance) -> String {
        guard let summary = balance.walletSummary else {
            return L10n.string("credits.proMonthly.detail", balance.proMonthly, monthlyCreditsIncluded)
        }

        if summary.plan.includesMonthlyCredits {
            return L10n.string(
                "credits.proMonthly.period.detail",
                summary.period.remainingIncludedCredits,
                summary.period.includedCredits,
                summary.period.usedCredits
            )
        }

        if summary.plan.isProActive {
            return L10n.string("credits.proMonthly.promo.detail")
        }

        return L10n.string("credits.proMonthly.none.detail")
    }

    static func purchasedDetail(_ balance: AnimateCreditBalance) -> String {
        if let summary = balance.walletSummary {
            return L10n.string("credits.purchased.detail", summary.credits.purchasedTotal)
        }
        return L10n.string("credits.purchased.detail", balance.purchased)
    }

    static func otherDetail(_ balance: AnimateCreditBalance) -> String {
        if let summary = balance.walletSummary {
            return L10n.string("credits.other.detail", summary.credits.promoGrantedTotal)
        }
        return L10n.string("credits.other.detail", balance.promotional)
    }

    static func detailRows(for balance: AnimateCreditBalance) -> [AnimateCreditDetailRow] {
        if let summary = balance.walletSummary {
            var rows = [
                AnimateCreditDetailRow(
                    id: "availableNow",
                    title: L10n.string("credits.availableNow.title"),
                    value: summary.credits.available,
                    detail: L10n.string("credits.availableNow.detail", countTitle(summary.credits.available)),
                    systemImage: "creditcard"
                ),
                AnimateCreditDetailRow(
                    id: "reserved",
                    title: L10n.string("credits.reserved.title"),
                    value: summary.credits.reserved,
                    detail: L10n.string("credits.reserved.detail", summary.credits.reserved),
                    systemImage: "lock"
                ),
                AnimateCreditDetailRow(
                    id: "periodUsed",
                    title: L10n.string("credits.periodUsed.title"),
                    value: summary.period.usedCredits,
                    detail: periodDetail(summary),
                    systemImage: "calendar"
                )
            ]

            if summary.plan.isProActive {
                rows.append(
                    AnimateCreditDetailRow(
                        id: "plan",
                        title: L10n.string("credits.plan.title"),
                        value: summary.plan.includesMonthlyCredits ? summary.period.remainingIncludedCredits : summary.credits.available,
                        detail: summary.plan.includesMonthlyCredits
                            ? proMonthlyDetail(balance)
                            : L10n.string("credits.plan.promo.detail"),
                        systemImage: "sparkles.rectangle.stack"
                    )
                )
            }

            return rows
        }

        return [
            AnimateCreditDetailRow(
                id: "proMonthly",
                title: L10n.string("credits.proMonthly.title"),
                value: balance.proMonthly,
                detail: proMonthlyDetail(balance),
                systemImage: "sparkles.rectangle.stack"
            ),
            AnimateCreditDetailRow(
                id: "purchased",
                title: L10n.string("credits.purchased.title"),
                value: balance.purchased,
                detail: purchasedDetail(balance),
                systemImage: "creditcard"
            ),
            AnimateCreditDetailRow(
                id: "other",
                title: L10n.string("credits.other.title"),
                value: balance.promotional,
                detail: otherDetail(balance),
                systemImage: "gift"
            )
        ]
    }

    private static func planTitle(_ plan: AnimateCreditWalletSummary.Plan) -> String {
        switch plan.source {
        case "subscription":
            return L10n.string("credits.plan.pro.subscription")
        case "promo":
            if let expiresAt = plan.expiresAt {
                return L10n.string("credits.plan.pro.promoUntil", shortDate(expiresAt))
            }
            return L10n.string("credits.plan.pro.promo")
        default:
            return L10n.string("profile.summary.plan.detail.pro")
        }
    }

    private static func periodDetail(_ summary: AnimateCreditWalletSummary) -> String {
        if summary.plan.includesMonthlyCredits {
            return L10n.string(
                "credits.periodUsed.subscription.detail",
                summary.period.usedCredits,
                summary.period.includedCredits,
                shortDate(summary.period.endsAt)
            )
        }

        return L10n.string("credits.periodUsed.detail", summary.period.usedCredits)
    }

    private static func shortDate(_ isoDate: String) -> String {
        String(isoDate.prefix(10))
    }
}

struct AnimateCreditDetailRow: Identifiable, Equatable {
    let id: String
    let title: String
    let value: Int
    let detail: String
    let systemImage: String
}
