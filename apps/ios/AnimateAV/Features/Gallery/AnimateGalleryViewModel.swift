import Combine
import Foundation

@MainActor
final class AnimateGalleryViewModel: ObservableObject {
    private static let dismissedRemoteVideoIdsDefaultsKey = "AnimateGallery.dismissedRemoteVideoIds"

    @Published private(set) var videos: [AnimateGalleryVideoPresentation] = []
    @Published private(set) var images: [AnimateGalleryImagePresentation] = []
    @Published private(set) var statusMessage: String?

    private var galleryCancellables = Set<AnyCancellable>()
    private let galleryStore: any AnimateGalleryStoring
    private let galleryArtifactsProvider: (any AnimateGalleryListProviding)?
    private let authTokenProvider: (any AnimateAuthTokenProviding)?
    private let finalRenderClient: AnimateFinalRenderClient?
    private var remoteArtifacts: [AnimateArtifact] = []
    private var currentOwnerUserId: String?
    private var downloadingImageIds = Set<String>()
    private var dismissedRemoteVideoIds: Set<String>
    private var dismissedRemoteImageIds = Set<String>()

    init(
        galleryStore: any AnimateGalleryStoring = AnimateGalleryStore(),
        galleryArtifactsProvider: (any AnimateGalleryListProviding)? = nil,
        authTokenProvider: (any AnimateAuthTokenProviding)? = nil,
        finalRenderClient: AnimateFinalRenderClient? = nil
    ) {
        self.galleryStore = galleryStore
        self.galleryArtifactsProvider = galleryArtifactsProvider
        self.authTokenProvider = authTokenProvider
        self.finalRenderClient = finalRenderClient
        self.dismissedRemoteVideoIds = Set(
            UserDefaults.standard.stringArray(forKey: Self.dismissedRemoteVideoIdsDefaultsKey) ?? []
        )
        refreshVideos()
        refreshImages()
        NotificationCenter.default.publisher(for: AnimateGalleryStore.didChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshVideos()
                self?.refreshImages()
            }
            .store(in: &galleryCancellables)
        galleryArtifactsProvider?.galleryArtifactsPublisher
            .sink { [weak self] artifacts in
                self?.remoteArtifacts = artifacts
                self?.refreshVideos()
                self?.refreshImages()
            }
            .store(in: &galleryCancellables)
        galleryArtifactsProvider?.galleryArtifactsErrorPublisher
            .sink { [weak self] message in
                self?.statusMessage = message
            }
            .store(in: &galleryCancellables)
    }

    func bind(accountStateProvider: any AnimateAccountStateProviding) {
        accountStateProvider.currentUserIdPublisher
            .sink { [weak self] ownerUserId in
                self?.currentOwnerUserId = ownerUserId
                if ownerUserId == nil {
                    self?.stopRemoteGalleryObservation()
                }
            }
            .store(in: &galleryCancellables)
    }

    func startRemoteGalleryObservation() {
        galleryArtifactsProvider?.observeGalleryArtifacts(ownerUserId: currentOwnerUserId)
    }

    func stopRemoteGalleryObservation() {
        galleryArtifactsProvider?.clearGalleryArtifacts()
        remoteArtifacts = []
        refreshVideos()
        refreshImages()
    }

