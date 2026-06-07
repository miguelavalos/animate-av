import AVAppShellFoundation
import Foundation

enum AnimateRootTab: String, CaseIterable, Identifiable {
    case home
    case create
    case inProgress
    case gallery
    case avi
    case profile

    var id: String { rawValue }

    static let footerTabs: [AnimateRootTab] = [.home, .inProgress, .gallery]

    var shellTab: AVAppShellTab<AnimateRootTab> {
        switch self {
        case .home:
            AVAppShellTab(
                id: self,
                title: L10n.string("tab.home"),
                systemImage: "house.fill",
                accessibilityIdentifier: "animate.tab.home"
            )
        case .create:
            AVAppShellTab(
                id: self,
                title: L10n.string("tab.create"),
                systemImage: "plus.app.fill",
                accessibilityIdentifier: "animate.tab.create"
            )
        case .inProgress:
            AVAppShellTab(
                id: self,
                title: L10n.string("tab.inProgress"),
                systemImage: "clock.fill",
                accessibilityIdentifier: "animate.tab.inProgress"
            )
        case .gallery:
            AVAppShellTab(
                id: self,
                title: L10n.string("tab.gallery"),
                systemImage: "play.square.stack.fill",
                accessibilityIdentifier: "animate.tab.gallery"
            )
        case .avi, .profile:
            AVAppShellTab(
                id: self,
                title: L10n.string("tab.avi"),
                systemImage: "sparkles",
                accessibilityIdentifier: "animate.tab.avi"
            )
        }
    }
}
