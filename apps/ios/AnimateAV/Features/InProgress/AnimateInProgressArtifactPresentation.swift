import Foundation

struct AnimateInProgressRenderJobsSectionPresentation: Equatable {
    let title = L10n.string("moment.activity.title")
    let emptySystemImage = "gearshape.2"
    let emptyMessage = L10n.string("moment.activity.empty")
    let jobs: [AnimateInProgressRenderJobPresentation]

    init(renderJobs: [AnimateRenderJob]) {
        jobs = AnimateInProgressRenderJobPresentation.sorted(renderJobs)
    }
}

struct AnimateInProgressArtifactSectionPresentation: Equatable {
    let title: String
    let emptySystemImage: String
    let emptyMessage: String
    let artifact: AnimateInProgressArtifactPresentation?

    static func finalExport(artifacts: [AnimateArtifact]) -> AnimateInProgressArtifactSectionPresentation {
        AnimateInProgressArtifactSectionPresentation(
            title: L10n.string("moment.artifact.final.title"),
            emptySystemImage: "video.fill",
            emptyMessage: L10n.string("moment.artifact.final.empty"),
            artifact: AnimateInProgressArtifactPresentation.finalExport(in: artifacts)
        )
    }
}

struct AnimateInProgressArtifactPresentation: Equatable {
    let status: String
    let kindTitle: String
    let watermarkTitle: String
    let expiresAtTitle: String
    let storageKey: String
    let actionDetail: String

    init(artifact: AnimateArtifact) {
        status = artifact.status
        kindTitle = AnimateStatusRules.displayKind(artifact.kind)
        watermarkTitle = artifact.hasWatermark == true ? L10n.string("moment.artifact.included") : L10n.string("moment.artifact.none")
        expiresAtTitle = AnimateDateFormatting.formattedDate(milliseconds: artifact.expiresAt)
        storageKey = artifact.r2Key
        actionDetail = AnimateRecoveryCopy.artifactActionDetail(kind: artifact.kind, status: artifact.status)
    }

    static func finalExport(in artifacts: [AnimateArtifact]) -> AnimateInProgressArtifactPresentation? {
        artifacts.last { $0.kind == "final_export" }.map(AnimateInProgressArtifactPresentation.init)
    }
}

struct AnimateInProgressRenderJobPresentation: Identifiable, Equatable {
    let id: String
    let status: String
    let kindTitle: String
    let providerTitle: String
    let modelTitle: String
    let createdAtTitle: String
    let updatedAtTitle: String
    let workflowRunId: String?
    let providerRequestId: String?
    let errorCode: String?
    let errorMessage: String?

    init(renderJob: AnimateRenderJob) {
        id = renderJob.id
        status = renderJob.status
        kindTitle = AnimateStatusRules.displayKind(renderJob.kind)
        providerTitle = renderJob.provider == nil ? L10n.string("moment.job.notRecorded") : L10n.string("moment.job.recorded")
        modelTitle = renderJob.model == nil ? L10n.string("moment.job.notRecorded") : L10n.string("moment.job.configured")
        createdAtTitle = AnimateDateFormatting.formattedDate(milliseconds: renderJob.createdAt)
        updatedAtTitle = AnimateDateFormatting.formattedDate(milliseconds: renderJob.updatedAt)
        workflowRunId = renderJob.workflowRunId
        providerRequestId = renderJob.providerRequestId
        errorCode = renderJob.errorCode
        errorMessage = renderJob.status == "failed"
            ? AnimateRecoveryCopy.failedRenderDetail(
                userMessage: renderJob.userMessage,
                errorMessage: renderJob.errorMessage
            )
            : renderJob.errorMessage
    }

    static func sorted(_ renderJobs: [AnimateRenderJob]) -> [AnimateInProgressRenderJobPresentation] {
        renderJobs
            .sorted { $0.updatedAt > $1.updatedAt }
            .map(AnimateInProgressRenderJobPresentation.init)
    }
}
