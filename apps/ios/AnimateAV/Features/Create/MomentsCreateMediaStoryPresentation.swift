import Foundation

struct MomentsCreateMediaPresentation: Equatable {
    var activeMomentId: String?
    var template: MomentTemplate
    var summary: MomentsCreateMediaSummary
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
        MomentsMediaRules.selectionMessage(
            MomentsMediaRules.availability(template: template, selectedCount: summary.selectedCount),
            readyMessage: "",
            tooFewMessage: { L10n.string("create.media.selection.tooFew", $0, Self.mediaAssetLabel($0)) },
            tooManyMessage: { _ in L10n.string("create.media.selection.tooMany") }
        )
    }

    var syncedMediaAssets: [MomentMediaAsset] {
        summary.syncedMediaAssets.sorted { $0.sortOrder < $1.sortOrder }
    }

    private static func mediaAssetLabel(_ count: Int) -> String {
        count == 1 ? L10n.string("create.media.asset.singular") : L10n.string("create.media.asset.plural")
    }
}

struct MomentsCreateStoryPresentation: Equatable {
    var summary: MomentsCreateStorySummary
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

    var savedScenes: [MomentStoryScene] {
        summary.savedScenes.sorted { $0.sceneIndex < $1.sceneIndex }
    }
}

struct MomentsCreateStoryDecisionPresentation: Equatable {
    var mediaSummary: MomentsCreateMediaSummary
    var storySummary: MomentsCreateStorySummary
    var selectedDuration: MomentDuration
    var renderPlan: MomentsRenderPlan?
    var canRefreshStory = false
    var availabilityMessage: String?

    var statusMessage: String {
        if storySummary.hasScenes {
            return L10n.string("create.storyDecision.status.ready")
        }
        if storySummary.isPlanning {
            return storySummary.statusMessage ?? L10n.string("create.storyDecision.status.improving")
        }
        if mediaCount > 0, canRefreshStory {
            return L10n.string("create.storyDecision.status.readyToPrepare")
        }
        if mediaCount > 0 {
            return availabilityMessage ?? L10n.string("create.storyDecision.status.unavailable")
        }
        return L10n.string("create.storyDecision.status.needsMedia")
    }

    var modeTitle: String {
        if storySummary.isPlanning {
            return L10n.string("create.storyDecision.pill.working")
        }
        if storySummary.hasScenes {
            return L10n.string("create.storyDecision.pill.story")
        }
        if mediaCount > 0 {
            return L10n.string("create.storyDecision.pill.ready")
        }
        return L10n.string("create.storyDecision.pill.noMedia")
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
            ? L10n.string("create.storyDecision.action.refresh")
            : L10n.string("create.storyDecision.action.prepare")
    }

    var primaryActionIconName: String {
        storySummary.hasScenes ? "sparkles" : "wand.and.stars"
    }

    var editActionTitle: String {
        L10n.string("create.storyDecision.action.edit")
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

    var visibleScenes: [MomentsCreateStoryScenePresentation] {
        Array(storySummary.presentedScenes.prefix(2))
    }

    var remainingSceneCount: Int {
        max(storySummary.presentedScenes.count - visibleScenes.count, 0)
    }

    var remainingSceneTitle: String? {
        guard remainingSceneCount > 0 else { return nil }
        return L10n.string(
            remainingSceneCount == 1 ? "create.storyDecision.moreScene" : "create.storyDecision.moreScenes",
            remainingSceneCount
        )
    }

    private var mediaCount: Int {
        mediaSummary.effectiveMediaCount
    }
}
