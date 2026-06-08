import AVLaunchFoundation
import SwiftUI

struct AnimateAppBootstrapView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var dependencies = AnimateDependencyContainer()
    @State private var selectedTab: AnimateRootTab = .home
    @State private var authOptionsArePresented = false
    @State private var authenticationWasSkipped = false
    @State private var isShowingAccountOnboarding = false
    @State private var initialSplashIsPresented = true
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
                    authOptionsArePresented: $authOptionsArePresented,
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
            await completeInitialSplashIfNeeded()
            dependencies.applyUITestFixturesIfNeeded()
            await Task.yield()
            dependencies.applyUITestFixturesIfNeeded()
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await dependencies.accountController.syncFromAccountProvider()
        }
        .onReceive(dependencies.accountController.currentUserIdPublisher) { ownerUserId in
            dependencies.handleAccountChange(ownerUserId: ownerUserId)
        }
    }

    private var shouldShowOnboarding: Bool {
        !dependencies.accountController.isSignedIn && !authenticationWasSkipped && isShowingAccountOnboarding
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
        guard !dependencies.accountController.isSignedIn else { return }
        guard !authenticationWasSkipped else { return }
        isShowingAccountOnboarding = true
    }

    private func skipAuthentication() {
        authOptionsArePresented = false
        isShowingAccountOnboarding = false
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
        isShowingAccountOnboarding = true
        authOptionsArePresented = showAuthOptions
    }

    private func startAppleSignIn() async throws {
        try await dependencies.accountController.signInWithApple()
        await dependencies.accountController.syncFromAccountProvider()
        authenticationWasSkipped = false
        isShowingAccountOnboarding = false
        authOptionsArePresented = false
    }

    private func startGoogleSignIn() async throws {
        try await dependencies.accountController.signInWithGoogle()
        await dependencies.accountController.syncFromAccountProvider()
        authenticationWasSkipped = false
        isShowingAccountOnboarding = false
        authOptionsArePresented = false
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
