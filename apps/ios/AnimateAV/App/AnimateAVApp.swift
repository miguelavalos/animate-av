import AVDiagnosticsFoundation
import SwiftUI

@main
struct AnimateAVApp: App {
    @StateObject private var languageController = AppLanguageController()
    @StateObject private var themeController = AppThemeController()
    @StateObject private var newVideoStartController = AnimateNewVideoStartController()

    init() {
        AppConfig.configureAVAccountIfPossible()
        AVDiagnostics.configure(AppConfig.diagnosticsConfiguration)
    }

    var body: some Scene {
        WindowGroup {
            MomentsAppBootstrapView()
                .environmentObject(languageController)
                .environmentObject(themeController)
                .environmentObject(newVideoStartController)
                .environment(\.locale, languageController.locale)
                .avCommonAppExperience(AnimateAppExperience.experience)
                .preferredColorScheme(themeController.currentTheme.preferredColorScheme)
        }
    }
}
