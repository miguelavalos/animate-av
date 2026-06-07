import Foundation
import OSLog

@MainActor
final class StoryWorkflow: WorkspaceObservingWorkflow {
    @Published private(set) var generatedPlan: AnimateStoryResponse?
    @Published private(set) var isPlanning = false
    @Published private(set) var statusMessage: String?

    private let currentUserProvider: any AnimateCurrentUserProviding
    private let authTokenProvider: any AnimateAuthTokenProviding
    private let storyClient: AnimateStoryClient
    private let logger = Logger(subsystem: "com.avalsys.animateav", category: "story")

    init(
        currentUserProvider: any AnimateCurrentUserProviding,
        authTokenProvider: any AnimateAuthTokenProviding,
        workspaceObserver: any AnimateActiveWorkspaceObserving,
        storyClient: AnimateStoryClient
    ) {
        self.currentUserProvider = currentUserProvider
        self.authTokenProvider = authTokenProvider
        self.storyClient = storyClient
        super.init(workspaceObserver: workspaceObserver)
    }

    var isConfigured: Bool {
        storyClient.isConfigured
    }

    func canPlan(template: MomentTemplate) -> Bool {
        return currentUserProvider.currentUserId != nil
            && isConfigured
            && AnimateStoryRules.availability(
                mediaAssets: activeWorkspace?.mediaAssets,
                template: template
            ).canPlan
            && !isPlanning
    }

    func generatePlan(
        momentId: String,
        form: MomentSetupForm,
        selectedMedia: [MomentsSelectedMedia],
        persistedMedia: [AnimateStoryMedia]? = nil
    ) async -> Bool {
        guard let ownerUserId = currentUserProvider.currentUserId else {
            statusMessage = L10n.string("workflow.story.signInPlan")
            return false
        }
        guard let bearerToken = try? await authTokenProvider.currentBearerToken() else {
            statusMessage = L10n.string("workflow.story.signInAgainPlan")
            return false
        }
        guard isConfigured else {
            statusMessage = L10n.string("workflow.story.notConfigured")
            return false
        }

        let media = persistedMedia ?? storyMedia(from: selectedMedia, fallbackMediaAssets: activeWorkspace?.mediaAssets)
        let availability = MomentsMediaRules.availability(
            template: form.template,
            selectedCount: media.filter(\.selected).count
        )
        guard availability.canUseSelection else {
            statusMessage = generateBlockMessage(availability)
            return false
        }

        let generation = beginWorkflowGeneration()
        isPlanning = true
        statusMessage = nil
        MomentsWorkflowDiagnostics.addBreadcrumb(
            feature: "animate.story",
            operation: "generate_plan",
            data: [
                "selected_count": String(media.filter(\.selected).count),
                "total_count": String(media.count),
            ]
        )

        do {
            let plan = try await storyClient.generatePlan(
                momentId: momentId,
                ownerUserId: ownerUserId,
                bearerToken: bearerToken,
                form: form,
                selectedMedia: media
            )
            guard isCurrentWorkflowGeneration(generation) else { return false }
            try validatePlanMediaReferences(plan, availableMedia: media)
            generatedPlan = plan
            guard isCurrentWorkflowGeneration(generation) else { return false }
            workspaceObserver.observeWorkspace(ownerUserId: ownerUserId, momentId: momentId)
            statusMessage = plan.helperCopy
        } catch let error as StoryWorkflowError {
            guard isCurrentWorkflowGeneration(generation) else { return false }
            logger.error("Story plan workflow failed momentId=\(momentId, privacy: .public) reason=\(error.localizedDescription, privacy: .public)")
            MomentsWorkflowDiagnostics.capture(
                error,
                feature: "animate.story",
                operation: "generate_plan",
                step: "workflow",
                data: [
                    "selected_count": String(media.filter(\.selected).count),
                    "total_count": String(media.count),
                ]
            )
            statusMessage = error.localizedDescription
            isPlanning = false
            return false
        } catch let error as LocalizedError {
            guard isCurrentWorkflowGeneration(generation) else { return false }
            logger.error("Story plan request failed momentId=\(momentId, privacy: .public) error=\(String(describing: error), privacy: .public)")
            MomentsWorkflowDiagnostics.capture(
                error,
                feature: "animate.story",
                operation: "generate_plan",
                step: "request",
                data: [
                    "selected_count": String(media.filter(\.selected).count),
                    "total_count": String(media.count),
                ]
            )
            statusMessage = MomentsRecoveryCopy.storyFailure()
            isPlanning = false
            return false
        } catch {
            guard isCurrentWorkflowGeneration(generation) else { return false }
            logger.error("Story plan failed momentId=\(momentId, privacy: .public) error=\(String(describing: error), privacy: .public)")
            MomentsWorkflowDiagnostics.capture(
                error,
                feature: "animate.story",
                operation: "generate_plan",
                step: "unknown",
                data: [
                    "selected_count": String(media.filter(\.selected).count),
                    "total_count": String(media.count),
                ]
            )
            statusMessage = MomentsRecoveryCopy.storyFailure()
            isPlanning = false
            return false
        }

        guard isCurrentWorkflowGeneration(generation) else { return false }
        isPlanning = false
        return true
    }

