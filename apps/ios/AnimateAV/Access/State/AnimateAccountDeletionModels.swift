import Foundation

struct AccountSummary: Decodable, Equatable {
    let id: String?
    let emailAddress: String?
    let displayName: String?
    let linkedApps: [LinkedAccountApp]
    let access: [AnimateAppAccess]
    let billing: AccountBillingSummary?
    let currentDeletionJob: AccountDeletionJob?
    let deleteAccountEligibility: AccountDeletionEligibility?

    enum CodingKeys: String, CodingKey {
        case id, emailAddress, email, displayName, name, user, linkedApps, apps, access, billing, currentDeletionJob, deleteAccountEligibility
    }

    init(
        id: String? = nil,
        emailAddress: String? = nil,
        displayName: String? = nil,
        linkedApps: [LinkedAccountApp] = [],
        access: [AnimateAppAccess] = [],
        billing: AccountBillingSummary? = nil,
        currentDeletionJob: AccountDeletionJob? = nil,
        deleteAccountEligibility: AccountDeletionEligibility? = nil
    ) {
        self.id = id
        self.emailAddress = emailAddress
        self.displayName = displayName
        self.linkedApps = linkedApps
        self.access = access
        self.billing = billing
        self.currentDeletionJob = currentDeletionJob
        self.deleteAccountEligibility = deleteAccountEligibility
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let user = try container.decodeIfPresent(AccountSummaryUser.self, forKey: .user)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? user?.id
        emailAddress = try container.decodeIfPresent(String.self, forKey: .emailAddress)
            ?? container.decodeIfPresent(String.self, forKey: .email)
            ?? user?.emailAddress
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
            ?? container.decodeIfPresent(String.self, forKey: .name)
            ?? user?.displayName
        linkedApps = try container.decodeIfPresent([LinkedAccountApp].self, forKey: .linkedApps) ?? []
        access = try container.decodeIfPresent([AnimateAppAccess].self, forKey: .access)
            ?? container.decodeIfPresent([AnimateAppAccess].self, forKey: .apps)
            ?? []
        billing = try container.decodeIfPresent(AccountBillingSummary.self, forKey: .billing)
        currentDeletionJob = try container.decodeIfPresent(AccountDeletionJob.self, forKey: .currentDeletionJob)
        deleteAccountEligibility = try container.decodeIfPresent(AccountDeletionEligibility.self, forKey: .deleteAccountEligibility)
    }
}

private struct AccountSummaryUser: Decodable, Equatable {
    let id: String?
    let emailAddress: String?
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case id, email, emailAddress, displayName, name
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id)
        emailAddress = try container.decodeIfPresent(String.self, forKey: .emailAddress)
            ?? container.decodeIfPresent(String.self, forKey: .email)
        displayName = try container.decodeIfPresent(String.self, forKey: .displayName)
            ?? container.decodeIfPresent(String.self, forKey: .name)
    }
}

struct LinkedAccountApp: Decodable, Equatable, Identifiable {
    let appId: String
    let label: String?

    var id: String { appId }
}

struct AnimateAppAccess: Decodable, Equatable {
    let appId: String
    let accessMode: String?
    let planTier: String?
}

struct AccountBillingSummary: Decodable, Equatable {
    let subscriptions: [AccountBillingSubscription]

    enum CodingKeys: String, CodingKey {
        case subscriptions
    }

    init(subscriptions: [AccountBillingSubscription] = []) {
        self.subscriptions = subscriptions
    }

    init(from decoder: Decoder) throws {
        if var unkeyedContainer = try? decoder.unkeyedContainer() {
            var decodedSubscriptions: [AccountBillingSubscription] = []
            while !unkeyedContainer.isAtEnd {
                decodedSubscriptions.append(try unkeyedContainer.decode(AccountBillingSubscription.self))
            }
            subscriptions = decodedSubscriptions
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        subscriptions = try container.decodeIfPresent([AccountBillingSubscription].self, forKey: .subscriptions) ?? []
    }
}

struct AccountBillingSubscription: Decodable, Equatable, Identifiable {
    let id: String
    let appId: String?
    let planId: String?
    let provider: String?
    let status: String
    let managementUrl: URL?

