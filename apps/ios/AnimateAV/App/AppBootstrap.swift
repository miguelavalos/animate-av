import AVLaunchFoundation
import AVProductAccountFoundation
import SwiftUI

struct AnimateAppBootstrapView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var dependencies = AnimateDependencyContainer()
    @State private var selectedTab: AnimateRootTab = .home
    @State private var authPresentationState: AVProductAccountAuthPresentationState = .hidden
    @State private var authenticationWasSkipped = false
    @State private var initialSplashIsPresented = true
    @State private var initialAccountRestoreCompleted = false
    @State private var initialAccountRestoreInProgress = false
    @State private var didApplyLaunchTab = false
    @State private var postAuthenticationSplashIsPresented = false

    private let launchContext = AnimateLaunchContext.current
    private var splashPolicy: AVSplashTransitionPolicy {
        AVSplashTransitionPolicy(isDisabled: launchContext.shouldDisableSplash)
    }

    var body: some View {
        Group {
            if shouldShowInitialSplash {
                AnimateAVSplashView()
            } else if shouldShowOnboarding {
                AnimateAuthOnboardingView(
                    authPresentationState: $authPresentationState,
                    accountIsAvailable: dependencies.accountController.isAccountAvailable,
                    onContinueWithApple: startAppleSignIn,
                    onContinueWithGoogle: startGoogleSignIn,
                    onSkip: skipAuthentication
                )
            } else {
                AnimateAppShellView(
                    selectedTab: $selectedTab,
                    startSignInFlow: { startSignInFlow(showAuthOptions: true) }
                )
                .id(dependencies.accountController.isSignedIn ? "signed-in-shell" : "skipped-auth-shell")
                .overlay {
                    if postAuthenticationSplashIsPresented {
                        AnimateAVSplashView()
                            .transition(.opacity)
                            .zIndex(2)
                    }
                }
            }
        }
        .environmentObject(dependencies.accountController)
        .environmentObject(dependencies.videosWorkflow)
        .environmentObject(dependencies.homeViewModel)
        .environmentObject(dependencies.createViewModel)
        .environmentObject(dependencies.inProgressViewModel)
        .environmentObject(dependencies.galleryViewModel)
        .environmentObject(dependencies.aviViewModel)
        .task {
            applyLaunchTabIfNeeded()
            await restoreInitialAccountSessionIfNeeded()
            dependencies.applyUITestFixturesIfNeeded()
            await Task.yield()
            dependencies.applyUITestFixturesIfNeeded()
            await completeInitialSplashIfNeeded()
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await restoreInitialAccountSessionIfNeeded()
        }
        .onReceive(dependencies.accountController.currentUserIdPublisher) { ownerUserId in
            dependencies.handleAccountChange(ownerUserId: ownerUserId)
        }
    }

    private var shouldShowOnboarding: Bool {
        guard !authenticationWasSkipped else { return false }
        guard !dependencies.accountController.isAccountSessionTemporarilyUnavailable else { return false }
        let rootGate = AVProductAccountAuthFlowRootGate(
            accountState: dependencies.accountController.productAccountState,
            authPresentationState: authPresentationState
        )
        return rootGate.shouldShowOnboarding
    }

    private var shouldShowInitialSplash: Bool {
        initialSplashIsPresented && !launchContext.shouldDisableSplash
    }

    private func applyLaunchTabIfNeeded() {
        guard !didApplyLaunchTab else { return }
        didApplyLaunchTab = true
        guard let preferredTab = launchContext.preferredTab else { return }
        selectedTab = AnimateRootTab(preferredTab)
    }

    private func completeInitialSplashIfNeeded() async {
        guard initialSplashIsPresented else { return }
        if !launchContext.shouldDisableSplash {
            try? await Task.sleep(for: splashPolicy.displayDuration)
        }
        await MainActor.run {
            withAnimation(splashPolicy.dismissAnimation) {
                initialSplashIsPresented = false
                showInitialOnboardingAfterSplashIfNeeded()
            }
        }
    }

    private func showInitialOnboardingAfterSplashIfNeeded() {
        guard initialAccountRestoreCompleted else { return }
        guard !dependencies.accountController.isSignedIn else { return }
        guard !dependencies.accountController.isAccountSessionTemporarilyUnavailable else { return }
        guard !authenticationWasSkipped else { return }
        authPresentationState = .onboardingCollapsed
    }

    private func restoreInitialAccountSessionIfNeeded() async {
        guard !initialAccountRestoreCompleted else { return }
        guard !initialAccountRestoreInProgress else { return }
        initialAccountRestoreInProgress = true
        defer { initialAccountRestoreInProgress = false }
        await dependencies.accountController.syncFromAccountProvider()
        initialAccountRestoreCompleted = true
    }

    private func skipAuthentication() {
        authPresentationState = .hidden
        postAuthenticationSplashIsPresented = true
        authenticationWasSkipped = true
        Task {
            try? await Task.sleep(for: splashPolicy.displayDuration)
            await MainActor.run {
                withAnimation(splashPolicy.dismissAnimation) {
                    postAuthenticationSplashIsPresented = false
                }
            }
        }
    }

    private func startSignInFlow(showAuthOptions: Bool = false) {
        postAuthenticationSplashIsPresented = false
        authenticationWasSkipped = false
        authPresentationState = showAuthOptions ? .onboardingOptions : .onboardingCollapsed
    }

    private func startAppleSignIn() async throws {
        try await dependencies.accountController.signInWithApple()
        authenticationWasSkipped = false
        authPresentationState = .hidden
    }

    private func startGoogleSignIn() async throws {
        try await dependencies.accountController.signInWithGoogle()
        authenticationWasSkipped = false
        authPresentationState = .hidden
    }
}

private extension AnimateRootTab {
    init(_ launchTab: AnimateLaunchContext.Tab) {
        switch launchTab {
        case .home:
            self = .home
        case .create:
            self = .create
        case .createImage:
            self = .createImage
        case .inProgress:
            self = .inProgress
        case .avi:
            self = .avi
        }
    }
}
