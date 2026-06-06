import AVAppShellFoundation
import AVBrandFoundation
import AVPaywallFoundation
import SwiftUI

struct MomentsCreditsPaywallView: View {
    @Environment(\.openURL) private var openURL

    let balance: MomentsCreditBalance
    let isSignedIn: Bool
    let startSignInFlow: () -> Void
    let claimPromotionCode: (String) async throws -> Int
    let purchaseCatalog: MomentsPurchaseCatalog
    let isPurchaseCatalogLoading: Bool
    let purchaseCatalogErrorMessage: String?
    let loadPurchaseProducts: () async -> Void
    let purchaseProduct: (MomentsCreditPaywallProduct) async throws -> MomentsPurchaseResult
    let restorePurchases: () async throws -> MomentsPurchaseResult
    let dismiss: () -> Void

    @State private var promoCode = ""
    @State private var statusMessage: String?
    @State private var promoStatusMessage: String?
    @State private var isClaimingPromo = false
    @State private var purchasingProductID: String?
    @State private var isRestoringPurchases = false
    @State private var showsBalanceDetails = false
    @State private var showsPromoClaim = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AVBrandSpacing.md) {
                    header
                    balanceOverview

                    if isSignedIn {
                        purchaseCatalogStatus
                        if purchasesAreAvailable {
                            monthlyPlan
                            creditPacks
                            restoreAndLegal
                        }
                        promoClaim
                    } else {
                        signInRequired
                    }

                    if let statusMessage {
                        AVPaywallStatusRow(systemImage: "info.circle.fill", message: statusMessage)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 24)
            }
            .background(MomentsTheme.shellBackground.ignoresSafeArea())
            .navigationTitle(L10n.string("credits.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("common.done"), action: dismiss)
                }
            }
        }
        .accessibilityIdentifier("moments.credits.paywall")
        .task(id: isSignedIn) {
            guard isSignedIn else { return }
            await loadPurchaseProducts()
        }
    }

    private var header: some View {
        AVPaywallHeader(
            eyebrow: L10n.string("paywall.header.eyebrow"),
            title: L10n.string("paywall.header.title"),
            subtitle: isSignedIn
                ? L10n.string("paywall.header.subtitle.signedIn")
                : L10n.string("paywall.header.subtitle.guest"),
            titleFontSize: 26,
            subtitleFontSize: 13
        )
    }

    private var balanceOverview: some View {
        VStack(alignment: .leading, spacing: AVBrandSpacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.string("paywall.wallet.title"))
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(AVBrandColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                Text(L10n.string("paywall.wallet.startAt"))
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(AVBrandColor.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            MomentsCreditsPrimaryBalanceTile(title: L10n.string("credits.videoCredits.title"), value: balance.spendable, detail: balanceTitle)

            if isSignedIn {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        showsBalanceDetails.toggle()
                    }
                } label: {
                    Label(showsBalanceDetails ? L10n.string("paywall.wallet.hideDetails") : L10n.string("paywall.wallet.viewDetails"), systemImage: showsBalanceDetails ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(AVBrandColor.textSecondary)
                }
                .buttonStyle(.plain)

                if showsBalanceDetails {
                    HStack(spacing: AVBrandSpacing.sm) {
                        ForEach(MomentsCreditCopy.detailRows(for: balance)) { row in
                            MomentsCreditsBalanceTile(row: row)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(AVBrandSpacing.md)
        .background(AVBrandColor.cardSurface, in: RoundedRectangle(cornerRadius: AVBrandRadius.card, style: .continuous))
        .shadow(color: AVBrandColor.softShadow.opacity(0.14), radius: 12, y: 6)
    }

    private var creditPacks: some View {
        VStack(spacing: AVBrandSpacing.sm) {
            sectionHeader(title: L10n.string("paywall.oneTime.title"), detail: L10n.string("paywall.oneTime.detail"))

            HStack(spacing: AVBrandSpacing.sm) {
                MomentsCreditsPackButton(
                    product: .starterPack,
                    priceText: priceText(for: .starterPack),
                    isBusy: purchasingProductID == MomentsCreditProductID.starterPackProduct,
                    isDisabled: isPurchaseActionDisabled
                ) {
                    startPurchase(.starterPack)
                }
                MomentsCreditsPackButton(
                    product: .creatorPack,
                    priceText: priceText(for: .creatorPack),
                    isBusy: purchasingProductID == MomentsCreditProductID.creatorPackProduct,
                    isDisabled: isPurchaseActionDisabled
                ) {
                    startPurchase(.creatorPack)
                }
            }
        }
    }

    private var monthlyPlan: some View {
        VStack(alignment: .leading, spacing: AVBrandSpacing.sm) {
            sectionHeader(title: L10n.string("paywall.proMonthly.title"), detail: L10n.string("paywall.proMonthly.detail"))

            MomentsProPlanCard(
                product: .proMonthly,
                priceText: monthlyPriceText(for: .proMonthly),
                isBusy: purchasingProductID == MomentsCreditProductID.proMonthlyProduct,
                isDisabled: isPurchaseActionDisabled
            ) {
                startPurchase(.proMonthly)
            }

            AVPaywallStatusRow(
                systemImage: "calendar.badge.clock",
                message: monthlySubscriptionTerms(for: .proMonthly)
            )
            .accessibilityIdentifier("moments.credits.subscriptionTerms")
        }
    }

    private var promoClaim: some View {
        VStack(alignment: .leading, spacing: AVBrandSpacing.sm) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    showsPromoClaim.toggle()
                }
            } label: {
                HStack {
                    sectionHeader(title: L10n.string("paywall.promo.title"), detail: L10n.string("paywall.promo.detail"))
                    Spacer(minLength: AVBrandSpacing.sm)
                    Image(systemName: showsPromoClaim ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(AVBrandColor.textSecondary)
                }
            }
            .buttonStyle(.plain)

            if showsPromoClaim {
                HStack(spacing: AVBrandSpacing.sm) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(AVBrandColor.accent)

                    TextField(L10n.string("paywall.promo.placeholder"), text: $promoCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(AVBrandTypography.bodyStrong)
                        .padding(.horizontal, AVBrandSpacing.md)
                        .frame(height: 46)
                        .background(AVBrandColor.cardSurface, in: RoundedRectangle(cornerRadius: AVBrandRadius.control, style: .continuous))

                    Button(action: claimPromo) {
                        ZStack {
                            if isClaimingPromo {
                                ProgressView()
                                    .tint(AVBrandColor.textInverse)
                            } else {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 17, weight: .black))
                                    .foregroundStyle(AVBrandColor.textInverse)
                            }
                        }
                        .frame(width: 46, height: 46)
                        .background(AVBrandColor.accent, in: RoundedRectangle(cornerRadius: AVBrandRadius.control, style: .continuous))
                    }
                    .disabled(normalizedPromoCode.isEmpty || isClaimingPromo)
                    .accessibilityLabel(L10n.string("paywall.promo.claim"))
                    .accessibilityIdentifier("moments.credits.claimPromo")
                }

                Text(L10n.string("paywall.promo.optional"))
                    .font(AVBrandTypography.captionStrong)
                    .foregroundStyle(AVBrandColor.textSecondary)
            }

            if let promoStatusMessage {
                HStack(alignment: .firstTextBaseline, spacing: AVBrandSpacing.xs) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(AVBrandColor.textSecondary)

                    Text(promoStatusMessage)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 2)
            }
        }
        .padding(AVBrandSpacing.md)
        .background(AVBrandColor.mutedSurface, in: RoundedRectangle(cornerRadius: AVBrandRadius.card, style: .continuous))
    }

    private var restoreAndLegal: some View {
        VStack(spacing: AVBrandSpacing.md) {
            Text(L10n.string("paywall.legal.renewal"))
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(AVBrandColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                restorePreviousPurchases()
            } label: {
                HStack(spacing: AVBrandSpacing.xs) {
                    if isRestoringPurchases {
                        ProgressView()
                            .controlSize(.mini)
                            .tint(AVBrandColor.textSecondary)
                    }

                    Text(L10n.string("paywall.restore.title"))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AVBrandColor.textSecondary)
                }
            }
            .buttonStyle(.plain)
            .disabled(isRestoringPurchases || purchasingProductID != nil)
            .accessibilityIdentifier("moments.credits.restore")

            AVPaywallLegalLinks(
                links: [
                    AVPaywallLegalLink(title: L10n.string("paywall.terms"), accessibilityIdentifier: "moments.credits.terms") {
                        openURL(AppConfig.termsURL)
                    },
                    AVPaywallLegalLink(title: L10n.string("paywall.privacy"), accessibilityIdentifier: "moments.credits.privacy") {
                        openURL(AppConfig.privacyPolicyURL)
                    }
                ]
            )
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var purchaseCatalogStatus: some View {
        if isPurchaseCatalogLoading {
            HStack(spacing: AVBrandSpacing.xs) {
                ProgressView()
                    .controlSize(.mini)
                    .tint(AVBrandColor.textSecondary)

                Text(L10n.string("paywall.loadingPrices"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(AVBrandColor.textSecondary)
            }
            .padding(AVBrandSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AVBrandColor.mutedSurface, in: RoundedRectangle(cornerRadius: AVBrandRadius.control, style: .continuous))
        } else if let purchaseCatalogErrorMessage, !purchaseCatalogErrorMessage.isEmpty {
            AVPaywallStatusRow(systemImage: "info.circle.fill", message: purchaseCatalogErrorMessage)
                .accessibilityIdentifier("moments.credits.purchasesUnavailable")
        } else if !purchaseCatalog.hasRequiredPaywallProducts {
            AVPaywallStatusRow(systemImage: "info.circle.fill", message: L10n.string("paywall.purchasesUnavailable"))
                .accessibilityIdentifier("moments.credits.purchasesUnavailable")
        }
    }

    private func sectionHeader(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundStyle(AVBrandColor.textPrimary)

            Text(detail)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AVBrandColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var signInRequired: some View {
        VStack(alignment: .leading, spacing: AVBrandSpacing.md) {
            Text(L10n.string("paywall.signIn.title"))
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(AVBrandColor.textPrimary)

            Text(L10n.string("paywall.signIn.detail"))
                .font(AVBrandTypography.body)
                .foregroundStyle(AVBrandColor.textSecondary)

            AVAppShellPrimaryButton(L10n.string("paywall.signIn.button"), systemImage: "person.crop.circle.badge.checkmark") {
                dismiss()
                startSignInFlow()
            }
            .accessibilityIdentifier("moments.credits.signIn")
        }
        .padding(AVBrandSpacing.lg)
        .background(AVBrandColor.cardSurface, in: RoundedRectangle(cornerRadius: AVBrandRadius.card, style: .continuous))
    }

    private var balanceTitle: String {
        if balance.spendable == 0 {
            return L10n.string("paywall.balance.noCredits")
        }
        return MomentsCreditCopy.availableTitle(balance)
    }

    private var normalizedPromoCode: String {
        promoCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isPurchaseActionDisabled: Bool {
        purchasingProductID != nil
            || isRestoringPurchases
            || isPurchaseCatalogLoading
            || purchaseCatalogErrorMessage != nil
            || !purchaseCatalog.hasRequiredPaywallProducts
    }

    private var purchasesAreAvailable: Bool {
        !isPurchaseCatalogLoading
            && purchaseCatalogErrorMessage == nil
            && purchaseCatalog.hasRequiredPaywallProducts
    }

    private func priceText(for product: MomentsCreditPaywallProduct) -> String {
        purchaseCatalog.localizedPrice(for: product) ?? product.buttonTitle
    }

    private func monthlyPriceText(for product: MomentsCreditPaywallProduct) -> String {
        guard let price = purchaseCatalog.localizedPrice(for: product) else {
            return product.buttonTitle
        }
        return L10n.string("paywall.price.month", price)
    }

    private func monthlySubscriptionTerms(for product: MomentsCreditPaywallProduct) -> String {
        let price = purchaseCatalog.localizedPrice(for: product) ?? L10n.string("paywall.price.appStore")
        return L10n.string("paywall.subscription.terms", price)
    }

    private func startPurchase(_ product: MomentsCreditPaywallProduct) {
        guard !isPurchaseActionDisabled else { return }
        purchasingProductID = product.id
        statusMessage = nil

        Task {
            do {
                let result = try await purchaseProduct(product)
                switch result.status {
                case .purchased:
                    statusMessage = L10n.string("paywall.purchase.purchased", product.title)
                case .restored:
                    statusMessage = L10n.string("paywall.purchase.restored")
                case .cancelled:
                    statusMessage = L10n.string("paywall.purchase.cancelled")
                }
            } catch {
                statusMessage = purchaseErrorMessage(error)
            }
            purchasingProductID = nil
        }
    }

    private func restorePreviousPurchases() {
        guard !isRestoringPurchases, purchasingProductID == nil else { return }
        isRestoringPurchases = true
        statusMessage = nil

        Task {
            do {
                let result = try await restorePurchases()
                switch result.status {
                case .restored:
                    statusMessage = L10n.string("paywall.purchase.restored")
                case .purchased:
                    statusMessage = L10n.string("paywall.purchase.restoredSingle")
                case .cancelled:
                    statusMessage = L10n.string("paywall.restore.cancelled")
                }
            } catch {
                statusMessage = purchaseErrorMessage(error)
            }
            isRestoringPurchases = false
        }
    }

    private func claimPromo() {
        guard !normalizedPromoCode.isEmpty else { return }
        let code = normalizedPromoCode
        isClaimingPromo = true
        promoStatusMessage = nil

        Task {
            do {
                let creditsGranted = try await claimPromotionCode(code)
                promoStatusMessage = L10n.string("paywall.promo.added", MomentsCreditCopy.countTitle(creditsGranted))
                promoCode = ""
                if creditsGranted > 0 {
                    dismiss()
                }
            } catch {
                promoStatusMessage = error.localizedDescription
            }
            isClaimingPromo = false
        }
    }

    private func purchaseErrorMessage(_ error: Error) -> String {
        if let error = error as? MomentsPurchaseError {
            return error.localizedDescription
        }
        return L10n.string("purchase.error.offeringUnavailable")
    }
}

private struct MomentsProPlanCard: View {
    let product: MomentsCreditPaywallProduct
    let priceText: String
    let isBusy: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AVBrandSpacing.md) {
                HStack(alignment: .top, spacing: AVBrandSpacing.md) {
                    Image(systemName: product.systemImage)
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(AVBrandColor.textInverse)
                        .frame(width: 44, height: 44)
                        .background(AVBrandColor.accent, in: RoundedRectangle(cornerRadius: AVBrandRadius.control, style: .continuous))

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: AVBrandSpacing.xs) {
                            Text(product.eyebrow)
                                .font(AVBrandTypography.eyebrow)
                                .foregroundStyle(AVBrandColor.accent)
                                .textCase(.uppercase)

                            Text(L10n.string("paywall.pro.noWatermark"))
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundStyle(AVBrandColor.textInverse)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(AVBrandColor.accent, in: Capsule())
                        }

                        Text(product.title)
                            .font(.system(size: 23, weight: .black, design: .rounded))
                            .foregroundStyle(AVBrandColor.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)

                        Text(priceText)
                            .font(.system(size: 19, weight: .black, design: .rounded))
                            .foregroundStyle(AVBrandColor.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.82)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text(product.detail)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: AVBrandSpacing.xs) {
                    MomentsProBenefitRow(systemImage: "video.fill", text: L10n.string("paywall.pro.benefit.videoCredits"))
                    MomentsProBenefitRow(systemImage: "checkmark.seal.fill", text: L10n.string("paywall.pro.benefit.noWatermark"))
                }

                HStack(spacing: AVBrandSpacing.sm) {
                    Text(callToActionTitle)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(AVBrandColor.textInverse)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Spacer()

                    if isBusy {
                        ProgressView()
                            .controlSize(.small)
                            .tint(AVBrandColor.textInverse)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .black))
                            .foregroundStyle(AVBrandColor.textInverse)
                    }
                }
                .padding(.horizontal, AVBrandSpacing.md)
                .frame(height: 48)
                .background(AVBrandColor.accent, in: RoundedRectangle(cornerRadius: AVBrandRadius.control, style: .continuous))
            }
            .padding(AVBrandSpacing.lg)
            .background(AVBrandColor.cardSurface, in: RoundedRectangle(cornerRadius: AVBrandRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AVBrandRadius.card, style: .continuous)
                    .stroke(AVBrandColor.accent.opacity(0.28), lineWidth: 1)
            }
            .shadow(color: AVBrandColor.softShadow.opacity(0.18), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityIdentifier("moments.credits.purchase.\(product.id)")
    }

    private var callToActionTitle: String {
        switch product.kind {
        case .subscription:
            return priceText == product.buttonTitle ? product.buttonTitle : L10n.string("paywall.product.continueFor", priceText)
        case .consumableCredits:
            return priceText == product.buttonTitle ? product.buttonTitle : L10n.string("paywall.product.buyFor", product.buttonTitle, priceText)
        }
    }
}

