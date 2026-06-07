import Foundation
import RevenueCat

struct AnimatePurchaseCatalog: Equatable {
    struct Entry: Equatable {
        let productId: String
        let packageIdentifier: String
        let localizedTitle: String
        let localizedPrice: String
    }

    var entriesByProductId: [String: Entry]

    static let empty = AnimatePurchaseCatalog(entriesByProductId: [:])

    var hasRequiredPaywallProducts: Bool {
        AnimateCreditPaywallProduct.all.allSatisfy { entry(for: $0) != nil }
    }

    func entry(for product: AnimateCreditPaywallProduct) -> Entry? {
        entriesByProductId[product.id]
    }

    func localizedPrice(for product: AnimateCreditPaywallProduct) -> String? {
        entry(for: product)?.localizedPrice
    }
}

struct AnimatePurchaseResult: Equatable {
    enum Status: Equatable {
        case purchased
        case restored
        case cancelled
    }

    let status: Status
    let productId: String?
    let transactionId: String?
}

enum AnimatePurchaseError: LocalizedError, Equatable {
    case notConfigured
    case offeringUnavailable
    case productUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return L10n.string("purchase.error.notConfigured")
        case .offeringUnavailable:
            return L10n.string("purchase.error.offeringUnavailable")
        case .productUnavailable:
            return L10n.string("purchase.error.productUnavailable")
        }
    }
}

@MainActor
protocol AnimatePurchaseServicing {
    func loadCatalog(userId: String) async throws -> AnimatePurchaseCatalog
    func purchase(productId: String, userId: String) async throws -> AnimatePurchaseResult
    func restorePurchases(userId: String) async throws -> AnimatePurchaseResult
    func logOut() async
}

@MainActor
final class RevenueCatAnimatePurchaseService: AnimatePurchaseServicing {
    private let apiKeyProvider: () -> String
    private let offeringIDProvider: () -> String
    private let monthlyPackageIDProvider: () -> String
    private var packagesByProductId: [String: Package] = [:]

    init(
        apiKeyProvider: @escaping () -> String = { AppConfig.revenueCatPublicAPIKey },
        offeringIDProvider: @escaping () -> String = { AppConfig.revenueCatOfferingID },
        monthlyPackageIDProvider: @escaping () -> String = { AppConfig.revenueCatMonthlyPackageID }
    ) {
        self.apiKeyProvider = apiKeyProvider
        self.offeringIDProvider = offeringIDProvider
        self.monthlyPackageIDProvider = monthlyPackageIDProvider
    }

    func loadCatalog(userId: String) async throws -> AnimatePurchaseCatalog {
        AnimateCreditsDiagnostics.addBreadcrumb(operation: "load_catalog")
        do {
            try await configureIfNeeded(userId: userId)
            let offering = try await animateOffering()
            let catalog = catalog(from: offering)
            AnimateCreditsDiagnostics.addBreadcrumb(
                operation: "catalog_loaded",
                data: ["product_count": String(catalog.entriesByProductId.count)]
            )
            return catalog
        } catch {
            AnimateCreditsDiagnostics.capture(error, operation: "load_catalog", step: "catalog")
            throw error
        }
    }

    func purchase(productId: String, userId: String) async throws -> AnimatePurchaseResult {
        AnimateCreditsDiagnostics.addBreadcrumb(
            operation: "purchase",
            data: ["product_key": AnimateCreditsDiagnostics.productKey(for: productId)]
        )
        do {
            try await configureIfNeeded(userId: userId)

            if packagesByProductId[productId] == nil {
                _ = try await loadCatalog(userId: userId)
            }

            guard let package = packagesByProductId[productId] else {
                throw AnimatePurchaseError.productUnavailable(productId)
            }

            let result = try await Purchases.shared.purchase(package: package)
            guard !result.userCancelled else {
                AnimateCreditsDiagnostics.addBreadcrumb(
                    operation: "purchase_cancelled",
                    data: ["product_key": AnimateCreditsDiagnostics.productKey(for: productId)]
                )
                return AnimatePurchaseResult(status: .cancelled, productId: productId, transactionId: nil)
            }

            AnimateCreditsDiagnostics.addBreadcrumb(
                operation: "purchase_completed",
                data: ["product_key": AnimateCreditsDiagnostics.productKey(for: productId)]
            )
            return AnimatePurchaseResult(
                status: .purchased,
                productId: result.transaction?.productIdentifier ?? productId,
                transactionId: result.transaction?.transactionIdentifier
            )
        } catch {
            AnimateCreditsDiagnostics.capture(
                error,
                operation: "purchase",
                step: "revenuecat",
                data: ["product_key": AnimateCreditsDiagnostics.productKey(for: productId)]
            )
            throw error
        }
    }

