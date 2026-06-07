import Foundation

struct MomentsInProgressRenderJobsSectionPresentation: Equatable {
    let title = L10n.string("moment.activity.title")
    let emptySystemImage = "gearshape.2"
    let emptyMessage = L10n.string("moment.activity.empty")
    let jobs: [MomentsInProgressRenderJobPresentation]

    init(renderJobs: [MomentRenderJob]) {
        jobs = MomentsInProgressRenderJobPresentation.sorted(renderJobs)
    }
}

struct MomentsInProgressArtifactSectionPresentation: Equatable {
    let title: String
    let emptySystemImage: String
    let emptyMessage: String
    let artifact: MomentsInProgressArtifactPresentation?

    static func finalExport(artifacts: [MomentArtifact]) -> MomentsInProgressArtifactSectionPresentation {
        MomentsInProgressArtifactSectionPresentation(
            title: L10n.string("moment.artifact.final.title"),
            emptySystemImage: "video.fill",
            emptyMessage: L10n.string("moment.artifact.final.empty"),
            artifact: MomentsInProgressArtifactPresentation.finalExport(in: artifacts)
        )
    }
}

struct MomentsInProgressArtifactPresentation: Equatable {
    let status: String
    let kindTitle: String
    let watermarkTitle: String
    let expiresAtTitle: String
    let storageKey: String
    let actionDetail: String

    init(artifact: MomentArtifact) {
        status = artifact.status
        kindTitle = MomentStatusRules.displayKind(artifact.kind)
        watermarkTitle = artifact.hasWatermark == true ? L10n.string("moment.artifact.included") : L10n.string("moment.artifact.none")
        expiresAtTitle = AnimateDateFormatting.formattedDate(milliseconds: artifact.expiresAt)
        storageKey = artifact.r2Key
        actionDetail = MomentsRecoveryCopy.artifactActionDetail(kind: artifact.kind, status: artifact.status)
    }

    static func finalExport(in artifacts: [MomentArtifact]) -> MomentsInProgressArtifactPresentation? {
        artifacts.last { $0.kind == "final_export" }.map(MomentsInProgressArtifactPresentation.init)
    }
}

struct MomentsInProgressRenderJobPresentation: Identifiable, Equatable {
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

    init(renderJob: MomentRenderJob) {
        id = renderJob.id
        status = renderJob.status
        kindTitle = MomentStatusRules.displayKind(renderJob.kind)
        providerTitle = renderJob.provider == nil ? L10n.string("moment.job.notRecorded") : L10n.string("moment.job.recorded")
        modelTitle = renderJob.model == nil ? L10n.string("moment.job.notRecorded") : L10n.string("moment.job.configured")
        createdAtTitle = AnimateDateFormatting.formattedDate(milliseconds: renderJob.createdAt)
        updatedAtTitle = AnimateDateFormatting.formattedDate(milliseconds: renderJob.updatedAt)
        workflowRunId = renderJob.workflowRunId
        providerRequestId = renderJob.providerRequestId
        errorCode = renderJob.errorCode
        errorMessage = renderJob.status == "failed"
            ? MomentsRecoveryCopy.failedRenderDetail(
                userMessage: renderJob.userMessage,
                errorMessage: renderJob.errorMessage
            )
            : renderJob.errorMessage
    }

    static func sorted(_ renderJobs: [MomentRenderJob]) -> [MomentsInProgressRenderJobPresentation] {
        renderJobs
            .sorted { $0.updatedAt > $1.updatedAt }
            .map(MomentsInProgressRenderJobPresentation.init)
    }
}
