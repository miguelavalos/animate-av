import AVBrandFoundation
import AVSettingsFoundation
import SwiftUI

struct AnimateAVSplashView: View {
    var body: some View {
        AVConfiguredSplashScreen()
    }
}

#Preview {
    AnimateAVSplashView()
        .avBrandPalette(AnimateTheme.brandPalette)
}
