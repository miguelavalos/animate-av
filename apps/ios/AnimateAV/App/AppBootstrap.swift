import AVLaunchFoundation
import SwiftUI

struct MomentsAppBootstrapView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var dependencies = MomentsDependencyContainer()
    @State private var selectedTab: MomentsRootTab = .home
    @State private var authOptionsArePresented = false
    @State private var authenticationWasSkipped = false
    @State private var isShowingAccountOnboarding = true
    @State private var didApplyLaunchTab = false
    @State private var postAuthenticationSplashIsPresented = false

    private let launchContext = MomentsLaunchContext.current
    private var splashPolicy: AVSplashTransitionPolicy {
        AVSplashTransitionPolicy(isDisabled: launchContext.shouldDisableSplash)
    }

    var body: some View {
        Group {
            if shouldShowOnboarding {
                MomentsAuthOnboardingView(
                    authOptionsArePresented: $authOptionsArePresented,
                    accountIsAvailable: dependencies.accountController.isAccountAvailable,
                    onContinueWithApple: startAppleSignIn,
                    onContinueWithGoogle: startGoogleSignIn,
                    onSkip: skipAuthentication
                )
            } else {
                MomentsAppShellView(
                    selectedTab: $selectedTab,
                    startSignInFlow: { startSignInFlow(showAuthOptions: true) }
                )
                .id(dependencies.accountController.isSignedIn ? "signed-in-shell" : "skipped-auth-shell")
                .avSplashTransition(policy: splashPolicy) {
                    AnimateAVSplashView()
                }
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
        .environmentObject(dependencies.inProgressMomentsWorkflow)
        .environmentObject(dependencies.homeViewModel)
        .environmentObject(dependencies.createViewModel)
        .environmentObject(dependencies.inProgressViewModel)
        .environmentObject(dependencies.galleryViewModel)
        .environmentObject(dependencies.aviViewModel)
        .task {
            applyLaunchTabIfNeeded()
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

    private func applyLaunchTabIfNeeded() {
        guard !didApplyLaunchTab else { return }
        didApplyLaunchTab = true
        guard let preferredTab = launchContext.preferredTab else { return }
        selectedTab = MomentsRootTab(preferredTab)
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

private extension MomentsRootTab {
    init(_ launchTab: MomentsLaunchContext.Tab) {
        switch launchTab {
        case .home:
            self = .home
        case .create:
            self = .create
        case .inProgress:
            self = .inProgress
        case .avi:
            self = .avi
        }
    }
}
