import Combine
import Foundation

@MainActor
final class MomentsGalleryViewModel: ObservableObject {
    @Published private(set) var videos: [MomentsGalleryVideoPresentation] = []
    @Published private(set) var statusMessage: String?

    private var galleryCancellables = Set<AnyCancellable>()
    private let galleryStore: any MomentsGalleryStoring
    private let galleryMomentsProvider: (any GalleryMomentsListProviding)?
    private let authTokenProvider: (any MomentsAuthTokenProviding)?
    private let finalRenderClient: MomentsFinalRenderClient?
    private var remoteMoments: [InProgressMoment] = []

    init(
        galleryStore: any MomentsGalleryStoring = MomentsGalleryStore(),
        galleryMomentsProvider: (any GalleryMomentsListProviding)? = nil,
        authTokenProvider: (any MomentsAuthTokenProviding)? = nil,
        finalRenderClient: MomentsFinalRenderClient? = nil
    ) {
        self.galleryStore = galleryStore
        self.galleryMomentsProvider = galleryMomentsProvider
        self.authTokenProvider = authTokenProvider
        self.finalRenderClient = finalRenderClient
        refreshVideos()
        NotificationCenter.default.publisher(for: MomentsGalleryStore.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshVideos()
            }
            .store(in: &galleryCancellables)
        galleryMomentsProvider?.galleryMomentsPublisher
            .sink { [weak self] moments in
                self?.remoteMoments = moments
                self?.refreshVideos()
            }
            .store(in: &galleryCancellables)
        galleryMomentsProvider?.galleryMomentsErrorPublisher
            .sink { [weak self] message in
                self?.statusMessage = message
            }
            .store(in: &galleryCancellables)
    }

    func refreshVideos() {
        let localRecords = galleryStore.loadRecords()
        var presentations: [MomentsGalleryVideoPresentation] = localRecords.map { record in
            let localFileExists = galleryStore.localFileExists(for: record)
            let remoteArtifact = remoteMoments
                .first { $0.id == record.momentId || $0.finalExport?.id == record.artifactId || $0.finalExport?.workflowArtifactId == record.artifactId }?
                .finalExport
            return MomentsGalleryVideoPresentation(
                record: record,
                localFileURL: galleryStore.localFileURL(for: record),
                availability: localFileExists ? .savedOnDevice : availabilityForMissingLocalFile(remoteArtifact: remoteArtifact),
                remoteArtifact: remoteArtifact
            )
        }

        for moment in remoteMoments {
            guard let artifact = moment.finalExport else { continue }
            let artifactId = artifact.workflowArtifactId ?? artifact.id
            let alreadyPresented = presentations.contains { presentation in
                presentation.record.artifactId == artifactId
                    || presentation.record.artifactId == artifact.id
                    || presentation.record.momentId == moment.id
            }
            guard !alreadyPresented else { continue }

            let record = MomentsGalleryVideoRecord(
                id: artifactId,
                momentId: moment.id,
                artifactId: artifactId,
                title: moment.title,
                r2Key: artifact.r2Key,
                localRelativePath: "Videos/\(artifactId).mp4",
                createdAt: artifact.createdAt
            )
            presentations.append(
                MomentsGalleryVideoPresentation(
                    record: record,
                    localFileURL: nil,
                    availability: availabilityForRemoteOnlyArtifact(artifact),
                    remoteArtifact: artifact
                )
            )
        }

        videos = presentations.sorted { $0.record.createdAt > $1.record.createdAt }
    }

    func deleteVideo(_ video: MomentsGalleryVideoPresentation) {
        galleryStore.deleteRecord(video.record, deleteLocalFile: true)
        refreshVideos()
    }

    func renameVideo(_ video: MomentsGalleryVideoPresentation, title: String) {
        guard video.localFileURL != nil else { return }
        galleryStore.renameRecord(video.record, title: title)
        refreshVideos()
    }

    func redownloadVideo(_ video: MomentsGalleryVideoPresentation) {
        guard video.canDownload else { return }
        guard let remoteArtifact = video.remoteArtifact,
              let authTokenProvider,
              let finalRenderClient
        else {
            statusMessage = L10n.string("gallery.video.downloadUnavailable")
            return
        }

        Task { [weak self] in
            do {
                guard let bearerToken = try await authTokenProvider.currentBearerToken() else {
                    self?.statusMessage = L10n.string("workflow.final.signInAgainSaveLocal")
                    return
                }
                let artifactId = remoteArtifact.workflowArtifactId ?? remoteArtifact.id
                let download = try await finalRenderClient.prepareFinalArtifactDownload(
                    momentId: video.record.momentId,
                    artifactId: artifactId,
                    bearerToken: bearerToken
                )
                let temporaryFileURL = try await finalRenderClient.downloadFinalArtifact(from: download)
                let record = try self?.galleryStore.saveDownloadedVideo(
                    temporaryFileURL: temporaryFileURL,
                    momentId: video.record.momentId,
                    artifactId: artifactId,
                    title: video.title,
                    r2Key: download.r2Key ?? remoteArtifact.r2Key,
                    createdAt: Date()
                )
                if let record {
                    self?.galleryStore.addRecord(record)
                }
                self?.statusMessage = L10n.string("gallery.video.downloaded")
                self?.refreshVideos()
            } catch {
                self?.statusMessage = L10n.string("gallery.video.downloadFailed")
            }
        }
    }

    private func availabilityForMissingLocalFile(remoteArtifact: MomentArtifact?) -> MomentsGalleryVideoAvailability {
        guard let remoteArtifact else { return .localFileMissing }
        return availabilityForRemoteOnlyArtifact(remoteArtifact)
    }

    private func availabilityForRemoteOnlyArtifact(_ artifact: MomentArtifact) -> MomentsGalleryVideoAvailability {
        guard artifact.status == "available" else { return .downloadUnavailable }
        guard artifact.expiresAt > Date().timeIntervalSince1970 * 1000 else { return .downloadUnavailable }
        return .downloadAvailable
    }
}