    func refreshVideos() {
        let localRecords = galleryStore.loadRecords()
        var presentations: [AnimateGalleryVideoPresentation] = localRecords.map { record in
            let localFileExists = galleryStore.localFileExists(for: record)
            let remoteArtifact = remoteArtifacts.first {
                $0.id == record.artifactId || $0.workflowArtifactId == record.artifactId
            }
            return AnimateGalleryVideoPresentation(
                record: record,
                localFileURL: galleryStore.localFileURL(for: record),
                sourceImageURL: localURLIfAvailable(relativePath: record.sourceImageLocalRelativePath),
                generatedImageURL: localURLIfAvailable(relativePath: record.generatedImageLocalRelativePath)
                    ?? generatedImageURL(for: record, remoteArtifact: remoteArtifact),
                availability: localFileExists ? .savedOnDevice : availabilityForMissingLocalFile(remoteArtifact: remoteArtifact),
                remoteArtifact: remoteArtifact
            )
        }

        for artifact in remoteArtifacts where artifact.kind == "final_export" || artifact.kind == "final_video" {
            let artifactId = artifact.workflowArtifactId ?? artifact.id
            guard !dismissedRemoteVideoIds.contains(artifactId),
                  !dismissedRemoteVideoIds.contains(artifact.id)
            else { continue }
            let alreadyPresented = presentations.contains { presentation in
                presentation.record.artifactId == artifactId
                    || presentation.record.artifactId == artifact.id
            }
            guard !alreadyPresented else { continue }

            let record = AnimateGalleryVideoRecord(
                id: artifactId,
                videoId: artifactId,
                artifactId: artifactId,
                title: L10n.string("gallery.video.defaultTitle"),
                r2Key: artifact.r2Key,
                localRelativePath: "Videos/\(artifactId).mp4",
                createdAt: artifact.createdAt
            )
            presentations.append(
                AnimateGalleryVideoPresentation(
                    record: record,
                    localFileURL: nil,
                    sourceImageURL: nil,
                    generatedImageURL: nil,
                    availability: availabilityForRemoteOnlyArtifact(artifact),
                    remoteArtifact: artifact
                )
            )
        }

        videos = presentations.sorted { $0.record.createdAt > $1.record.createdAt }
    }

    func refreshImages() {
        var presentations = galleryStore.loadImageRecords().map { record in
            let remoteArtifact = remoteArtifacts.first {
                $0.id == record.artifactId || $0.workflowArtifactId == record.artifactId
            }
            let localFileURL = galleryStore.localFileExists(for: record)
                ? galleryStore.localFileURL(for: record)
                : nil
            return AnimateGalleryImagePresentation(
                record: record,
                remoteArtifact: remoteArtifact,
                localFileURL: localFileURL
            )
        }

        for artifact in remoteArtifacts where artifact.kind == "generated_image" {
            let artifactId = artifact.workflowArtifactId ?? artifact.id
            guard !dismissedRemoteImageIds.contains(artifactId) else { continue }
            let alreadyPresented = presentations.contains { presentation in
                presentation.record?.artifactId == artifactId
                    || presentation.remoteArtifact?.id == artifact.id
                    || presentation.remoteArtifact?.workflowArtifactId == artifactId
            }
            guard !alreadyPresented, !galleryStore.containsImage(artifactId: artifactId) else { continue }

            presentations.append(
                AnimateGalleryImagePresentation(
                    record: nil,
                    remoteArtifact: artifact,
                    localFileURL: nil
                )
            )
        }

        images = presentations
            .sorted { lhs, rhs in
                let lhsCreatedAt = lhs.record?.createdAt ?? lhs.remoteArtifact?.createdAt ?? 0
                let rhsCreatedAt = rhs.record?.createdAt ?? rhs.remoteArtifact?.createdAt ?? 0
                return lhsCreatedAt > rhsCreatedAt
            }
    }

    func deleteVideo(_ video: AnimateGalleryVideoPresentation) {
        dismissedRemoteVideoIds.insert(video.record.artifactId)
        if let remoteArtifact = video.remoteArtifact {
            dismissedRemoteVideoIds.insert(remoteArtifact.id)
            if let workflowArtifactId = remoteArtifact.workflowArtifactId {
                dismissedRemoteVideoIds.insert(workflowArtifactId)
            }
        }
        persistDismissedRemoteVideoIds()
        galleryStore.deleteRecord(video.record, deleteLocalFile: true)
        refreshVideos()
    }

    func deleteImage(_ image: AnimateGalleryImagePresentation) {
        if let record = image.record {
            galleryStore.deleteImageRecord(record, deleteLocalFile: true)
        } else {
            dismissedRemoteImageIds.insert(image.id)
        }
        downloadingImageIds.remove(image.id)
        refreshImages()
    }

    func renameVideo(_ video: AnimateGalleryVideoPresentation, title: String) {
        guard video.localFileURL != nil else { return }
        galleryStore.renameRecord(video.record, title: title)
        refreshVideos()
    }

