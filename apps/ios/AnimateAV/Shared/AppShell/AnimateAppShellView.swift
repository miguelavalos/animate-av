import AVAppShellFoundation
import AVBrandFoundation
import AVSettingsFoundation
import SwiftUI
import UIKit

struct AnimateAppShellView: View {
    @Binding var selectedTab: AnimateRootTab
    let startSignInFlow: () -> Void

    @EnvironmentObject private var accountController: AccountController
    @EnvironmentObject private var createViewModel: AnimateCreateViewModel
    @EnvironmentObject private var inProgressViewModel: AnimateInProgressViewModel
    @EnvironmentObject private var galleryViewModel: AnimateGalleryViewModel
    @EnvironmentObject private var aviViewModel: AnimateAviViewModel
    @Environment(\.avCommonAppExperience) private var appExperience
    @State private var chromeItem: AVAppShellChromeItem? = AnimateUITestEnvironment.current.initialChromeItem
    @State private var creditsPaywallIsPresented = false
    @State private var navigationPath = NavigationPath()
    @State private var navigationStackResetID = UUID()
    @State private var imageDraftImage: UIImage?
    @State private var imageDraftData: Data?
    @State private var imageDraftSourceIdentifier: String?
    @State private var imageDraftLooks: Set<AnimateCreateImageLook> = []
    @State private var inProgressPreferredAssetKindRaw: String?

    var body: some View {
        adaptiveShell
            .sheet(isPresented: $creditsPaywallIsPresented) {
                AnimateCreditsPaywallView(
                    balance: accountController.creditBalance,
                    isSignedIn: accountController.isSignedIn,
                    startSignInFlow: startSignInFlow,
                    claimPromotionCode: accountController.claimPromotionCode,
                    purchaseCatalog: accountController.purchaseCatalog,
                    isPurchaseCatalogLoading: accountController.isPurchaseCatalogLoading,
                    purchaseCatalogErrorMessage: accountController.purchaseCatalogErrorMessage,
                    loadPurchaseProducts: accountController.loadPurchaseProducts,
                    purchaseProduct: accountController.purchase,
                    restorePurchases: accountController.restorePurchases,
                    dismiss: { creditsPaywallIsPresented = false }
                )
            }
            .onChange(of: createViewModel.imageGenerationQueueNonce) { _, _ in
                guard accountController.canUseAnimateImageGeneration else { return }
                clearImageDraft()
                galleryViewModel.refreshImages()
                inProgressPreferredAssetKindRaw = "images"
                selectRootTab(.inProgress)
            }
            .onChange(of: accountController.canUseAnimateImageGeneration) { _, canUseImages in
                guard !canUseImages else { return }
                redirectImageGenerationIfUnavailable()
            }
            .onAppear(perform: redirectImageGenerationIfUnavailable)
    }

    @ViewBuilder
    private var adaptiveShell: some View {
        AVAppShellAdaptiveLayoutReader { layout in
            if layout.layoutClass.isTabletLike {
                tabletShell(layout: layout)
            } else {
                compactShell
            }
        }
    }

    private var compactShell: some View {
        AVAppShellConfiguredScaffold(
            selectedTabID: footerSelectedTab,
            tabs: AnimateRootTab.footerTabs(
                canUseAnimateImageGeneration: accountController.canUseAnimateImageGeneration
            ).map(\.shellTab),
            assistantID: .avi,
            assistant: footerAssistant,
            hasAssistantActiveContext: selectedTab != .avi && hasAviActiveContext,
            footerConfiguration: footerConfiguration,
            onSelectTab: { tab in
                guard canNavigateAwayFromCurrentTab else { return }
                chromeItem = nil
                selectFooterTab(tab)
            },
            onSelectAssistant: {
                guard canNavigateAwayFromCurrentTab else { return }
                selectAssistantTab()
            },
            content: {
                NavigationStack(path: $navigationPath) {
                    screen(for: selectedTab)
                }
                .id(navigationStackResetID)
                .safeAreaPadding(.bottom, [.create, .createImage].contains(selectedTab) ? 132 : 96)
            },
            footerPlayer: {
                EmptyView()
            }
        )
        .overlay(alignment: .bottomTrailing) {
            newVideoFloatingAction(bottomPadding: 104)
        }
        .accessibilityIdentifier("animate.shell.compact")
    }

    private func tabletShell(layout: AVAppShellLayoutContext) -> some View {
        HStack(spacing: 0) {
            tabletSidebar

            Divider()

            tabletContentArea(layout: layout)
        }
        .background(AVBrandSurface.shellBackground.ignoresSafeArea())
        .accessibilityIdentifier("animate.shell.tablet")
    }