    enum CodingKeys: String, CodingKey {
        case id, appId, planId, name, provider, status, managementUrl, manageUrl
    }

    init(id: String, appId: String? = nil, planId: String? = nil, provider: String? = nil, status: String, managementUrl: URL? = nil) {
        self.id = id
        self.appId = appId
        self.planId = planId
        self.provider = provider
        self.status = status
        self.managementUrl = managementUrl
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appId = try container.decodeIfPresent(String.self, forKey: .appId)
        planId = try container.decodeIfPresent(String.self, forKey: .planId)
            ?? container.decodeIfPresent(String.self, forKey: .name)
        provider = try container.decodeIfPresent(String.self, forKey: .provider)
        status = try container.decode(String.self, forKey: .status)
        managementUrl = try container.decodeIfPresent(URL.self, forKey: .managementUrl)
            ?? container.decodeIfPresent(URL.self, forKey: .manageUrl)
        id = try container.decodeIfPresent(String.self, forKey: .id)
            ?? [appId, planId, provider, status].compactMap { $0 }.joined(separator: ":")
    }
}

struct AccountDeletionEligibility: Decodable, Equatable {
    let status: Status
    let blockers: [AccountDeletionBlocker]
    let warnings: [AccountDeletionBlocker]
    let currentJob: AccountDeletionJob?

    enum Status: String, Decodable {
        case eligible, blocked, inProgress, completed, unavailable
    }

    init(status: Status, blockers: [AccountDeletionBlocker], warnings: [AccountDeletionBlocker] = [], currentJob: AccountDeletionJob?) {
        self.status = status
        self.blockers = blockers
        self.warnings = warnings
        self.currentJob = currentJob
    }
}

struct AccountDeletionBlocker: Decodable, Equatable, Identifiable {
    let type: BlockerType
    let appId: String?
    let label: String
    let detail: String?
    let managementUrl: URL?

    var id: String {
        [type.rawValue, appId, label, detail].compactMap { $0 }.joined(separator: "|")
    }

    enum BlockerType: String, Decodable, Hashable {
        case linkedApp, activeAiCredits, activeProAccess, activeBillingSubscription, identityProvider, deletionInProgress, eligibilityUnavailable
    }
}

struct AccountDeletionJob: Decodable, Equatable, Identifiable {
    let id: String
    let status: String
    let detail: String?
}

struct DeleteAccountRequestResponse: Decodable, Equatable {
    let status: String?
    let job: AccountDeletionJob?
    let deletionJob: AccountDeletionJob?
    let deleteAccountEligibility: AccountDeletionEligibility?

    enum CodingKeys: String, CodingKey {
        case status, job, deletionJob, deleteAccountEligibility
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        let canonicalJob = try container.decodeIfPresent(AccountDeletionJob.self, forKey: .deletionJob)
        deletionJob = canonicalJob
        job = try container.decodeIfPresent(AccountDeletionJob.self, forKey: .job) ?? canonicalJob
        deleteAccountEligibility = try container.decodeIfPresent(AccountDeletionEligibility.self, forKey: .deleteAccountEligibility)
    }
}

struct DeleteAccountFinalizeResponse: Decodable, Equatable {
    let status: String?
    let job: AccountDeletionJob?
    let deletionJob: AccountDeletionJob?
    let deleteAccountEligibility: AccountDeletionEligibility?

    enum CodingKeys: String, CodingKey {
        case status, job, deletionJob, deleteAccountEligibility
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        let canonicalJob = try container.decodeIfPresent(AccountDeletionJob.self, forKey: .deletionJob)
        deletionJob = canonicalJob
        job = try container.decodeIfPresent(AccountDeletionJob.self, forKey: .job) ?? canonicalJob
        deleteAccountEligibility = try container.decodeIfPresent(AccountDeletionEligibility.self, forKey: .deleteAccountEligibility)
    }
}

struct UnlinkAppResponse: Decodable, Equatable {
    let link: UnlinkAppResult
    let message: String?
}

struct UnlinkAppResult: Decodable, Equatable {
    let appId: String
    let remainingLinkedApps: Int
    let unlinked: Bool
}
