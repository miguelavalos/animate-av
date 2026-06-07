import AVAppShellFoundation
import AVBrandFoundation
import AVSettingsFoundation
import SwiftUI

struct AnimateAppShellView: View {
    @Binding var selectedTab: AnimateRootTab
    let startSignInFlow: () -> Void

    @EnvironmentObject private var accountController: AccountController
    @EnvironmentObject private var createViewModel: MomentsCreateViewModel
    @EnvironmentObject private var inProgressViewModel: MomentsInProgressViewModel
    @EnvironmentObject private var galleryViewModel: MomentsGalleryViewModel
    @EnvironmentObject private var aviViewModel: MomentsAviViewModel
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
            if showsNewMomentFloatingAction {
                Button {
                    startFloatingMomentAction()
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
                MomentsHomeScreen(
                    openSettings: { chromeItem = .settings },
                    openAccount: { chromeItem = .account },
                    startSignInFlow: startSignInFlow,
                    openCredits: openCredits,
                    retryCredits: retryCreditBalance,
                    selectTab: selectRootTab,
                    startMoment: startOrContinueMoment,
                    continueMoment: { request in
                        createViewModel.continueMoment(request.moment, focus: request.focus)
                        selectRootTab(.create)
                    }
                )
            case .create:
                MomentsCreateScreen(
                    startSignInFlow: startSignInFlow,
                    openCredits: openCredits,
                    cancelCreation: cancelCreation,
                    finishFinalVideoToGallery: finishFinalVideoToGallery,
                    bottomSafeAreaPadding: 82
                )
            case .inProgress:
                MomentsInProgressScreen(
                    balance: accountController.creditBalance,
                    creditBalanceLoadState: accountController.creditBalanceLoadState,
                    continueMoment: { request in
                        createViewModel.continueMoment(request.moment, focus: request.focus)
                        selectedTab = .create
                    },
                    startMoment: {
                        startOrContinueMoment()
                    },
                    startSignInFlow: startSignInFlow,
                    openCredits: openCredits,
                    retryCredits: retryCreditBalance
                )
            case .gallery:
                MomentsGalleryScreen()
                    .environmentObject(galleryViewModel)
            case .avi:
                MomentsAviScreen(
                    selectTab: selectRootTab,
                    startMoment: startOrContinueMoment,
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

    private var showsNewMomentFloatingAction: Bool {
        chromeItem == nil
            && accountController.isSignedIn
            && [.inProgress, .gallery].contains(selectedTab)
            && !createViewModel.hasLocalMomentWorkspace
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

    private func startOrContinueMoment() {
        if createViewModel.hasLocalMomentWorkspace {
            selectRootTab(.create)
            return
        }

        if createViewModel.hasMomentWorkspace {
            selectRootTab(.create)
            return
        }

        if let activeMoment = inProgressViewModel.momentsSummary.latestInProgressMoment {
            createViewModel.continueMoment(activeMoment)
            selectRootTab(.create)
            return
        }

        beginNewMomentFromPreference()
    }

    private func startFloatingMomentAction() {
        if createViewModel.hasLocalMomentWorkspace {
            selectRootTab(.create)
            return
        }

        if createViewModel.activeMomentId != nil {
            createViewModel.clearSessionState()
        }

        beginNewMomentFromPreference()
    }

    private func beginNewMomentFromPreference() {
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
