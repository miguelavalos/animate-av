import AVAppShellFoundation
import AVBrandFoundation
import AVSettingsFoundation
import SwiftUI

struct AnimateProfileScreen: View {
    let mode: AVAppShellChromeItem
    let openSettings: () -> Void
    let openAccount: () -> Void
    let openCredits: () -> Void
    let startSignInFlow: () -> Void

    @EnvironmentObject private var accountController: AccountController
    @EnvironmentObject private var createViewModel: AnimateCreateViewModel
    @EnvironmentObject private var inProgressViewModel: AnimateInProgressViewModel
    @EnvironmentObject private var languageController: AppLanguageController
    @EnvironmentObject private var themeController: AppThemeController
    @EnvironmentObject private var newVideoStartController: AnimateNewVideoStartController
    @Environment(\.avCommonAppExperience) private var appExperience
    @Environment(\.openURL) private var openURL
    @State private var showsCreditDetails = false
    @State private var isShowingLocalDataActions = false
    @State private var isClearingLocalData = false

    var body: some View {
        AVSettingsProfileScreenScaffold(
            title: screenTitle,
            subtitle: screenSubtitle,
            backgroundStyle: AnyShapeStyle(AnimateTheme.shellBackground),
            showsTopSafeAreaShield: true
        ) {
            AVAppShellConfiguredBrandHeader(
                activeItem: mode,
                openSettings: openSettings,
                openAccount: openAccount
            )
        } content: {
            switch mode {
            case .settings:
                settingsContent
            case .account:
                accountContent
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isShowingLocalDataActions) {
            AnimateLocalDataMaintenanceSheet(
                clearTitle: localized("profile.local.clear.title"),
                clearDetail: localized("profile.local.clear.detail"),
                onConfirmClear: clearLocalVideoData
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private var screenTitle: String {
        switch mode {
        case .settings:
            localized("profile.settingsScreen.title")
        case .account:
            localized("profile.accountScreen.title")
        }
    }

    private var screenSubtitle: String {
        switch mode {
        case .settings:
            localized("profile.settingsScreen.subtitle")
        case .account:
            localized("profile.accountScreen.subtitle")
        }
    }

    @ViewBuilder
    private var settingsContent: some View {
        appPreferencesCard
        creationPreferencesCard
        onThisDeviceCard
        helpAndLegalCard
    }

    @ViewBuilder
    private var accountContent: some View {
        accountCard
        if accountController.isSignedIn {
            creditsCard
        }
        animateProCard
        if accountController.isSignedIn {
            accountSafetyCard
        }
    }

    private var appPreferencesCard: some View {
        AVSettingsSectionCard(
            title: localized("profile.preferences.title"),
            subtitle: localized("profile.preferences.subtitle")
        ) {
            AVSettingsInfoRow(
                systemImage: "globe",
                title: localized("profile.preferences.language.title"),
                detail: localized("profile.preferences.language.detail")
            )

            languageSelector

            AVSettingsInfoRow(
                systemImage: "circle.lefthalf.filled",
                title: localized("profile.preferences.theme.title"),
                detail: localized("profile.preferences.theme.detail")
            )

            themeSelector
        }
    }

    private var creationPreferencesCard: some View {
        AVSettingsSectionCard(
            title: localized("profile.creationPreferences.title"),
            subtitle: localized("profile.creationPreferences.subtitle")
        ) {
            AVSettingsInfoRow(
                systemImage: "film.stack",
                title: localized("profile.creationPreferences.start.title"),
                detail: localized("profile.creationPreferences.start.detail")
            )

            newVideoStartSelector
        }
    }

    private var onThisDeviceCard: some View {
        AVSettingsSectionCard(
            title: localized("profile.local.title"),
            subtitle: localized("profile.local.subtitle")
        ) {
            VStack(alignment: .leading, spacing: 12) {
                AVSettingsInfoRow(
                    systemImage: "folder",
                    title: localized("profile.local.library.title"),
                    detail: localized("profile.local.library.detail")
                )
                AVSettingsInfoRow(
                    systemImage: "photo.on.rectangle.angled",
                    title: localized("profile.local.media.title"),
                    detail: localized("profile.local.media.detail")
                )
                AVSettingsInfoRow(
                    systemImage: "sparkles.rectangle.stack",
                    title: localized("profile.local.artifacts.title"),
                    detail: localized("profile.local.artifacts.detail")
                )

                AVSettingsButton(
                    title: isClearingLocalData
                        ? localized("profile.local.clear.loading")
                        : localized("profile.local.manage"),
                    style: .destructive,
                    action: { isShowingLocalDataActions = true }
                )
                .disabled(isClearingLocalData)
                .accessibilityIdentifier("profile.local.manage")
            }
        }
    }

    private var helpAndLegalCard: some View {
        AVSettingsHelpLegalSection(
            title: localized("profile.help.title"),
            subtitle: localized("profile.help.subtitle"),
            openSourceTitle: localized("profile.help.opensource.title"),
            openSourceDetail: localized("profile.help.opensource.detail"),
            sourceCodeURL: AppConfig.openSourceURL,
            sourceCodeTitle: localized("profile.help.sourceCode.title"),
            sourceCodeDetail: localized("profile.help.sourceCode.detail"),
            legalLinks: settingsLegalLinks,
            supportTitle: localized("profile.help.support.title"),
            supportDetail: localized("profile.help.support.detail"),
            privacyTitle: localized("profile.help.privacy.title"),
            privacyDetail: localized("profile.help.privacy.detail"),
            termsTitle: localized("profile.help.terms.title"),
            termsDetail: localized("profile.help.terms.detail"),
            accountDeletionTitle: "",
            accountDeletionDetail: "",
            openURL: { url in openURL(url) }
        )
    }

    private var accountCard: some View {
        AVSettingsSectionCard(
            title: localized("profile.account.title"),
            subtitle: accountIdentityDetail
        ) {
            Divider()
                .overlay(AVBrandColor.borderSubtle)

            VStack(alignment: .leading, spacing: 12) {
                AVSettingsInfoRow(
                    systemImage: "person.crop.circle",
                    title: localized("profile.summary.account.title"),
                    detail: sessionDetail
                )
                if accountController.isSignedIn, let emailAddress = accountController.user?.emailAddress {
                    AVSettingsInfoRow(
                        systemImage: "envelope",
                        title: localized("profile.account.email.title"),
                        detail: emailAddress
                    )
                }
                AVSettingsInfoRow(
                    systemImage: "sparkles.rectangle.stack",
                    title: localized("profile.summary.plan.title"),
                    detail: accessDetail
                )
            }

            accountActionButton
        }
    }

    private var creditsCard: some View {
        AVSettingsSectionCard(
            title: localized("credits.title"),
            subtitle: creditsSubtitle
        ) {
            VStack(alignment: .leading, spacing: 12) {
                AVSettingsInfoRow(
                    systemImage: accountController.creditBalanceLoadState.systemImage,
                    title: creditBalanceRowTitle,
                    detail: AnimateCreditCopy.balanceStatusDetail(
                        accountController.creditBalanceLoadState,
                        balance: accountController.creditBalance
                    )
                )
                .redacted(reason: accountController.creditBalanceLoadState.isLoading ? .placeholder : [])

                if accountController.creditBalanceLoadState.hasLoadedBalance {
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            showsCreditDetails.toggle()
                        }
                    } label: {
                        Label(
                            showsCreditDetails ? localized("paywall.wallet.hideDetails") : localized("paywall.wallet.viewDetails"),
                            systemImage: showsCreditDetails ? "chevron.up" : "chevron.down"
                        )
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                    }
                    .buttonStyle(.plain)
                }

                if showsCreditDetails, accountController.creditBalanceLoadState.hasLoadedBalance {
                    ForEach(AnimateCreditCopy.detailRows(for: accountController.creditBalance)) { row in
                        AVSettingsInfoRow(
                            systemImage: row.systemImage,
                            title: row.title,
                            detail: row.detail
                        )
                    }
                }
            }

            if !accountController.creditBalanceLoadState.isLoading {
                AVSettingsButton(
                    title: accountController.creditBalanceLoadState.hasLoadedBalance
                        ? localized("credits.getMore")
                        : localized("credits.balance.retry.title"),
                    style: .primary,
                    action: accountController.creditBalanceLoadState.hasLoadedBalance
                        ? openCredits
                        : retryCreditBalance
                )
                .accessibilityIdentifier(
                    accountController.creditBalanceLoadState.hasLoadedBalance
                        ? "profile.credits.open"
                        : "profile.credits.retry"
                )
            }
        }
    }

    private var animateProCard: some View {
        AVSettingsSectionCard(
            title: localized("profile.pro.title"),
            subtitle: animateProSubtitle
        ) {
            VStack(alignment: .leading, spacing: 12) {
                AVSettingsInfoRow(
                    systemImage: "film.stack",
                    title: proCreditsBenefitTitle,
                    detail: proCreditsBenefitDetail
                )
                AVSettingsInfoRow(
                    systemImage: "checkmark.seal.fill",
                    title: localized("profile.pro.sync.title"),
                    detail: localized("profile.pro.sync.detail")
                )
                AVSettingsInfoRow(
                    systemImage: "wand.and.stars",
                    title: localized("profile.pro.avi.title"),
                    detail: localized("profile.pro.avi.detail")
                )
            }

            if accountController.isSignedIn {
                AVSettingsButton(
                    title: localized("profile.pro.manage"),
                    style: .secondary,
                    action: { openURL(URL(string: "https://apps.apple.com/account/subscriptions")!) }
                )
            }
        }
        .accessibilityIdentifier("profile.pro.card")
    }

    private var accountSafetyCard: some View {
        AVSettingsSectionCard(
            title: localized("profile.safety.title"),
            subtitle: localized("profile.safety.subtitle"),
            spacing: 12
        ) {
            AVSettingsActionRow(
                systemImage: "exclamationmark.shield",
                title: localized("profile.safety.delete.title"),
                detail: localized("profile.safety.delete.detail"),
                action: { openURL(appExperience.legalLinks.accountDeletionURL ?? AppConfig.accountDeletionURL) }
            )
            .accessibilityIdentifier("profile.safety.delete")
        }
    }

    @ViewBuilder
    private var accountActionButton: some View {
        if accountController.isSignedIn {
            AVSettingsButton(
                title: localized("profile.actions.signOut"),
                style: .secondary,
                action: accountController.signOut
            )
            .accessibilityIdentifier("profile.account.signOut")
        } else {
            AVSettingsButton(
                title: accountController.isAccountAvailable
                    ? localized("profile.account.connect")
                    : localized("profile.account.connectUnavailable"),
                style: .primary,
                action: startSignInFlow
            )
            .disabled(!accountController.isAccountAvailable)
            .accessibilityIdentifier("profile.account.signIn")
        }
    }

    private var languageSelector: some View {
        Menu {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    languageController.select(language)
                } label: {
                    if languageController.currentLanguage == language {
                        Label {
                            Text("\(language.displayName) (\(language.autonym))")
                        } icon: {
                            Image(systemName: "checkmark")
                        }
                    } else {
                        Text("\(language.displayName) (\(language.autonym))")
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(languageController.currentLanguage.displayName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AVBrandColor.textPrimary)

                    Text(languageController.currentLanguage.autonym)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AVBrandColor.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AnimateTheme.highlight)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AVBrandColor.mutedSurface)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AVBrandColor.borderSubtle, lineWidth: 1)
            }
        }
    }

    private var themeSelector: some View {
        HStack(spacing: 10) {
            ForEach(AppTheme.allCases) { theme in
                AVSettingsOptionButton(
                    title: themeLabel(for: theme),
                    systemImage: themeSymbol(for: theme),
                    isSelected: themeController.currentTheme == theme,
                    action: { themeController.select(theme) }
                )
            }
        }
    }

    private var newVideoStartSelector: some View {
        Menu {
            ForEach(AnimateNewVideoStartPreference.allCases) { preference in
                Button {
                    newVideoStartController.select(preference)
                } label: {
                    if newVideoStartController.currentPreference == preference {
                        Label {
                            Text(preference.title)
                        } icon: {
                            Image(systemName: "checkmark")
                        }
                    } else {
                        Text(preference.title)
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: newVideoStartController.currentPreference.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AnimateTheme.highlight)
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 3) {
                    Text(newVideoStartController.currentPreference.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AVBrandColor.textPrimary)

                    Text(newVideoStartController.currentPreference.detail)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AVBrandColor.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AnimateTheme.highlight)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AVBrandColor.mutedSurface)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AVBrandColor.borderSubtle, lineWidth: 1)
            }
        }
        .accessibilityIdentifier("settings.newVideoStart")
    }

    private var accountIdentityDetail: String {
        if accountController.isSignedIn {
            return accountController.user?.emailAddress
                ?? accountController.user?.id
                ?? L10n.string("profile.account.connected", appExperience.identity.accountName)
        }
        return localized("profile.account.identity.guest")
    }

    private var sessionDetail: String {
        if accountController.isSignedIn {
            return accountController.user?.displayName
                ?? accountController.user?.emailAddress
                ?? localized("profile.account.signedInDevice")
        }
        return localized("profile.summary.account.detail.guest")
    }

    private var accessDetail: String {
        if accountController.isSignedIn {
            guard accountController.creditBalanceLoadState.hasLoadedBalance else {
                return AnimateCreditCopy.balanceStatusDetail(accountController.creditBalanceLoadState)
            }
            return AnimateCreditCopy.accessDetail(accountController.creditBalance)
        }
        return localized("profile.summary.plan.detail.guest")
    }

    private var creditsSubtitle: String {
        guard accountController.creditBalanceLoadState.hasLoadedBalance else {
            return AnimateCreditCopy.balanceStatusDetail(accountController.creditBalanceLoadState)
        }
        return AnimateCreditCopy.walletSubtitle(accountController.creditBalance)
    }

    private var creditBalanceRowTitle: String {
        guard accountController.creditBalanceLoadState.hasLoadedBalance else {
            return AnimateCreditCopy.balanceStatusTitle(accountController.creditBalanceLoadState)
        }
        return localized("credits.available.title")
    }

    private func retryCreditBalance() {
        Task {
            await accountController.refreshCreditBalance()
        }
    }

    private var animateProSubtitle: String {
        if accountController.isSignedIn {
            guard accountController.creditBalanceLoadState.hasLoadedBalance else {
                return AnimateCreditCopy.balanceStatusDetail(accountController.creditBalanceLoadState)
            }
            return AnimateCreditCopy.accessDetail(accountController.creditBalance)
        }
        return localized("profile.pro.subtitle.guest")
    }

    private var proCreditsBenefitTitle: String {
        guard accountController.creditBalance.walletSummary?.plan.includesMonthlyCredits == false else {
            return localized("profile.pro.library.title")
        }
        return localized("profile.pro.library.promo.title")
    }

    private var proCreditsBenefitDetail: String {
        guard accountController.creditBalance.walletSummary?.plan.includesMonthlyCredits == false else {
            return localized("profile.pro.library.detail")
        }
        return localized("profile.pro.library.promo.detail")
    }

    private var settingsLegalLinks: AVAppLegalLinks {
        AVAppLegalLinks(
            supportURL: appExperience.legalLinks.supportURL,
            privacyURL: appExperience.legalLinks.privacyURL,
            termsURL: appExperience.legalLinks.termsURL
        )
    }

    private func themeLabel(for theme: AppTheme) -> String {
        switch theme {
        case .system: localized("profile.preferences.theme.system")
        case .light: localized("profile.preferences.theme.light")
        case .dark: localized("profile.preferences.theme.dark")
        }
    }

    private func themeSymbol(for theme: AppTheme) -> String {
        switch theme {
        case .system: "iphone"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }

    private func clearLocalVideoData() {
        guard isClearingLocalData == false else { return }
        isClearingLocalData = true
        createViewModel.clearSessionState()
        inProgressViewModel.clearSelection()
        AnimateLocalMediaThumbnailCache.clearAll()
        isClearingLocalData = false
    }

    private func localized(_ key: String) -> String {
        L10n.string(key)
    }
}

