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
    @State private var chromeItem: AVAppShellChromeItem?
    @State private var creditsPaywallIsPresented = false
    @State private var navigationPath = NavigationPath()
    @State private var navigationStackResetID = UUID()
    @State private var imageDraftImage: UIImage?
    @State private var imageDraftData: Data?
    @State private var imageDraftSourceIdentifier: String?
    @State private var imageDraftLooks: Set<AnimateCreateImageLook> = []
    @State private var inProgressPreferredAssetKindRaw: String?

    var body: some View {
        appScaffold
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
    }

    private var appScaffold: some View {
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
                chromeItem = nil
                if createViewModel.hasRecoverableVideoContext {
                    selectRootTab(.create)
                } else {
                    selectRootTab(.avi)
                }
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
                .padding(.bottom, 104)
            }
        }
        .onChange(of: accountController.canUseAnimateImageGeneration) { _, canUseImages in
            guard !canUseImages else { return }
            redirectImageGenerationIfUnavailable()
        }
        .onAppear(perform: redirectImageGenerationIfUnavailable)
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
    private func screen(for tab: AnimateRootTab) -> some View {
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
                    }
                )
            case .create:
                AnimateCreateScreen(
                    startSignInFlow: startSignInFlow,
                    openCredits: openCredits,
                    cancelCreation: cancelCreation,
                    finishFinalVideoToGallery: finishFinalVideoToGallery,
                    bottomSafeAreaPadding: 82
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
                    .safeAreaPadding(.bottom, 82)
                } else {
                    AnimateCreateScreen(
                        startSignInFlow: startSignInFlow,
                        openCredits: openCredits,
                        cancelCreation: cancelCreation,
                        finishFinalVideoToGallery: finishFinalVideoToGallery,
                        bottomSafeAreaPadding: 82
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
        guard chromeItem == nil else { return .profile }
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
        selectedTab = tab
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
