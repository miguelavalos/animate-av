import Foundation

enum CreditSource: String, CaseIterable {
    case proMonthly
    case promotional
    case purchased

    var title: String {
        switch self {
        case .proMonthly: L10n.string("credits.proMonthly.title")
        case .promotional: L10n.string("credits.promotional.title")
        case .purchased: L10n.string("credits.purchased.title")
        }
    }
}

struct AnimateCreditBalance: Equatable {
    var proMonthly: Int
    var promotional: Int
    var purchased: Int
    var availableCredits: Int?
    var walletSummary: AnimateCreditWalletSummary?
    var watermarkRemovalCreditCost: Int = 1
    var watermarkFreeIncluded: Bool = false

    static let empty = AnimateCreditBalance(proMonthly: 0, promotional: 0, purchased: 0)

    var spendable: Int {
        availableCredits ?? (proMonthly + promotional + purchased)
    }

    func amount(for source: CreditSource) -> Int {
        switch source {
        case .proMonthly: proMonthly
        case .promotional: promotional
        case .purchased: purchased
        }
    }
}

struct AnimateCreditWalletSummary: Decodable, Equatable {
    let plan: Plan
    let period: Period
    let credits: Credits

    struct Plan: Decodable, Equatable {
        let tier: String
        let status: String
        let source: String
        let expiresAt: String?
        let includesMonthlyCredits: Bool

        var isProActive: Bool {
            tier == "pro" && status == "active"
        }
    }

    struct Period: Decodable, Equatable {
        let startsAt: String
        let endsAt: String
        let includedCredits: Int
        let usedCredits: Int
        let remainingIncludedCredits: Int
    }

    struct Credits: Decodable, Equatable {
        let available: Int
        let reserved: Int
        let purchasedTotal: Int
        let promoGrantedTotal: Int
        let subscriptionGrantedTotal: Int
    }
}

struct AnimateCreditSpendPlan: Equatable {
    let proMonthly: Int
    let promotional: Int
    let purchased: Int

    var total: Int {
        proMonthly + promotional + purchased
    }
}

enum AnimateCreditGate {
    static func canAfford(_ template: AnimateVideoTemplate, balance: AnimateCreditBalance) -> Bool {
        balance.spendable >= template.creditCost
    }

    static func canAffordAny(_ templates: [AnimateVideoTemplate], balance: AnimateCreditBalance) -> Bool {
        templates.contains { canAfford($0, balance: balance) }
    }

    static func spendPlan(for cost: Int, balance: AnimateCreditBalance) -> AnimateCreditSpendPlan? {
        guard cost > 0, balance.spendable >= cost else { return nil }

        let proMonthlySpend = min(balance.proMonthly, cost)
        let afterPro = cost - proMonthlySpend
        let promotionalSpend = min(balance.promotional, afterPro)
        let purchasedSpend = afterPro - promotionalSpend

        return AnimateCreditSpendPlan(
            proMonthly: proMonthlySpend,
            promotional: promotionalSpend,
            purchased: purchasedSpend
        )
    }
}