private struct AnimateLocalDataMaintenanceSheet: View {
    let clearTitle: String
    let clearDetail: String
    let onConfirmClear: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var isShowingClearAlert = false

    var body: some View {
        AVSettingsSheetScaffold(
            backgroundStyle: AnyShapeStyle(AnimateTheme.shellBackground),
            closeTitle: L10n.string("profile.local.sheet.close"),
            onClose: { dismiss() }
        ) {
            AVSettingsSheetHeader(
                title: L10n.string("profile.local.sheet.title"),
                subtitle: L10n.string("profile.local.sheet.subtitle")
            )

            VStack(alignment: .leading, spacing: 12) {
                AVSettingsInfoRow(
                    systemImage: "photo.on.rectangle.angled",
                    title: L10n.string("profile.local.keep.photos.title"),
                    detail: L10n.string("profile.local.keep.photos.detail")
                )
                AVSettingsInfoRow(
                    systemImage: "play.rectangle",
                    title: L10n.string("profile.local.keep.gallery.title"),
                    detail: L10n.string("profile.local.keep.gallery.detail")
                )
                AVSettingsInfoRow(
                    systemImage: "cloud",
                    title: L10n.string("profile.local.keep.account.title"),
                    detail: L10n.string("profile.local.keep.account.detail")
                )
            }

            AVSettingsDestructiveActionCard(
                sectionTitle: L10n.string("profile.local.sheet.danger"),
                systemImage: "trash",
                title: clearTitle,
                detail: clearDetail,
                action: { isShowingClearAlert = true }
            )
        }
        .alert(
            L10n.string("profile.local.clear.alert.title"),
            isPresented: $isShowingClearAlert
        ) {
            Button(L10n.string("profile.local.sheet.close"), role: .cancel) {}
            Button(L10n.string("profile.local.clear.confirm"), role: .destructive) {
                onConfirmClear()
                dismiss()
            }
        } message: {
            Text(L10n.string("profile.local.clear.alert.message"))
        }
    }
}