    func prepareVideoInfo(_ video: AnimateGalleryVideoPresentation) {
        guard video.generatedImageURL == nil,
              let authTokenProvider
        else { return }

        Task { [weak self] in
            guard let bearerToken = try? await authTokenProvider.currentBearerToken() else { return }
            _ = await self?.downloadRelatedGeneratedImage(
                for: video,
                bearerToken: bearerToken
            )
            self?.refreshImages()
            self?.refreshVideos()
        }
    }

    func redownloadVideo(_ video: AnimateGalleryVideoPresentation) {
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
                    videoId: video.record.videoId,
                    artifactId: artifactId,
                    bearerToken: bearerToken
                )
                let temporaryFileURL = try await finalRenderClient.downloadFinalArtifact(from: download)
                let generatedImageLocalRelativePath = await self?.downloadRelatedGeneratedImage(
                    for: video,
                    bearerToken: bearerToken
                ) ?? video.record.generatedImageLocalRelativePath
                let record = try self?.galleryStore.saveDownloadedVideo(
                    temporaryFileURL: temporaryFileURL,
                    videoId: video.record.videoId,
                    artifactId: artifactId,
                    title: video.displayTitle,
                    r2Key: download.r2Key ?? remoteArtifact.r2Key,
                    sourceImageLocalRelativePath: video.record.sourceImageLocalRelativePath,
                    generatedImageLocalRelativePath: generatedImageLocalRelativePath,
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

    private func downloadRelatedGeneratedImage(
        for video: AnimateGalleryVideoPresentation,
        bearerToken: String
    ) async -> String? {
        guard let finalRenderClient,
              let generatedImage = relatedGeneratedImage(for: video.record, remoteArtifact: video.remoteArtifact)
        else { return nil }

        let artifactId = generatedImage.artifactId
        if let existingRecord = galleryStore.loadImageRecords().first(where: {
            $0.artifactId == artifactId
                || $0.artifactId == video.record.artifactId
                || $0.artifactId == video.remoteArtifact?.generatedImageArtifactId
        }),
           galleryStore.localFileExists(for: existingRecord) {
            return existingRecord.localRelativePath
        }

        do {
            let download = try await finalRenderClient.prepareImageArtifactDownload(
                artifactId: artifactId,
                bearerToken: bearerToken
            )
            let temporaryFileURL = try await finalRenderClient.downloadFinalArtifact(from: download)
            let record = try galleryStore.saveDownloadedImage(
                temporaryFileURL: temporaryFileURL,
                artifactId: download.artifactId,
                title: L10n.string("gallery.image.defaultTitle"),
                look: generatedImage.look,
                r2Key: download.r2Key ?? generatedImage.r2Key ?? artifactId,
                createdAt: Date(timeIntervalSince1970: generatedImage.createdAt / 1000)
            )
            galleryStore.addImageRecord(record)
            return record.localRelativePath
        } catch {
            return nil
        }
    }

    private func relatedGeneratedImage(
        for record: AnimateGalleryVideoRecord,
        remoteArtifact: AnimateArtifact?
    ) -> RelatedGeneratedImage? {
        if let remoteArtifact,
           let videoJobId = remoteArtifact.videoJobId {
            if let artifact = remoteArtifacts.first(where: {
                $0.kind == "generated_image" && $0.videoJobId == videoJobId
            }) {
                return RelatedGeneratedImage(
                    artifactId: artifact.workflowArtifactId ?? artifact.id,
                    look: artifact.look,
                    r2Key: artifact.r2Key,
                    createdAt: artifact.createdAt
                )
            }
        }

        let artifactId = record.artifactId

        return RelatedGeneratedImage(
            artifactId: artifactId,
            look: remoteArtifact?.look,
            r2Key: nil,
            createdAt: remoteArtifact?.createdAt ?? record.createdAt
        )
    }

    private func generatedImageURL(
        for record: AnimateGalleryVideoRecord,
        remoteArtifact: AnimateArtifact?
    ) -> URL? {
        guard let generatedImage = relatedGeneratedImage(for: record, remoteArtifact: remoteArtifact),
              let existingRecord = galleryStore.loadImageRecords().first(where: {
                  $0.artifactId == generatedImage.artifactId
                      || $0.artifactId == record.artifactId
                      || $0.artifactId == remoteArtifact?.generatedImageArtifactId
              }),
              galleryStore.localFileExists(for: existingRecord)
        else {
            return nil
        }

        return galleryStore.localFileURL(for: existingRecord)
    }

    private func localURLIfAvailable(relativePath: String?) -> URL? {
        guard let relativePath, galleryStore.localFileExists(relativePath: relativePath) else {
            return nil
        }
        return galleryStore.localFileURL(relativePath: relativePath)
    }

    private func persistDismissedRemoteVideoIds() {
        UserDefaults.standard.set(
            Array(dismissedRemoteVideoIds).sorted(),
            forKey: Self.dismissedRemoteVideoIdsDefaultsKey
        )
    }

    func downloadImage(_ image: AnimateGalleryImagePresentation) {
        downloadImage(image, reportStatus: true)
    }

    private func downloadImage(_ image: AnimateGalleryImagePresentation, reportStatus: Bool) {
        guard image.canDownload else { return }
        guard let authTokenProvider,
              let finalRenderClient
        else {
            if reportStatus {
                statusMessage = L10n.string("gallery.image.downloadUnavailable")
            }
            return
        }
        guard let remoteArtifact = image.remoteArtifact else {
            if reportStatus {
                statusMessage = L10n.string("gallery.image.downloadUnavailable")
            }
            return
        }

        let artifactId = remoteArtifact.workflowArtifactId ?? remoteArtifact.id
        guard !galleryStore.containsImage(artifactId: artifactId),
              !downloadingImageIds.contains(artifactId)
        else { return }

        downloadingImageIds.insert(artifactId)
        Task { [weak self] in
            do {
                guard let bearerToken = try await authTokenProvider.currentBearerToken() else {
                    if reportStatus {
                        self?.statusMessage = L10n.string("workflow.final.signInAgainSaveLocal")
                    }
                    self?.downloadingImageIds.remove(artifactId)
                    return
                }
                let download = try await finalRenderClient.prepareImageArtifactDownload(
                    artifactId: artifactId,
                    bearerToken: bearerToken
                )
                let temporaryFileURL = try await finalRenderClient.downloadFinalArtifact(from: download)
                let record = try self?.galleryStore.saveDownloadedImage(
                    temporaryFileURL: temporaryFileURL,
                    artifactId: artifactId,
                    title: L10n.string("gallery.image.defaultTitle"),
                    look: remoteArtifact.look ?? image.lookTitle,
                    r2Key: download.r2Key ?? remoteArtifact.r2Key,
                    createdAt: Date(timeIntervalSince1970: remoteArtifact.createdAt / 1000)
                )
                if let record {
                    self?.galleryStore.addImageRecord(record)
                }
                self?.downloadingImageIds.remove(artifactId)
                if reportStatus {
                    self?.statusMessage = L10n.string("gallery.image.downloaded")
                }
                self?.refreshImages()
            } catch {
                self?.downloadingImageIds.remove(artifactId)
                if reportStatus {
                    self?.statusMessage = L10n.string("gallery.image.downloadFailed")
                }
            }
        }
    }

    private func availabilityForMissingLocalFile(remoteArtifact: AnimateArtifact?) -> AnimateGalleryVideoAvailability {
        guard let remoteArtifact else { return .localFileMissing }
        return availabilityForRemoteOnlyArtifact(remoteArtifact)
    }

    private func availabilityForRemoteOnlyArtifact(_ artifact: AnimateArtifact) -> AnimateGalleryVideoAvailability {
        guard artifact.status == "available" else { return .downloadUnavailable }
        guard artifact.expiresAt > Date().timeIntervalSince1970 * 1000 else { return .downloadUnavailable }
        return .downloadAvailable
    }
}

private struct RelatedGeneratedImage {
    let artifactId: String
    let look: String?
    let r2Key: String?
    let createdAt: Double
}
