import AVAppShellFoundation
import AVBrandFoundation
import AVSettingsFoundation
import SwiftUI

struct AnimateAppShellView: View {
    @Binding var selectedTab: AnimateRootTab
    let startSignInFlow: () -> Void

    @EnvironmentObject private var accountController: AccountController
    @EnvironmentObject private var createViewModel: AnimateCreateViewModel
    @EnvironmentObject private var inProgressViewModel: AnimateInProgressViewModel
    @EnvironmentObject private var galleryViewModel: AnimateGalleryViewModel
    @EnvironmentObject private var aviViewModel: AnimateAviViewModel
    @EnvironmentObject private var newVideoStartController: AnimateNewVideoStartController
    @Environment(\.avCommonAppExperience) private var appExperience
    @State private var chromeItem: AVAppShellChromeItem?
    @State private var creditsPaywallIsPresented = false
    @State private var navigationPath = NavigationPath()
    @State private var navigationStackResetID = UUID()

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
    }

    private var appScaffold: some View {
        AVAppShellConfiguredScaffold(
            selectedTabID: footerSelectedTab,
            tabs: AnimateRootTab.footerTabs.map(\.shellTab),
            assistantID: .avi,
            assistant: footerAssistant,
            hasAssistantActiveContext: selectedTab != .avi && hasAviActiveContext,
            footerConfiguration: appExperience.footerConfiguration,
            onSelectTab: { tab in
                chromeItem = nil
                selectRootTab(tab)
            },
            onSelectAssistant: {
                chromeItem = nil
                if createViewModel.hasRecoverableMomentContext {
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
                .safeAreaPadding(.bottom, selectedTab == .create ? 132 : 96)
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
                .accessibilityLabel(L10n.string("inProgress.newMoment"))
                .padding(.trailing, 28)
                .padding(.bottom, 104)
            }
        }
    }

    private var footerAssistant: AVAppShellConfiguredAssistant {
        AVAppShellConfiguredAssistant(
            experience: appExperience,
            accessibilityIdentifier: "animate.tab.avi",
            activeContextSystemImage: "video.fill"
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
            case .inProgress:
                AnimateInProgressScreen(
                    balance: accountController.creditBalance,
                    creditBalanceLoadState: accountController.creditBalanceLoadState,
                    continueVideo: { request in
                        createViewModel.continueVideo(request.video, focus: request.focus)
                        selectedTab = .create
                    },
                    startVideoCreation: {
                        startOrContinueVideoCreation()
                    },
                    startSignInFlow: startSignInFlow,
                    openCredits: openCredits,
                    retryCredits: retryCreditBalance
                )
            case .gallery:
                AnimateGalleryScreen()
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
        return selectedTab == .create ? .inProgress : selectedTab
    }

    private var showsNewVideoFloatingAction: Bool {
        chromeItem == nil
            && accountController.isSignedIn
            && [.inProgress, .gallery].contains(selectedTab)
            && !createViewModel.hasLocalAnimateWorkspace
    }

    private var hasAviActiveContext: Bool {
        createViewModel.hasRecoverableMomentContext
    }

    private func cancelCreation() {
        createViewModel.clearSessionState()
        selectRootTab(.inProgress)
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

        if createViewModel.hasAnimateWorkspace {
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
        if createViewModel.hasLocalAnimateWorkspace {
            selectRootTab(.create)
            return
        }

        if createViewModel.activeVideoId != nil {
            createViewModel.clearSessionState()
        }

        beginNewVideoCreationFromPreference()
    }

    private func beginNewVideoCreationFromPreference() {
        guard createViewModel.canBeginNewMoment else {
            selectRootTab(.create)
            return
        }

        let startPreference = newVideoStartController.currentPreference
        createViewModel.beginNewMoment()
        selectRootTab(.create)
        requestStartPickerAfterCreateNavigation(startPreference)
    }

    private func requestStartPickerAfterCreateNavigation(_ preference: AnimateNewVideoStartPreference) {
        guard preference != .askEveryTime else { return }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard selectedTab == .create,
                  createViewModel.workflowPresentation.mediaSummary.selectedCount == 0
            else { return }

            switch preference {
            case .askEveryTime:
                break
            case .photosOrClips:
                createViewModel.requestMediaPickerOpen()
            }
        }
    }

    private func selectRootTab(_ tab: AnimateRootTab) {
        navigationPath = NavigationPath()
        navigationStackResetID = UUID()
        selectedTab = tab
    }
}
