import Foundation

enum AnimateVideoTemplateID: String, CaseIterable, Identifiable, Codable {
    case birthdayMessage = "birthday"
    case partyRecap = "eventRecap"
    case softRoast = "softRoast"

    var id: String { rawValue }
}

struct AnimateVideoTemplate: Identifiable, Equatable {
    let id: AnimateVideoTemplateID
    let title: String
    let durationSeconds: Int
    let creditCost: Int
    let minimumAssets: Int
    let maximumAssets: Int
    let summary: String

    var duration: String {
        L10n.string("create.template.duration", durationSeconds)
    }

    var mediaRange: String {
        L10n.string("create.template.mediaRange", minimumAssets)
    }

    static var birthdayMessage: AnimateVideoTemplate {
        AnimateVideoTemplate(
        id: .birthdayMessage,
        title: L10n.string("create.template.celebration.title"),
        durationSeconds: 5,
        creditCost: 1,
        minimumAssets: 1,
        maximumAssets: 1,
        summary: L10n.string("create.template.celebration.summary")
        )
    }

    static var partyRecap: AnimateVideoTemplate {
        AnimateVideoTemplate(
        id: .partyRecap,
        title: L10n.string("create.template.eventRecap.title"),
        durationSeconds: 10,
        creditCost: 1,
        minimumAssets: 1,
        maximumAssets: 1,
        summary: L10n.string("create.template.eventRecap.summary")
        )
    }

    static var softRoast: AnimateVideoTemplate {
        AnimateVideoTemplate(
        id: .softRoast,
        title: L10n.string("create.template.softRoast.title"),
        durationSeconds: 15,
        creditCost: 1,
        minimumAssets: 1,
        maximumAssets: 1,
        summary: L10n.string("create.template.softRoast.summary")
        )
    }

    static var launchTemplates: [AnimateVideoTemplate] { [
        birthdayMessage,
        partyRecap,
        softRoast
    ] }
}
