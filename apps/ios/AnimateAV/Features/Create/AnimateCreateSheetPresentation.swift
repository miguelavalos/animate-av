import SwiftUI

extension View {
    func animateCreateSheetPresentation(
        detents: Set<PresentationDetent> = [.large]
    ) -> some View {
        self
            .presentationDetents(detents)
            .presentationDragIndicator(.visible)
            .presentationSizing(.page)
    }
}
