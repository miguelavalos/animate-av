import AVSettingsFoundation
import SwiftUI

struct SignInActionsView<AuthenticationController>: View where AuthenticationController: ObservableObject & MomentsAuthenticationControlling {
    @ObservedObject var authenticationController: AuthenticationController
    @StateObject private var signInCoordinator = AVAuthSignInCoordinator()

    var body: some View {
        AVSettingsSignInActions(
            isBusy: signInCoordinator.activeProvider != nil || authenticationController.isAuthenticationBusy,
            activeProvider: signInCoordinator.activeProvider,
            isAvailable: authenticationController.isAuthenticationAvailable,
            appleAccessibilityIdentifier: "moments.auth.apple",
            googleAccessibilityIdentifier: "moments.auth.google",
            onApple: startAppleSignIn,
            onGoogle: startGoogleSignIn
        )
        .alert(L10n.string("access.error.title"), isPresented: $signInCoordinator.isShowingError) {
            Button(L10n.string("common.close"), role: .cancel) {}
        } message: {
            Text(signInCoordinator.errorMessage)
        }
        .onDisappear {
            signInCoordinator.cancel()
        }
    }

    private func startAppleSignIn() {
        signInCoordinator.start(
            provider: .apple,
            isAvailable: authenticationController.isAuthenticationAvailable,
            unavailableMessage: L10n.string("access.unavailable"),
            operation: authenticationController.signInWithApple
        )
    }

    private func startGoogleSignIn() {
        signInCoordinator.start(
            provider: .google,
            isAvailable: authenticationController.isAuthenticationAvailable,
            unavailableMessage: L10n.string("access.unavailable"),
            operation: authenticationController.signInWithGoogle
        )
    }
}
