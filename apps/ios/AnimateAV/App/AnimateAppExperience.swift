import AVBrandFoundation
import AVSettingsFoundation
import Foundation

enum AnimateAppExperience {
    private static let appIdentity = AVAppIdentity(
        displayName: "Animate AV",
        assistantName: "Avi",
        accountName: "Account AV"
    )

    @MainActor
    static var experience: AVCommonAppExperience {
        AVCommonAppExperience(
            identity: appIdentity,
            legalLinks: legalLinks,
            brandPalette: AnimateTheme.brandPalette,
            visualAssets: visualAssets,
            splashTagline: L10n.string("app.splash.tagline"),
            splashStatus: L10n.string("app.splash.status"),
            onboardingTitle: L10n.string("app.onboarding.title"),
            onboardingSubtitle: L10n.string("app.onboarding.subtitle"),
            onboardingPrimaryTitle: L10n.string("app.onboarding.signIn"),
            onboardingSecondaryTitle: L10n.string("app.onboarding.skip"),
            onboardingBackgroundStart: .init(red: 0.97, green: 0.94, blue: 0.86),
            onboardingBackgroundMid: AVBrandColor.neutral50,
            onboardingBackgroundEnd: .init(red: 0.9, green: 0.93, blue: 0.89)
        )
    }

    static var identity: AVAppIdentity {
        appIdentity
    }

    static var visualAssets: AVCommonAppVisualAssets {
        AVCommonAppVisualAssets(
            headerLogoName: "AnimateHeaderWordmark",
            splashLogoName: "AnimateAVLogo",
            splashHeroName: "AnimateSplashHero",
            onboardingBrandName: "AnimateHeaderWordmark",
            onboardingHeroName: "AnimateOnboardingHero",
            onboardingCTACompanionName: "AviOnboardingCTA",
            onboardingAuthPanelCompanionName: "AviLoginSheetPeek",
            footerAssistantName: "AviFooterIcon"
        )
    }

    @MainActor
    static var legalLinks: AVAppLegalLinks {
        AVAppLegalLinks(
            supportURL: AppConfig.supportURL,
            privacyURL: AppConfig.privacyPolicyURL,
            termsURL: AppConfig.termsURL,
            accountDeletionURL: AppConfig.accountDeletionURL
        )
    }

    static var settingsSubtitle: String {
        L10n.string("app.settings.subtitle", identity.shortName)
    }

    static var accountSubtitle: String {
        L10n.string("app.account.subtitle", identity.accountName)
    }
}
