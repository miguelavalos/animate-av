import AVAppShellFoundation
import Foundation

enum MomentsRootTab: String, CaseIterable, Identifiable {
    case home
    case create
    case inProgress
    case gallery
    case avi
    case profile

    var id: String { rawValue }

    static let footerTabs: [MomentsRootTab] = [.home, .inProgress, .gallery]

    var shellTab: AVAppShellTab<MomentsRootTab> {
        switch self {
        case .home:
            AVAppShellTab(
                id: self,
                title: L10n.string("tab.home"),
                systemImage: "house.fill",
                accessibilityIdentifier: "moments.tab.home"
            )
        case .create:
            AVAppShellTab(
                id: self,
                title: L10n.string("tab.create"),
                systemImage: "plus.app.fill",
                accessibilityIdentifier: "moments.tab.create"
            )
        case .inProgress:
            AVAppShellTab(
                id: self,
                title: L10n.string("tab.inProgress"),
                systemImage: "clock.fill",
                accessibilityIdentifier: "moments.tab.inProgress"
            )
        case .gallery:
            AVAppShellTab(
                id: self,
                title: L10n.string("tab.gallery"),
                systemImage: "play.square.stack.fill",
                accessibilityIdentifier: "moments.tab.gallery"
            )
        case .avi, .profile:
            AVAppShellTab(
                id: self,
                title: L10n.string("tab.avi"),
                systemImage: "sparkles",
                accessibilityIdentifier: "moments.tab.avi"
            )
        }
    }
}