    func reset(force: Bool = false) {
        guard force || !isPlanning else { return }
        advanceWorkflowGeneration()
        isPlanning = false
        clearActiveWorkspace()
        generatedPlan = nil
        statusMessage = nil
    }

    private func storyMedia(
        from selectedMedia: [MomentsSelectedMedia],
        fallbackMediaAssets: [MomentMediaAsset]?
    ) -> [AnimateStoryMedia] {
        if !selectedMedia.isEmpty {
            return selectedMedia
                .filter(\.selected)
                .sorted { $0.sortOrder < $1.sortOrder }
                .map {
                    AnimateStoryMedia(
                        mediaAssetId: $0.id.uuidString,
                        mediaKind: $0.kind,
                        sortOrder: $0.sortOrder,
                        selected: $0.selected,
                        moderationStatus: "pending"
                    )
                }
        }

        return (fallbackMediaAssets ?? [])
            .filter(\.selected)
            .sorted { $0.sortOrder < $1.sortOrder }
            .map {
                AnimateStoryMedia(
                    mediaAssetId: $0.id,
                    mediaKind: $0.kind,
                    sortOrder: Int($0.sortOrder),
                    selected: $0.selected,
                    moderationStatus: $0.moderationStatus
                )
            }
    }

    private func validatePlanMediaReferences(
        _ plan: AnimateStoryResponse,
        availableMedia: [AnimateStoryMedia]
    ) throws {
        let availableMediaIds = Set(availableMedia.map(\.mediaAssetId))
        let missingMediaIds = plan.scenes
            .flatMap(\.mediaAssetIds)
            .filter { !availableMediaIds.contains($0) }

        guard missingMediaIds.isEmpty else {
            throw StoryWorkflowError.invalidMediaReferences
        }
    }

    private func generateBlockMessage(_ availability: MomentsMediaRules.Availability) -> String {
        switch availability.blockReason {
        case nil:
            return L10n.string("create.story.status.ready")
        case .tooFewSelected(let missingCount):
            let label = missingCount == 1
                ? L10n.string("media.photoOrClip.singular")
                : L10n.string("media.photoOrClip.plural")
            return L10n.string("create.story.status.tooFew", missingCount, label)
        case .tooManySelected(let extraCount):
            let label = extraCount == 1
                ? L10n.string("media.photoOrClip.singular")
                : L10n.string("media.photoOrClip.plural")
            return L10n.string("create.story.status.tooMany", extraCount, label)
        }
    }
}

enum StoryWorkflowError: LocalizedError {
    case invalidMediaReferences
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .invalidMediaReferences:
            L10n.string("create.story.error.invalidMediaReferences")
        case .saveFailed:
            L10n.string("create.story.error.saveFailed")
        }
    }
}
