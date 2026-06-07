import Foundation

enum AnimateCreditProductID {
    static let proMonthlyProduct = "animateav_pro_monthly"
    static let starterPackProduct = "animateav_credits_5"
    static let creatorPackProduct = "animateav_credits_20"
}

struct AnimateCreditPaywallProduct: Identifiable, Equatable {
    enum Kind: Equatable {
        case subscription
        case consumableCredits(Int)
    }

    let id: String
    let kind: Kind
    let eyebrow: String
    let title: String
    let detail: String
    let buttonTitle: String
    let systemImage: String
    let isRecommended: Bool

    static var proMonthly: AnimateCreditPaywallProduct {
        AnimateCreditPaywallProduct(
        id: AnimateCreditProductID.proMonthlyProduct,
        kind: .subscription,
        eyebrow: L10n.string("paywall.product.bestValue"),
        title: L10n.string("paywall.product.pro.title"),
        detail: L10n.string("paywall.product.pro.detail"),
        buttonTitle: L10n.string("paywall.product.pro.button"),
        systemImage: "sparkles",
        isRecommended: true
        )
    }

    static var starterPack: AnimateCreditPaywallProduct {
        AnimateCreditPaywallProduct(
        id: AnimateCreditProductID.starterPackProduct,
        kind: .consumableCredits(5),
        eyebrow: L10n.string("paywall.product.starter.eyebrow"),
        title: L10n.string("paywall.product.starter.title"),
        detail: L10n.string("paywall.product.starter.detail"),
        buttonTitle: L10n.string("paywall.product.starter.button"),
        systemImage: "plus.circle.fill",
        isRecommended: false
        )
    }

    static var creatorPack: AnimateCreditPaywallProduct {
        AnimateCreditPaywallProduct(
        id: AnimateCreditProductID.creatorPackProduct,
        kind: .consumableCredits(20),
        eyebrow: L10n.string("paywall.product.bestValue"),
        title: L10n.string("paywall.product.creator.title"),
        detail: L10n.string("paywall.product.creator.detail"),
        buttonTitle: L10n.string("paywall.product.creator.button"),
        systemImage: "square.stack.3d.up.fill",
        isRecommended: false
        )
    }

    static var all: [AnimateCreditPaywallProduct] { [
        .proMonthly,
        .starterPack,
        .creatorPack
    ] }
}
