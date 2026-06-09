import Foundation
import OSLog

@MainActor
final class VideoDirectionWorkflow: WorkspaceObservingWorkflow {
    @Published private(set) var generatedPlan: AnimateVideoDirectionResponse?
    @Published private(set) var isPlanning = false
    @Published private(set) var statusMessage: String?

    private let currentUserProvider: any AnimateCurrentUserProviding
    private let authTokenProvider: any AnimateAuthTokenProviding
    private let videoDirectionClient: AnimateVideoDirectionClient
    private let logger = Logger(subsystem: "com.avalsys.animateav", category: "story")

    init(
        currentUserProvider: any AnimateCurrentUserProviding,
        authTokenProvider: any AnimateAuthTokenProviding,
        workspaceObserver: any AnimateActiveWorkspaceObserving,
        videoDirectionClient: AnimateVideoDirectionClient
    ) {
        self.currentUserProvider = currentUserProvider
        self.authTokenProvider = authTokenProvider
        self.videoDirectionClient = videoDirectionClient
        super.init(workspaceObserver: workspaceObserver)
    }

    var isConfigured: Bool {
        videoDirectionClient.isConfigured
    }

    func canPlan(template: AnimateVideoTemplate) -> Bool {
        return currentUserProvider.currentUserId != nil
            && isConfigured
            && AnimateVideoDirectionRules.availability(
                mediaAssets: activeWorkspace?.mediaAssets,
                template: template
            ).canPlan
            && !isPlanning
    }

    func generatePlan(
        videoId: String,
        form: AnimateVideoSetupForm,
        selectedMedia: [AnimateSelectedMedia],
        persistedMedia: [AnimateVideoDirectionMedia]? = nil
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
        let availability = AnimateMediaRules.availability(
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
        AnimateWorkflowDiagnostics.addBreadcrumb(
            feature: "animate.story",
            operation: "generate_plan",
            data: [
                "selected_count": String(media.filter(\.selected).count),
                "total_count": String(media.count),
            ]
        )

        do {
            let plan = try await videoDirectionClient.generatePlan(
                videoId: videoId,
                ownerUserId: ownerUserId,
                bearerToken: bearerToken,
                form: form,
                selectedMedia: media
            )
            guard isCurrentWorkflowGeneration(generation) else { return false }
            try validatePlanMediaReferences(plan, availableMedia: media)
            generatedPlan = plan
            guard isCurrentWorkflowGeneration(generation) else { return false }
            workspaceObserver.observeWorkspace(ownerUserId: ownerUserId, videoId: videoId)
            statusMessage = plan.helperCopy
        } catch let error as VideoDirectionWorkflowError {
            guard isCurrentWorkflowGeneration(generation) else { return false }
            logger.error("Video direction workflow failed videoId=\(videoId, privacy: .public) reason=\(error.localizedDescription, privacy: .public)")
            AnimateWorkflowDiagnostics.capture(
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
            logger.error("Video direction request failed videoId=\(videoId, privacy: .public) error=\(String(describing: error), privacy: .public)")
            AnimateWorkflowDiagnostics.capture(
                error,
                feature: "animate.story",
                operation: "generate_plan",
                step: "request",
                data: [
                    "selected_count": String(media.filter(\.selected).count),
                    "total_count": String(media.count),
                ]
            )
            statusMessage = AnimateRecoveryCopy.storyFailure()
            isPlanning = false
            return false
        } catch {
            guard isCurrentWorkflowGeneration(generation) else { return false }
            logger.error("Video direction failed videoId=\(videoId, privacy: .public) error=\(String(describing: error), privacy: .public)")
            AnimateWorkflowDiagnostics.capture(
                error,
                feature: "animate.story",
                operation: "generate_plan",
                step: "unknown",
                data: [
                    "selected_count": String(media.filter(\.selected).count),
                    "total_count": String(media.count),
                ]
            )
            statusMessage = AnimateRecoveryCopy.storyFailure()
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
        from selectedMedia: [AnimateSelectedMedia],
        fallbackMediaAssets: [AnimateMediaAsset]?
    ) -> [AnimateVideoDirectionMedia] {
        if !selectedMedia.isEmpty {
            return selectedMedia
                .filter(\.selected)
                .sorted { $0.sortOrder < $1.sortOrder }
                .map {
                    AnimateVideoDirectionMedia(
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
                AnimateVideoDirectionMedia(
                    mediaAssetId: $0.id,
                    mediaKind: $0.kind,
                    sortOrder: Int($0.sortOrder),
                    selected: $0.selected,
                    moderationStatus: $0.moderationStatus
                )
            }
    }

    private func validatePlanMediaReferences(
        _ plan: AnimateVideoDirectionResponse,
        availableMedia: [AnimateVideoDirectionMedia]
    ) throws {
        let availableMediaIds = Set(availableMedia.map(\.mediaAssetId))
        let missingMediaIds = plan.scenes
            .flatMap(\.mediaAssetIds)
            .filter { !availableMediaIds.contains($0) }

        guard missingMediaIds.isEmpty else {
            throw VideoDirectionWorkflowError.invalidMediaReferences
        }
    }

    private func generateBlockMessage(_ availability: AnimateMediaRules.Availability) -> String {
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

enum VideoDirectionWorkflowError: LocalizedError {
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
