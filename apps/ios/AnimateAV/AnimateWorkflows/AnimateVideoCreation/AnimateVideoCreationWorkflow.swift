import Foundation
import OSLog

@MainActor
final class AnimateVideoCreationWorkflow: ObservableObject {
    @Published private(set) var isCreatingVideo = false
    @Published private(set) var activeVideoId: String?
    @Published private(set) var errorMessage: String?

    private let currentUserProvider: any AnimateCurrentUserProviding
    private let authTokenProvider: any AnimateAuthTokenProviding
    private let creditBalanceProvider: any AnimateCreditBalanceProviding
    private let videoCreator: any AnimateVideoCreating
    private let videoDeleter: any AnimateVideoDeleting
    private let workspaceObserver: any AnimateActiveWorkspaceObserving
    private var workflowGeneration = WorkflowGeneration()
    private let logger = Logger(subsystem: "com.avalsys.animateav", category: "moment-creation")

    init(
        currentUserProvider: any AnimateCurrentUserProviding,
        authTokenProvider: any AnimateAuthTokenProviding,
        creditBalanceProvider: any AnimateCreditBalanceProviding,
        videoCreator: any AnimateVideoCreating,
        videoDeleter: any AnimateVideoDeleting,
        workspaceObserver: any AnimateActiveWorkspaceObserving
    ) {
        self.currentUserProvider = currentUserProvider
        self.authTokenProvider = authTokenProvider
        self.creditBalanceProvider = creditBalanceProvider
        self.videoCreator = videoCreator
        self.videoDeleter = videoDeleter
        self.workspaceObserver = workspaceObserver
    }

    var launchTemplates: [AnimateVideoTemplate] {
        AnimateVideoTemplate.launchTemplates
    }

    var balance: AnimateCreditBalance {
        creditBalanceProvider.currentCreditBalance
    }

    var isConfigured: Bool {
        videoCreator.isConfigured
    }

    func canAfford(_ template: AnimateVideoTemplate) -> Bool {
        AnimateCreditGate.canAfford(template, balance: balance)
    }

    func spendPlan(for template: AnimateVideoTemplate) -> AnimateCreditSpendPlan? {
        AnimateCreditGate.spendPlan(for: template.creditCost, balance: balance)
    }

    func createVideo(form: AnimateVideoSetupForm) async -> String? {
        guard !isCreatingVideo else { return nil }
        guard let ownerUserId = currentUserProvider.currentUserId else {
            errorMessage = L10n.string("workflow.video.signInStart")
            return nil
        }
        guard let bearerToken = try? await authTokenProvider.currentBearerToken() else {
            errorMessage = L10n.string("workflow.story.signInAgainPlan")
            return nil
        }

        let availability = AnimateVideoSetupRules.availability(form: form, balance: balance)
        guard availability.canCreateVideo else {
            errorMessage = createVideoBlockMessage(availability)
            return nil
        }

        let generation = workflowGeneration.begin()
        isCreatingVideo = true
        errorMessage = nil

        do {
            let momentId = try await videoCreator.createVideo(bearerToken: bearerToken, form: form)
            guard workflowGeneration.isCurrent(generation) else { return nil }
            activeVideoId = momentId
            workspaceObserver.observeWorkspace(ownerUserId: ownerUserId, momentId: momentId)
            isCreatingVideo = false
            return momentId
        } catch {
            guard workflowGeneration.isCurrent(generation) else { return nil }
            logger.error("Moment creation failed reason=\(String(describing: error), privacy: .public)")
            errorMessage = error.localizedDescription
            isCreatingVideo = false
            return nil
        }
    }

    func updateVideoSetup(momentId: String, form: AnimateVideoSetupForm) async -> Bool {
        guard !isCreatingVideo else { return false }
        guard currentUserProvider.currentUserId != nil else {
            errorMessage = L10n.string("workflow.video.signInContinue")
            return false
        }
        guard let bearerToken = try? await authTokenProvider.currentBearerToken() else {
            errorMessage = L10n.string("workflow.story.signInAgainPlan")
            return false
        }

        let availability = AnimateVideoSetupRules.availability(form: form, balance: balance)
        guard availability.canCreateVideo else {
            errorMessage = createVideoBlockMessage(availability)
            return false
        }

        isCreatingVideo = true
        errorMessage = nil

        do {
            try await videoCreator.updateVideoSetup(
                bearerToken: bearerToken,
                momentId: momentId,
                form: form
            )
            isCreatingVideo = false
            return true
        } catch {
            logger.error("Moment setup update failed reason=\(String(describing: error), privacy: .public)")
            errorMessage = error.localizedDescription
            isCreatingVideo = false
            return false
        }
    }

    func continueVideo(_ video: AnimateVideo) {
        guard let ownerUserId = currentUserProvider.currentUserId else {
            errorMessage = L10n.string("workflow.video.signInContinue")
            return
        }

        workflowGeneration.advance()
        isCreatingVideo = false
        activeVideoId = video.id
        errorMessage = nil
        workspaceObserver.observeWorkspace(ownerUserId: ownerUserId, momentId: video.id)
    }

    func resetVideoSetup(force: Bool = false) {
        guard force || !isCreatingVideo else { return }
        workflowGeneration.advance()
        isCreatingVideo = false
        activeVideoId = nil
        errorMessage = nil
        workspaceObserver.clearWorkspace()
    }

    func discardActiveVideo(momentId momentIdOverride: String? = nil) async -> Bool {
        guard !isCreatingVideo else { return false }
        guard currentUserProvider.currentUserId != nil else {
            errorMessage = L10n.string("workflow.video.signInDiscard")
            return false
        }
        guard let bearerToken = try? await authTokenProvider.currentBearerToken() else {
            errorMessage = L10n.string("workflow.story.signInAgainPlan")
            return false
        }
        guard let momentId = momentIdOverride ?? activeVideoId else { return true }

        let generation = workflowGeneration.begin()
        isCreatingVideo = true
        errorMessage = nil

        do {
            try await videoDeleter.deleteVideo(bearerToken: bearerToken, momentId: momentId)
            guard workflowGeneration.isCurrent(generation) else { return false }
            isCreatingVideo = false
            self.activeVideoId = nil
            workspaceObserver.clearWorkspace()
            return true
        } catch {
            guard workflowGeneration.isCurrent(generation) else { return false }
            errorMessage = error.localizedDescription
            isCreatingVideo = false
            return false
        }
    }

    private func createVideoBlockMessage(_ availability: AnimateVideoSetupRules.Availability) -> String {
        AnimateVideoSetupRules.availabilityMessage(availability) ?? L10n.string("workflow.video.setupNotReady")
    }
}
