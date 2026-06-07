import Foundation
import OSLog

@MainActor
final class MomentCreationWorkflow: ObservableObject {
    @Published private(set) var isCreatingMoment = false
    @Published private(set) var activeMomentId: String?
    @Published private(set) var errorMessage: String?

    private let currentUserProvider: any MomentsCurrentUserProviding
    private let authTokenProvider: any MomentsAuthTokenProviding
    private let creditBalanceProvider: any AnimateCreditBalanceProviding
    private let momentCreator: any MomentsCreating
    private let momentDeleter: any MomentsDeleting
    private let workspaceObserver: any MomentsActiveWorkspaceObserving
    private var workflowGeneration = WorkflowGeneration()
    private let logger = Logger(subsystem: "com.avalsys.animateav", category: "moment-creation")

    init(
        currentUserProvider: any MomentsCurrentUserProviding,
        authTokenProvider: any MomentsAuthTokenProviding,
        creditBalanceProvider: any AnimateCreditBalanceProviding,
        momentCreator: any MomentsCreating,
        momentDeleter: any MomentsDeleting,
        workspaceObserver: any MomentsActiveWorkspaceObserving
    ) {
        self.currentUserProvider = currentUserProvider
        self.authTokenProvider = authTokenProvider
        self.creditBalanceProvider = creditBalanceProvider
        self.momentCreator = momentCreator
        self.momentDeleter = momentDeleter
        self.workspaceObserver = workspaceObserver
    }

    var launchTemplates: [MomentTemplate] {
        MomentTemplate.launchTemplates
    }

    var balance: AnimateCreditBalance {
        creditBalanceProvider.currentCreditBalance
    }

    var isConfigured: Bool {
        momentCreator.isConfigured
    }

    func canAfford(_ template: MomentTemplate) -> Bool {
        AnimateCreditGate.canAfford(template, balance: balance)
    }

    func spendPlan(for template: MomentTemplate) -> AnimateCreditSpendPlan? {
        AnimateCreditGate.spendPlan(for: template.creditCost, balance: balance)
    }

    func createMoment(form: MomentSetupForm) async -> String? {
        guard !isCreatingMoment else { return nil }
        guard let ownerUserId = currentUserProvider.currentUserId else {
            errorMessage = L10n.string("workflow.moment.signInStart")
            return nil
        }
        guard let bearerToken = try? await authTokenProvider.currentBearerToken() else {
            errorMessage = L10n.string("workflow.story.signInAgainPlan")
            return nil
        }

        let availability = MomentSetupRules.availability(form: form, balance: balance)
        guard availability.canCreateMoment else {
            errorMessage = createMomentBlockMessage(availability)
            return nil
        }

        let generation = workflowGeneration.begin()
        isCreatingMoment = true
        errorMessage = nil

        do {
            let momentId = try await momentCreator.createMoment(bearerToken: bearerToken, form: form)
            guard workflowGeneration.isCurrent(generation) else { return nil }
            activeMomentId = momentId
            workspaceObserver.observeWorkspace(ownerUserId: ownerUserId, momentId: momentId)
            isCreatingMoment = false
            return momentId
        } catch {
            guard workflowGeneration.isCurrent(generation) else { return nil }
            logger.error("Moment creation failed reason=\(String(describing: error), privacy: .public)")
            errorMessage = error.localizedDescription
            isCreatingMoment = false
            return nil
        }
    }

    func updateMomentSetup(momentId: String, form: MomentSetupForm) async -> Bool {
        guard !isCreatingMoment else { return false }
        guard currentUserProvider.currentUserId != nil else {
            errorMessage = L10n.string("workflow.moment.signInContinue")
            return false
        }
        guard let bearerToken = try? await authTokenProvider.currentBearerToken() else {
            errorMessage = L10n.string("workflow.story.signInAgainPlan")
            return false
        }

        let availability = MomentSetupRules.availability(form: form, balance: balance)
        guard availability.canCreateMoment else {
            errorMessage = createMomentBlockMessage(availability)
            return false
        }

        isCreatingMoment = true
        errorMessage = nil

        do {
            try await momentCreator.updateMomentSetup(
                bearerToken: bearerToken,
                momentId: momentId,
                form: form
            )
            isCreatingMoment = false
            return true
        } catch {
            logger.error("Moment setup update failed reason=\(String(describing: error), privacy: .public)")
            errorMessage = error.localizedDescription
            isCreatingMoment = false
            return false
        }
    }

    func continueMoment(_ moment: InProgressMoment) {
        guard let ownerUserId = currentUserProvider.currentUserId else {
            errorMessage = L10n.string("workflow.moment.signInContinue")
            return
        }

        workflowGeneration.advance()
        isCreatingMoment = false
        activeMomentId = moment.id
        errorMessage = nil
        workspaceObserver.observeWorkspace(ownerUserId: ownerUserId, momentId: moment.id)
    }

    func resetMomentSetup(force: Bool = false) {
        guard force || !isCreatingMoment else { return }
        workflowGeneration.advance()
        isCreatingMoment = false
        activeMomentId = nil
        errorMessage = nil
        workspaceObserver.clearWorkspace()
    }

    func discardActiveMoment(momentId momentIdOverride: String? = nil) async -> Bool {
        guard !isCreatingMoment else { return false }
        guard currentUserProvider.currentUserId != nil else {
            errorMessage = L10n.string("workflow.moment.signInDiscard")
            return false
        }
        guard let bearerToken = try? await authTokenProvider.currentBearerToken() else {
            errorMessage = L10n.string("workflow.story.signInAgainPlan")
            return false
        }
        guard let momentId = momentIdOverride ?? activeMomentId else { return true }

        let generation = workflowGeneration.begin()
        isCreatingMoment = true
        errorMessage = nil

        do {
            try await momentDeleter.deleteMoment(bearerToken: bearerToken, momentId: momentId)
            guard workflowGeneration.isCurrent(generation) else { return false }
            isCreatingMoment = false
            self.activeMomentId = nil
            workspaceObserver.clearWorkspace()
            return true
        } catch {
            guard workflowGeneration.isCurrent(generation) else { return false }
            errorMessage = error.localizedDescription
            isCreatingMoment = false
            return false
        }
    }

    private func createMomentBlockMessage(_ availability: MomentSetupRules.Availability) -> String {
        MomentSetupRules.availabilityMessage(availability) ?? L10n.string("workflow.moment.setupNotReady")
    }
}
