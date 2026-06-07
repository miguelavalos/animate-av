import Foundation

struct AnimateCreateMediaPresentation: Equatable {
    var activeMomentId: String?
    var template: AnimateVideoTemplate
    var summary: AnimateCreateMediaSummary
    var canAddMedia = false
    var availabilityMessage: String?

    var remainingSlots: Int {
        summary.remainingSlots(template: template)
    }

    var pickerTitle: String {
        summary.isImporting ? L10n.string("create.media.action.adding") : L10n.string("create.media.action.add")
    }

    var selectedCountTitle: String {
        L10n.string("create.media.selectedCount", summary.selectedCount)
    }

    var selectionMessage: String {
        AnimateMediaRules.selectionMessage(
            AnimateMediaRules.availability(template: template, selectedCount: summary.selectedCount),
            readyMessage: "",
            tooFewMessage: { L10n.string("create.media.selection.tooFew", $0, Self.mediaAssetLabel($0)) },
            tooManyMessage: { _ in L10n.string("create.media.selection.tooMany") }
        )
    }

    var syncedMediaAssets: [AnimateMediaAsset] {
        summary.syncedMediaAssets.sorted { $0.sortOrder < $1.sortOrder }
    }

    private static func mediaAssetLabel(_ count: Int) -> String {
        count == 1 ? L10n.string("create.media.asset.singular") : L10n.string("create.media.asset.plural")
    }
}

struct AnimateCreateStoryPresentation: Equatable {
    var summary: AnimateCreateStorySummary
    var canPlanStory = false
    var availabilityMessage: String?

    var planButtonTitle: String {
        summary.isPlanning ? L10n.string("create.story.action.preparing") : L10n.string("create.story.action.prepare")
    }

    var emptyMessage: String {
        canPlanStory
            ? L10n.string("create.story.empty.ready")
            : L10n.string("create.story.empty.needsMedia")
    }

    var savedScenes: [AnimateStoryScene] {
        summary.savedScenes.sorted { $0.sceneIndex < $1.sceneIndex }
    }
}

struct AnimateCreateVideoDirectionPresentation: Equatable {
    var mediaSummary: AnimateCreateMediaSummary
    var storySummary: AnimateCreateStorySummary
    var selectedDuration: AnimateVideoDuration
    var renderPlan: AnimateRenderPlan?
    var canRefreshStory = false
    var availabilityMessage: String?

    var statusMessage: String {
        if storySummary.hasScenes {
            return L10n.string("create.videoDirection.status.ready")
        }
        if storySummary.isPlanning {
            return storySummary.statusMessage ?? L10n.string("create.videoDirection.status.improving")
        }
        if mediaCount > 0, canRefreshStory {
            return L10n.string("create.videoDirection.status.readyToPrepare")
        }
        if mediaCount > 0 {
            return availabilityMessage ?? L10n.string("create.videoDirection.status.unavailable")
        }
        return L10n.string("create.videoDirection.status.needsMedia")
    }

    var modeTitle: String {
        if storySummary.isPlanning {
            return L10n.string("create.videoDirection.pill.working")
        }
        if storySummary.hasScenes {
            return L10n.string("create.videoDirection.pill.story")
        }
        if mediaCount > 0 {
            return L10n.string("create.videoDirection.pill.ready")
        }
        return L10n.string("create.videoDirection.pill.noMedia")
    }

    var mediaCountTitle: String {
        L10n.string(
            mediaCount == 1 ? "create.workflowContent.itemCount" : "create.workflowContent.itemsCount",
            mediaCount
        )
    }

    var durationTitle: String {
        if let renderPlan {
            if let minimumDurationMs = renderPlan.minimumDurationMs,
               minimumDurationMs > 0,
               minimumDurationMs < renderPlan.targetDurationMs {
                return L10n.string(
                    "create.final.confirmSheet.durationRange",
                    minimumDurationMs / 1_000,
                    renderPlan.targetDurationMs / 1_000
                )
            }
            return L10n.string("create.final.confirmSheet.upToSeconds", renderPlan.targetDurationMs / 1_000)
        }
        return selectedDuration.title
    }

    var primaryActionTitle: String {
        storySummary.hasScenes
            ? L10n.string("create.videoDirection.action.refresh")
            : L10n.string("create.videoDirection.action.prepare")
    }

    var primaryActionIconName: String {
        storySummary.hasScenes ? "sparkles" : "wand.and.stars"
    }

    var editActionTitle: String {
        L10n.string("create.videoDirection.action.edit")
    }

    var iconName: String {
        if storySummary.hasScenes { return "rectangle.stack.fill" }
        if storySummary.isPlanning { return "sparkles" }
        return "wand.and.stars"
    }

    var canRunPrimaryAction: Bool {
        !storySummary.isPlanning
            && mediaCount > 0
            && canRefreshStory
    }

    var canShowRefreshAction: Bool {
        storySummary.hasScenes && canRunPrimaryAction
    }

    var visibleScenes: [AnimateCreateStoryScenePresentation] {
        Array(storySummary.presentedScenes.prefix(2))
    }

    var remainingSceneCount: Int {
        max(storySummary.presentedScenes.count - visibleScenes.count, 0)
    }

    var remainingSceneTitle: String? {
        guard remainingSceneCount > 0 else { return nil }
        return L10n.string(
            remainingSceneCount == 1 ? "create.videoDirection.moreScene" : "create.videoDirection.moreScenes",
            remainingSceneCount
        )
    }

    private var mediaCount: Int {
        mediaSummary.effectiveMediaCount
    }
}