    func restorePurchases(userId: String) async throws -> AnimatePurchaseResult {
        AnimateCreditsDiagnostics.addBreadcrumb(operation: "restore")
        do {
            try await configureIfNeeded(userId: userId)
            _ = try await Purchases.shared.restorePurchases()
            AnimateCreditsDiagnostics.addBreadcrumb(operation: "restore_completed")
            return AnimatePurchaseResult(status: .restored, productId: nil, transactionId: nil)
        } catch {
            AnimateCreditsDiagnostics.capture(error, operation: "restore", step: "revenuecat")
            throw error
        }
    }

    func logOut() async {
        guard Purchases.isConfigured else { return }
        packagesByProductId = [:]
        _ = try? await Purchases.shared.logOut()
    }

    private func configureIfNeeded(userId: String) async throws {
        let apiKey = apiKeyProvider().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else {
            throw AnimatePurchaseError.notConfigured
        }

        if Purchases.isConfigured {
            if Purchases.shared.appUserID != userId {
                _ = try await Purchases.shared.logIn(userId)
                packagesByProductId = [:]
            }
            return
        }

        Purchases.configure(withAPIKey: apiKey, appUserID: userId)
    }

    private func animateOffering() async throws -> Offering {
        let offerings: Offerings
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            AnimateCreditsDiagnostics.capture(error, operation: "load_catalog", step: "offerings")
            throw AnimatePurchaseError.offeringUnavailable
        }
        let offeringID = offeringIDProvider().trimmingCharacters(in: .whitespacesAndNewlines)
        if !offeringID.isEmpty, let offering = offerings.offering(identifier: offeringID) {
            return offering
        }
        if let current = offerings.current {
            return current
        }
        throw AnimatePurchaseError.offeringUnavailable
    }

    private func catalog(from offering: Offering) -> AnimatePurchaseCatalog {
        var packagesByProductId: [String: Package] = [:]
        for package in offering.availablePackages where packagesByProductId[package.storeProduct.productIdentifier] == nil {
            packagesByProductId[package.storeProduct.productIdentifier] = package
        }
        self.packagesByProductId = packagesByProductId
        cacheConfiguredMonthlyPackage(from: offering)

        return AnimatePurchaseCatalog(
            entriesByProductId: self.packagesByProductId.mapValues { package in
                AnimatePurchaseCatalog.Entry(
                    productId: package.storeProduct.productIdentifier,
                    packageIdentifier: package.identifier,
                    localizedTitle: package.storeProduct.localizedTitle,
                    localizedPrice: package.localizedPriceString
                )
            }
        )
    }

    private func cacheConfiguredMonthlyPackage(from offering: Offering) {
        let monthlyPackageID = monthlyPackageIDProvider().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !monthlyPackageID.isEmpty,
              let package = offering.availablePackages.first(where: {
                  $0.identifier == monthlyPackageID &&
                  $0.storeProduct.productIdentifier == AnimateCreditProductID.proMonthlyProduct
              }) else {
            return
        }
        packagesByProductId[AnimateCreditProductID.proMonthlyProduct] = package
    }
}

private enum AnimateCreditsDiagnostics {
    static func addBreadcrumb(operation: String, data: [String: String] = [:]) {
        AnimateWorkflowDiagnostics.addBreadcrumb(
            feature: "animate.credits",
            operation: operation,
            data: data
        )
    }

    static func capture(
        _ error: any Error,
        operation: String,
        step: String,
        data: [String: String] = [:]
    ) {
        AnimateWorkflowDiagnostics.capture(
            error,
            feature: "animate.credits",
            operation: operation,
            step: step,
            data: data
        )
    }

    static func productKey(for productId: String) -> String {
        switch productId {
        case AnimateCreditProductID.starterPackProduct:
            return "starter_pack"
        case AnimateCreditProductID.creatorPackProduct:
            return "creator_pack"
        case AnimateCreditProductID.proMonthlyProduct:
            return "pro_monthly"
        default:
            return "unknown"
        }
    }
}