private struct MomentsProBenefitRow: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(spacing: AVBrandSpacing.xs) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(AVBrandColor.accent)
                .frame(width: 18)

            Text(text)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(AVBrandColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct MomentsCreditsPackButton: View {
    let product: MomentsCreditPaywallProduct
    let priceText: String
    let isBusy: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AVBrandSpacing.xs) {
                HStack(alignment: .top) {
                    Image(systemName: product.systemImage)
                        .font(.system(size: 15, weight: .black))
                        .foregroundStyle(AVBrandColor.accent)

                    Spacer(minLength: AVBrandSpacing.xs)

                    Text(priceText)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(AVBrandColor.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Text(product.title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(AVBrandColor.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                Text(product.detail)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(AVBrandColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: AVBrandSpacing.xs)

                HStack(spacing: AVBrandSpacing.xs) {
                    Text(product.buttonTitle)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(AVBrandColor.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    if isBusy {
                        ProgressView()
                            .controlSize(.mini)
                            .tint(AVBrandColor.accent)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(AVBrandColor.accent)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 128, alignment: .topLeading)
            .padding(AVBrandSpacing.md)
            .background(AVBrandColor.cardSurface, in: RoundedRectangle(cornerRadius: AVBrandRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AVBrandRadius.card, style: .continuous)
                    .stroke(AVBrandColor.borderSubtle.opacity(0.5), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .accessibilityIdentifier("moments.credits.purchase.\(product.id)")
    }
}

private struct MomentsCreditsPrimaryBalanceTile: View {
    let title: String
    let value: Int
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AVBrandColor.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text("\(value)")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(AVBrandColor.textPrimary)
                .monospacedDigit()

            Text(detail)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AVBrandColor.accent)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AVBrandSpacing.md)
        .background(AVBrandColor.mutedSurface, in: RoundedRectangle(cornerRadius: AVBrandRadius.md, style: .continuous))
    }
}

private struct MomentsCreditsBalanceTile: View {
    let row: MomentsCreditDetailRow

    var body: some View {
        VStack(alignment: .leading, spacing: AVBrandSpacing.xxs) {
            Text("\(row.value)")
                .font(.system(size: 21, weight: .black, design: .rounded))
                .foregroundStyle(AVBrandColor.textPrimary)

            Text(row.title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(AVBrandColor.textSecondary)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AVBrandSpacing.sm)
        .background(AVBrandColor.mutedSurface, in: RoundedRectangle(cornerRadius: AVBrandRadius.md, style: .continuous))
    }
}