    private func tabletContentArea(layout: AVAppShellLayoutContext) -> some View {
        ZStack(alignment: .bottomTrailing) {
            NavigationStack(path: $navigationPath) {
                screen(
                    for: selectedTab,
                    isTabletLayout: true,
                    readableContentWidth: layout.readableContentWidth,
                    createBottomSafeAreaPadding: 28,
                    imageBottomSafeAreaPadding: 28
                )
            }
            .id(navigationStackResetID)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            newVideoFloatingAction(bottomPadding: 28)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var tabletSidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            tabletSidebarBrandHeader
                .padding(.bottom, 12)

            ForEach(tabletTabs) { tab in
                tabletSidebarButton(
                    tab: tab,
                    isSelected: chromeItem == nil && selectedTab == tab
                )
            }

            Spacer(minLength: 16)

            tabletChromeButton(
                title: L10n.string("profile.settingsScreen.title"),
                systemImage: "gearshape.fill",
                isSelected: chromeItem == .settings,
                accessibilityIdentifier: "animate.sidebar.settings"
            ) {
                openChromeItem(.settings)
            }

            tabletChromeButton(
                title: L10n.string("profile.accountScreen.title"),
                systemImage: "person.crop.circle.fill",
                isSelected: chromeItem == .account,
                accessibilityIdentifier: "animate.sidebar.account"
            ) {
                openChromeItem(.account)
            }
        }
        .padding(.horizontal, AVAppShellTabletSidebarMetric.horizontalPadding)
        .padding(.vertical, AVAppShellTabletSidebarMetric.verticalPadding)
        .frame(width: 256, alignment: .topLeading)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(.regularMaterial)
        .accessibilityIdentifier("animate.shell.tablet.sidebar")
    }

    private var tabletSidebarBrandHeader: some View {
        AVAppShellTabletSidebarBrandHeader(
            logoAssetName: appExperience.visualAssets?.headerLogoName ?? "AnimateHeaderWordmark",
            accessibilityLabel: appExperience.identity.displayName,
            logoWidth: 146,
            logoHeight: 44,
            logoLeadingCorrection: -2
        )
    }

    private var tabletTabs: [AnimateRootTab] {
        AnimateRootTab.footerTabs(
            canUseAnimateImageGeneration: accountController.canUseAnimateImageGeneration
        ) + [.avi]
    }

    private func tabletSidebarButton(tab: AnimateRootTab, isSelected: Bool) -> some View {
        let shellTab = tab.shellTab
        return AVAppShellTabletSidebarButton(
            title: shellTab.title,
            systemImage: shellTab.systemImage,
            isSelected: isSelected
        ) {
            guard canNavigateAwayFromCurrentTab else { return }
            if tab == .avi {
                selectAssistantTab()
            } else {
                selectFooterTab(tab)
            }
        }
        .accessibilityIdentifier("animate.sidebar.\(tab.rawValue)")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(shellTab.title)
    }

