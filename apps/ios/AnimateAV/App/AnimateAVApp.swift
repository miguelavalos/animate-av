import AVDiagnosticsFoundation
import SwiftUI

@main
struct AnimateAVApp: App {
    @StateObject private var languageController = AppLanguageController()
    @StateObject private var themeController = AppThemeController()
    @StateObject private var newMomentStartController = MomentsNewMomentStartController()

    init() {
        AppConfig.configureAVAccountIfPossible()
        AVDiagnostics.configure(AppConfig.diagnosticsConfiguration)
    }

    var body: some Scene {
        WindowGroup {
            MomentsAppBootstrapView()
                .environmentObject(languageController)
                .environmentObject(themeController)
                .environmentObject(newMomentStartController)
                .environment(\.locale, languageController.locale)
                .avCommonAppExperience(MomentsAppExperience.experience)
                .preferredColorScheme(themeController.currentTheme.preferredColorScheme)
        }
    }
}