    private func tabletChromeButton(
        title: String,
        systemImage: String,
        isSelected: Bool,
        accessibilityIdentifier: String,
        action: @escaping () -> Void
    ) -> some View {
        AVAppShellTabletSidebarButton(
            title: title,
            systemImage: systemImage,
            isSelected: isSelected,
            fontSize: 15,
            action: action
        )
        .accessibilityIdentifier(accessibilityIdentifier)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private func newVideoFloatingAction(bottomPadding: CGFloat) -> some View {
        if showsNewVideoFloatingAction {
            Button {
                startFloatingVideoCreationAction()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(AVBrandColor.textInverse)
                    .frame(width: 58, height: 58)
                    .background(
                        Circle()
                            .fill(AVBrandColor.accent)
                    )
                    .shadow(color: AVBrandColor.accent.opacity(0.24), radius: 16, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.string("inProgress.newVideo"))
            .padding(.trailing, 28)
            .padding(.bottom, bottomPadding)
        }
    }

    private var footerAssistant: AVAppShellConfiguredAssistant {
        AVAppShellConfiguredAssistant(
            experience: appExperience,
            accessibilityIdentifier: "animate.tab.avi",
            activeContextSystemImage: "video.fill"
        )
    }

    private var footerConfiguration: AVAppShellFooterConfiguration {
        guard selectedTab == .create else {
            return appExperience.footerConfiguration
        }

        return AVAppShellFooterConfiguration(
            backdropHeight: 104,
            playerTabSpacing: appExperience.footerConfiguration.playerTabSpacing
        )
    }

    @ViewBuilder
    private func screen(
        for tab: AnimateRootTab,
        isTabletLayout: Bool = false,
        readableContentWidth: CGFloat? = nil,
        createBottomSafeAreaPadding: CGFloat = 82,
        imageBottomSafeAreaPadding: CGFloat = 82
    ) -> some View {
        if let chromeItem {
            AnimateProfileScreen(
                mode: chromeItem,
                openSettings: { self.chromeItem = .settings },
                openAccount: { self.chromeItem = .account },
                openCredits: openCredits,
                startSignInFlow: startSignInFlow
            )
            .environmentObject(createViewModel)
            .environmentObject(inProgressViewModel)
        } else {
            switch tab {
            case .home:
                AnimateHomeScreen(
                    openSettings: { chromeItem = .settings },
                    openAccount: { chromeItem = .account },
                    startSignInFlow: startSignInFlow,
                    openCredits: openCredits,
                    retryCredits: retryCreditBalance,
                    selectTab: selectRootTab,
                    startVideoCreation: startOrContinueVideoCreation,
                    continueVideo: { request in
                        createViewModel.continueVideo(request.video, focus: request.focus)
                        selectRootTab(.create)
                    },
                    isTabletLayout: isTabletLayout,
                    maxContentWidth: readableContentWidth
                )
            case .create:
                AnimateCreateScreen(
                    startSignInFlow: startSignInFlow,
                    openCredits: openCredits,
                    cancelCreation: cancelCreation,
                    finishFinalVideoToGallery: finishFinalVideoToGallery,
                    bottomSafeAreaPadding: createBottomSafeAreaPadding
                )
            case .createImage:
                if accountController.canUseAnimateImageGeneration {
                    AnimateCreateImagesWorkspace(
                        balance: accountController.creditBalance,
                        creditBalanceLoadState: accountController.creditBalanceLoadState,
                        imageGenerationAvailability: createViewModel.imageGenerationAvailability,
                        isLoadingImageGenerationAvailability: createViewModel.isLoadingImageGenerationAvailability,
                        isStartingImageGeneration: createViewModel.isStartingImageGeneration,
                        isPurchasingImageGenerationPack: createViewModel.isPurchasingImageGenerationPack,
                        imageGenerationAvailabilityMessage: createViewModel.imageGenerationAvailabilityMessage,
                        selectedImage: $imageDraftImage,
                        selectedImageData: $imageDraftData,
                        selectedSourceImageLocalIdentifier: $imageDraftSourceIdentifier,
                        selectedLooks: $imageDraftLooks,
                        refreshImageGenerationAvailability: createViewModel.refreshImageGenerationAvailability,
                        startImageGeneration: createViewModel.startImageGeneration,
                        purchaseImageGenerationPack: createViewModel.purchaseImageGenerationPack,
                        openCredits: openCredits,
                        cancelCreation: cancelImageCreation
                    )
                    .safeAreaPadding(.horizontal, 20)
                    .safeAreaPadding(.top, 12)
                    .safeAreaPadding(.bottom, imageBottomSafeAreaPadding)
                } else {
                    AnimateCreateScreen(
                        startSignInFlow: startSignInFlow,
                        openCredits: openCredits,
                        cancelCreation: cancelCreation,
                        finishFinalVideoToGallery: finishFinalVideoToGallery,
                        bottomSafeAreaPadding: createBottomSafeAreaPadding
                    )
                }
            case .inProgress:
                AnimateInProgressScreen(
                    balance: accountController.creditBalance,
                    creditBalanceLoadState: accountController.creditBalanceLoadState,
                    preferredAssetKindRaw: inProgressPreferredAssetKindRaw,
                    canUseAnimateImageGeneration: accountController.canUseAnimateImageGeneration,
                    continueVideo: { request in
                        createViewModel.continueVideo(request.video, focus: request.focus)
                        selectedTab = .create
                    },
                    startVideoCreation: {
                        startOrContinueVideoCreation()
                    },
                    startImageCreation: {
                        startImageCreation()
                    },
                    startSignInFlow: startSignInFlow,
                    openCredits: openCredits,
                    retryCredits: retryCreditBalance
                )
            case .gallery:
                AnimateGalleryScreen(
                    startVideoCreation: startOrContinueVideoCreation,
                    startImageCreation: startImageCreation,
                    canUseAnimateImageGeneration: accountController.canUseAnimateImageGeneration
                )
                    .environmentObject(galleryViewModel)
            case .avi:
                AnimateAviScreen(
                    selectTab: selectRootTab,
                    startVideoCreation: startOrContinueVideoCreation,
                    startSignInFlow: startSignInFlow
                )
                    .environmentObject(aviViewModel)
            case .profile:
                EmptyView()
            }
        }
    }

    private func openCredits() {
        guard accountController.isSignedIn else {
            startSignInFlow()
            return
        }

        creditsPaywallIsPresented = true
    }

    private func retryCreditBalance() {
        Task {
            await accountController.refreshCreditBalance()
        }
    }

    private var footerSelectedTab: AnimateRootTab {
        guard chromeItem == nil else {
            return selectedTab == .createImage && !accountController.canUseAnimateImageGeneration ? .create : selectedTab
        }
        guard selectedTab != .createImage || accountController.canUseAnimateImageGeneration else {
            return .create
        }
        return selectedTab
    }

    private var canNavigateAwayFromCurrentTab: Bool {
        !(selectedTab == .create && createViewModel.isPreparingFinalPlan)
    }

    private var showsNewVideoFloatingAction: Bool {
        chromeItem == nil
            && accountController.isSignedIn
            && selectedTab == .gallery
            && !hasSingleVideoDraftContext
    }

    private var hasAviActiveContext: Bool {
        hasSingleVideoDraftContext
    }

    private var hasSingleVideoDraftContext: Bool {
        createViewModel.hasRecoverableVideoContext
            || createViewModel.hasLocalAnimateWorkspace
            || inProgressViewModel.videosSummary.latestAnimateVideo != nil
    }

    private func cancelCreation() {
        createViewModel.clearSessionState()
        selectRootTab(.home)
    }

    private func cancelImageCreation() {
        clearImageDraft()
        selectRootTab(.home)
    }

    private func redirectImageGenerationIfUnavailable() {
        guard !accountController.canUseAnimateImageGeneration else { return }
        clearImageDraft()
        inProgressPreferredAssetKindRaw = "videos"
        if selectedTab == .createImage {
            selectRootTab(.create)
        }
    }

    private func openChromeItem(_ item: AVAppShellChromeItem) {
        guard canNavigateAwayFromCurrentTab else { return }
        navigationPath = NavigationPath()
        navigationStackResetID = UUID()
        chromeItem = item
    }

    private func finishFinalVideoToGallery() {
        guard createViewModel.finishFinalVideoToGallery() else { return }

        createViewModel.clearFinalSessionAfterGalleryMove()
        galleryViewModel.refreshVideos()
        chromeItem = nil
        selectRootTab(.gallery)
    }

    private func startOrContinueVideoCreation() {
        if createViewModel.hasLocalAnimateWorkspace {
            selectRootTab(.create)
            return
        }

        if createViewModel.hasActiveVideoWorkspace {
            selectRootTab(.create)
            return
        }

        if let activeVideo = inProgressViewModel.videosSummary.latestAnimateVideo {
            createViewModel.continueVideo(activeVideo)
            selectRootTab(.create)
            return
        }

        beginNewVideoCreationFromPreference()
    }

    private func startFloatingVideoCreationAction() {
        startOrContinueVideoCreation()
    }

    private func startImageCreation() {
        guard accountController.canUseAnimateImageGeneration else {
            startOrContinueVideoCreation()
            return
        }
        selectRootTab(.createImage)
    }

    private func beginNewVideoCreationFromPreference() {
        guard createViewModel.canBeginNewVideoCreation else {
            selectRootTab(.create)
            return
        }

        createViewModel.beginNewVideoCreation()
        selectRootTab(.create)
    }

    private func selectRootTab(_ tab: AnimateRootTab) {
        if tab == .createImage, !accountController.canUseAnimateImageGeneration {
            startOrContinueVideoCreation()
            return
        }
        guard selectedTab != tab || chromeItem != nil else { return }
        navigationPath = NavigationPath()
        navigationStackResetID = UUID()
        chromeItem = nil
        selectedTab = tab
    }

    private func selectAssistantTab() {
        if createViewModel.hasRecoverableVideoContext {
            selectRootTab(.create)
        } else {
            selectRootTab(.avi)
        }
    }

    private func selectFooterTab(_ tab: AnimateRootTab) {
        switch tab {
        case .create:
            startOrContinueVideoCreation()
        case .createImage:
            startImageCreation()
        default:
            selectRootTab(tab)
        }
    }

    private func clearImageDraft() {
        imageDraftImage = nil
        imageDraftData = nil
        imageDraftSourceIdentifier = nil
        imageDraftLooks = []
    }
}
