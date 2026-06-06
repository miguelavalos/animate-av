import Foundation
import OSLog
import PhotosUI
import SwiftUI

@MainActor
final class MediaUploadWorkflow: WorkspaceObservingWorkflow {
    @Published private(set) var selectedMedia: [MomentsSelectedMedia] = []
    @Published private(set) var isImporting = false
    @Published private(set) var importProgress: MomentsMediaImportProgress?
    @Published private(set) var statusMessage: String?

    private let currentUserProvider: any MomentsCurrentUserProviding
    private let authTokenProvider: any MomentsAuthTokenProviding
    private let uploadClient: MomentsUploadClient
    private let logger = Logger(subsystem: "app.avalsys.animateav", category: "media-upload")
    private var restoredWorkspaceMomentId: String?

    init(
        currentUserProvider: any MomentsCurrentUserProviding,
        authTokenProvider: any MomentsAuthTokenProviding,
        workspaceObserver: any MomentsActiveWorkspaceObserving,
        uploadClient: MomentsUploadClient
    ) {
        self.currentUserProvider = currentUserProvider
        self.authTokenProvider = authTokenProvider
        self.uploadClient = uploadClient
        super.init(workspaceObserver: workspaceObserver)
    }

    var isConfigured: Bool {
        true
    }

    func importPickerItems(
        _ items: [PhotosPickerItem],
        template: MomentTemplate,
        momentId: String?
    ) async {
        guard !items.isEmpty else { return }
        let remainingSlots = MomentsMediaRules.remainingSlots(
            template: template,
            selectedCount: selectedMediaCount
        )
        guard remainingSlots > 0 else {
            statusMessage = L10n.string("workflow.media.templateFull")
            return
        }

        let generation = beginWorkflowGeneration()
        beginImport(totalCount: min(items.count, remainingSlots))
        MomentsMediaUploadDiagnostics.addBreadcrumb(
            operation: "import",
            source: "picker",
            assetCount: min(items.count, remainingSlots)
        )

        do {
            let imported = try await MediaPickerImport.load(
                items: items,
                limit: remainingSlots,
                startingSortOrder: selectedMedia.count,
                progress: { [weak self] completedCount, totalCount in
                    self?.updateImportProgress(completedCount: completedCount, totalCount: totalCount)
                }
            )

            guard isCurrentWorkflowGeneration(generation) else { return }
            let uniqueImported = MomentsMediaDeduplicator.uniqueNewMedia(
                existing: selectedMedia,
                imported: imported
            )
            selectedMedia.append(contentsOf: uniqueImported)
            sortChronologically()
            statusMessage = importStatusMessage(
                importedCount: uniqueImported.count,
                skippedDuplicateCount: imported.count - uniqueImported.count,
                emptyMessage: L10n.string("workflow.media.noNewMedia")
            )
        } catch {
            guard isCurrentWorkflowGeneration(generation) else { return }
            MomentsMediaUploadDiagnostics.captureImportError(
                error,
                source: "picker",
                requestedCount: min(items.count, remainingSlots),
                remainingSlots: remainingSlots
            )
            statusMessage = MomentsRecoveryCopy.mediaImportFailure()
        }

        guard isCurrentWorkflowGeneration(generation) else { return }
        endImport()
    }

    func importLatestPhotos(
        template: MomentTemplate,
        momentId: String?
    ) async {
        let remainingSlots = MomentsMediaRules.remainingSlots(
            template: template,
            selectedCount: selectedMediaCount
        )
        guard remainingSlots > 0 else {
            statusMessage = L10n.string("workflow.media.templateFull")
            return
        }

        let generation = beginWorkflowGeneration()
        beginImport(totalCount: remainingSlots)
        MomentsMediaUploadDiagnostics.addBreadcrumb(
            operation: "import",
            source: "latest_photos",
            assetCount: remainingSlots
        )

        do {
            let imported = try await MediaPickerImport.loadLatestPhotos(
                limit: remainingSlots,
                startingSortOrder: selectedMedia.count,
                progress: { [weak self] completedCount, totalCount in
                    self?.updateImportProgress(completedCount: completedCount, totalCount: totalCount)
                }
            )

            guard isCurrentWorkflowGeneration(generation) else { return }
            let uniqueImported = MomentsMediaDeduplicator.uniqueNewMedia(
                existing: selectedMedia,
                imported: imported
            )
            selectedMedia.append(contentsOf: uniqueImported)
            sortChronologically()
            statusMessage = importStatusMessage(
                importedCount: uniqueImported.count,
                skippedDuplicateCount: imported.count - uniqueImported.count,
                emptyMessage: L10n.string("workflow.media.noRecentPhotos")
            )
        } catch {
            guard isCurrentWorkflowGeneration(generation) else { return }
            MomentsMediaUploadDiagnostics.captureImportError(
                error,
                source: "latest_photos",
                requestedCount: remainingSlots,
                remainingSlots: remainingSlots
            )
            statusMessage = MomentsRecoveryCopy.mediaImportFailure()
        }

        guard isCurrentWorkflowGeneration(generation) else { return }
        endImport()
    }

    func importPhotoAlbum(
        id albumId: String,
        template: MomentTemplate,
        momentId: String?
    ) async {
        let remainingSlots = MomentsMediaRules.remainingSlots(
            template: template,
            selectedCount: selectedMediaCount
        )
        guard remainingSlots > 0 else {
            statusMessage = L10n.string("workflow.media.templateFull")
            return
        }

        let generation = beginWorkflowGeneration()
        beginImport(totalCount: remainingSlots)
        MomentsMediaUploadDiagnostics.addBreadcrumb(
            operation: "import",
            source: "album",
            assetCount: remainingSlots
        )

        do {
            let imported = try await MediaPickerImport.loadPhotoAlbum(
                id: albumId,
                limit: remainingSlots,
                startingSortOrder: selectedMedia.count,
                progress: { [weak self] completedCount, totalCount in
                    self?.updateImportProgress(completedCount: completedCount, totalCount: totalCount)
                }
            )

            guard isCurrentWorkflowGeneration(generation) else { return }
            let uniqueImported = MomentsMediaDeduplicator.uniqueNewMedia(
                existing: selectedMedia,
                imported: imported
            )
            selectedMedia.append(contentsOf: uniqueImported)
            sortChronologically()
            statusMessage = importStatusMessage(
                importedCount: uniqueImported.count,
                skippedDuplicateCount: imported.count - uniqueImported.count,
                emptyMessage: L10n.string("workflow.media.noAlbumPhotos")
            )
        } catch {
            guard isCurrentWorkflowGeneration(generation) else { return }
            MomentsMediaUploadDiagnostics.captureImportError(
                error,
                source: "album",
                requestedCount: remainingSlots,
                remainingSlots: remainingSlots
            )
            statusMessage = MomentsRecoveryCopy.mediaImportFailure()
        }

        guard isCurrentWorkflowGeneration(generation) else { return }
        endImport()
    }

    func remove(_ media: MomentsSelectedMedia) {
        selectedMedia.removeAll { $0.id == media.id }
        normalizeOrder()
    }

    func move(_ media: MomentsSelectedMedia, before target: MomentsSelectedMedia) {
        guard media.id != target.id,
              let sourceIndex = selectedMedia.firstIndex(where: { $0.id == media.id }),
              let targetIndex = selectedMedia.firstIndex(where: { $0.id == target.id }) else { return }

        let movedMedia = selectedMedia.remove(at: sourceIndex)
        let adjustedTargetIndex = sourceIndex < targetIndex ? targetIndex - 1 : targetIndex
        selectedMedia.insert(movedMedia, at: adjustedTargetIndex)
        normalizeOrder()
    }

    func reorder(_ media: [MomentsSelectedMedia]) {
        let mediaById = Dictionary(uniqueKeysWithValues: selectedMedia.map { ($0.id, $0) })
        selectedMedia = media.compactMap { mediaById[$0.id] }
        normalizeOrder()
    }

    func autoPickStrongMoments() {
        sortChronologically()
    }

    override func workspaceDidChange(_ workspace: MomentWorkspace?) {
        guard selectedMedia.isEmpty,
              let workspace,
              restoredWorkspaceMomentId != workspace.moment.id,
              !workspace.mediaAssets.isEmpty else { return }

        Task { [weak self] in
            await self?.restoreLocalMedia(from: workspace)
        }
    }

    func restoreLocalMediaForEditing() {
        guard selectedMedia.isEmpty,
              let activeWorkspace,
              restoredWorkspaceMomentId != activeWorkspace.moment.id,
              !activeWorkspace.mediaAssets.isEmpty else { return }

        Task { [weak self, activeWorkspace] in
            await self?.restoreLocalMedia(from: activeWorkspace)
        }
    }

    func persistSelectedMedia(momentId: String) async -> [MomentsStoryMedia]? {
        await persistSelectedMedia(
            momentId: momentId,
            requiresProductStateSave: true,
            saveFailureMessage: MomentsRecoveryCopy.mediaStorySaveFailure()
        )
    }

    func persistSelectedMediaForFinalVideo(momentId: String) async -> Bool {
        let selectedCount = selectedMedia.filter(\.selected).count
        let persistedMedia = await persistSelectedMedia(
            momentId: momentId,
            requiresProductStateSave: false,
            saveFailureMessage: MomentsRecoveryCopy.mediaVideoSaveFailure()
        )
        return persistedMedia != nil || selectedCount == 0
    }

    private func persistSelectedMedia(
        momentId: String,
        requiresProductStateSave: Bool,
        saveFailureMessage: String
    ) async -> [MomentsStoryMedia]? {
        guard let ownerUserId = currentUserProvider.currentUserId else {
            statusMessage = L10n.string("workflow.media.signInPrepareStory")
            return nil
        }
        guard let bearerToken = try? await authTokenProvider.currentBearerToken() else {
            statusMessage = L10n.string("workflow.media.signInAgainPrepareStory")
            return nil
        }
        let mediaToSave = selectedMedia
            .filter(\.selected)
            .sorted { $0.sortOrder < $1.sortOrder }
        if mediaToSave.isEmpty {
            return activeWorkspaceStoryMedia
        }
        let syncedMediaBySourceIdentifier = (activeWorkspace?.mediaAssets ?? []).reduce(into: [String: MomentMediaAsset]()) {
            guard let sourceIdentifier = $1.platformMediaAssetId else { return }
            $0[sourceIdentifier] = $1
        }
        let alreadySyncedMedia = mediaToSave.compactMap { media -> MomentsStoryMedia? in
            guard let synced = syncedMediaBySourceIdentifier[media.sourceLocalIdentifier] else { return nil }
            return MomentsStoryMedia(
                mediaAssetId: synced.id,
                mediaKind: synced.kind,
                sortOrder: media.sortOrder,
                selected: media.selected,
                moderationStatus: synced.moderationStatus
            )
        }
        let pendingMediaToSave = mediaToSave.filter {
            syncedMediaBySourceIdentifier[$0.sourceLocalIdentifier] == nil
        }
        if pendingMediaToSave.isEmpty {
            statusMessage = L10n.string("create.media.status.ready")
            return alreadySyncedMedia.sorted { $0.sortOrder < $1.sortOrder }
        }

        let generation = beginWorkflowGeneration()
        isImporting = true
        importProgress = MomentsMediaImportProgress(completedCount: 0, totalCount: pendingMediaToSave.count)
        statusMessage = L10n.string("workflow.media.uploading")
        MomentsMediaUploadDiagnostics.addBreadcrumb(
            operation: "persist",
            source: "selected_media",
            assetCount: pendingMediaToSave.count
        )
        logger.info(
            "Persisting selected media selected=\(mediaToSave.count, privacy: .public) alreadySynced=\(alreadySyncedMedia.count, privacy: .public) pending=\(pendingMediaToSave.count, privacy: .public)"
        )

        do {
            let result = try await MediaUploadPersistence.save(
                imported: pendingMediaToSave,
                ownerUserId: ownerUserId,
                bearerToken: bearerToken,
                momentId: momentId,
                uploadClient: uploadClient,
                requiresProductStateSave: requiresProductStateSave,
                progress: { [weak self] completedCount, totalCount in
                    self?.updateImportProgress(completedCount: completedCount, totalCount: totalCount)
                    self?.statusMessage = L10n.string(
                        "workflow.media.uploadingProgress",
                        completedCount,
                        totalCount
                    )
                },
                shouldContinue: { isCurrentWorkflowGeneration(generation) }
            )
            guard isCurrentWorkflowGeneration(generation) else { return nil }
            statusMessage = result.statusMessage
            isImporting = false
            importProgress = nil
            logger.info(
                "Persisted selected media saved=\(result.savedMedia.count, privacy: .public) total=\((alreadySyncedMedia.count + result.savedMedia.count), privacy: .public)"
            )
            return (alreadySyncedMedia + result.savedMedia).sorted { $0.sortOrder < $1.sortOrder }
        } catch MomentsUploadError.signedUploadUnavailable {
            guard isCurrentWorkflowGeneration(generation) else { return nil }
            MomentsMediaUploadDiagnostics.capturePersistenceError(
                MomentsUploadError.signedUploadUnavailable,
                step: "signed_upload_unavailable",
                selectedCount: mediaToSave.count,
                pendingCount: pendingMediaToSave.count,
                alreadySyncedCount: alreadySyncedMedia.count,
                requiresProductStateSave: requiresProductStateSave
            )
            logger.error(
                "Media persistence failed error=signedUploadUnavailable selected=\(mediaToSave.count, privacy: .public) pending=\(pendingMediaToSave.count, privacy: .public)"
            )
            statusMessage = MomentsRecoveryCopy.mediaUploadUnavailable()
            isImporting = false
            importProgress = nil
            return nil
        } catch let error as MomentsAPIError {
            guard isCurrentWorkflowGeneration(generation) else { return nil }
            MomentsMediaUploadDiagnostics.capturePersistenceError(
                error,
                step: "api",
                selectedCount: mediaToSave.count,
                pendingCount: pendingMediaToSave.count,
                alreadySyncedCount: alreadySyncedMedia.count,
                requiresProductStateSave: requiresProductStateSave
            )
            logger.error(
                "Media persistence failed apiCode=\(error.code, privacy: .public) selected=\(mediaToSave.count, privacy: .public) pending=\(pendingMediaToSave.count, privacy: .public)"
            )
            statusMessage = saveFailureMessage
            isImporting = false
            importProgress = nil
            return nil
        } catch {
            guard isCurrentWorkflowGeneration(generation) else { return nil }
            MomentsMediaUploadDiagnostics.capturePersistenceError(
                error,
                step: "unknown",
                selectedCount: mediaToSave.count,
                pendingCount: pendingMediaToSave.count,
                alreadySyncedCount: alreadySyncedMedia.count,
                requiresProductStateSave: requiresProductStateSave
            )
            logger.error(
                "Media persistence failed errorType=\(String(describing: type(of: error)), privacy: .public) description=\(error.localizedDescription, privacy: .public) selected=\(mediaToSave.count, privacy: .public) pending=\(pendingMediaToSave.count, privacy: .public)"
            )
            statusMessage = saveFailureMessage
            isImporting = false
            importProgress = nil
            return nil
        }
    }

    func reset(force: Bool = false) {
        guard force || !isImporting else { return }
        advanceWorkflowGeneration()
        isImporting = false
        importProgress = nil
        selectedMedia = []
        statusMessage = nil
        restoredWorkspaceMomentId = nil
        clearActiveWorkspace()
    }

    private func restoreLocalMedia(from workspace: MomentWorkspace) async {
        let selectedAssetCount = workspace.mediaAssets.filter(\.selected).count
        let expectedSelectedCount = selectedAssetCount > 0 ? selectedAssetCount : workspace.mediaAssets.count
        MomentsMediaUploadDiagnostics.addBreadcrumb(
            operation: "restore",
            source: "local_media",
            assetCount: expectedSelectedCount
        )
        do {
            let restoredMedia = try await MediaPickerImport.loadLocalMediaAssets(workspace.mediaAssets)
            guard activeWorkspace?.moment.id == workspace.moment.id, selectedMedia.isEmpty else { return }
            if restoredMedia.count == expectedSelectedCount {
                restoredWorkspaceMomentId = workspace.moment.id
                selectedMedia = restoredMedia
                statusMessage = L10n.string("workflow.media.localReady")
            } else if restoredMedia.isEmpty, expectedSelectedCount > 0 {
                statusMessage = L10n.string("workflow.media.savedReady")
            } else if expectedSelectedCount > 0 {
                statusMessage = L10n.string("workflow.media.savedReadyThumbnailsPending")
            }
        } catch MomentsUploadError.photoLibraryAccessDenied {
            guard activeWorkspace?.moment.id == workspace.moment.id else { return }
            statusMessage = L10n.string("workflow.media.savedReady")
        } catch {
            guard activeWorkspace?.moment.id == workspace.moment.id else { return }
            MomentsMediaUploadDiagnostics.captureRestoreError(error, expectedAssetCount: expectedSelectedCount)
            statusMessage = L10n.string("workflow.media.savedReady")
        }
    }

    private func beginImport(totalCount: Int) {
        isImporting = true
        importProgress = MomentsMediaImportProgress(completedCount: 0, totalCount: max(totalCount, 0))
        statusMessage = nil
    }

    private func updateImportProgress(completedCount: Int, totalCount: Int) {
        importProgress = MomentsMediaImportProgress(
            completedCount: max(completedCount, 0),
            totalCount: max(totalCount, completedCount)
        )
    }

    private func endImport() {
        isImporting = false
        importProgress = nil
    }

    private func normalizeOrder() {
        for index in selectedMedia.indices {
            selectedMedia[index].sortOrder = index
        }
    }

    private func sortChronologically() {
        if selectedMedia.contains(where: { $0.capturedAt != nil }) {
            selectedMedia = selectedMedia.sorted { left, right in
                switch (left.capturedAt, right.capturedAt) {
                case (.some(let leftDate), .some(let rightDate)):
                    if leftDate != rightDate {
                        return leftDate < rightDate
                    }
                    return left.sortOrder < right.sortOrder
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return sortByFilenameOrderOrSelection(left: left, right: right)
                }
            }
            normalizeOrder()
            return
        }

        if selectedMedia.allSatisfy({ $0.filenameOrderIndex != nil }) {
            selectedMedia = selectedMedia.sorted {
                sortByFilenameOrderOrSelection(left: $0, right: $1)
            }
            normalizeOrder()
            return
        }

        selectedMedia = selectedMedia.sorted { $0.sortOrder < $1.sortOrder }
        normalizeOrder()
    }

    private func sortByFilenameOrderOrSelection(left: MomentsSelectedMedia, right: MomentsSelectedMedia) -> Bool {
        guard let leftIndex = left.filenameOrderIndex,
              let rightIndex = right.filenameOrderIndex else {
            return left.sortOrder < right.sortOrder
        }

        if left.filenameOrderPrefix == right.filenameOrderPrefix, leftIndex != rightIndex {
            return leftIndex < rightIndex
        }

        return left.sortOrder < right.sortOrder
    }

    private func importStatusMessage(
        importedCount: Int,
        skippedDuplicateCount: Int,
        emptyMessage: String
    ) -> String {
        if importedCount == 0 {
            return skippedDuplicateCount > 0
                ? L10n.string("create.media.status.duplicatesOnly")
                : emptyMessage
        }

        if skippedDuplicateCount > 0 {
            let momentWord = importedCount == 1
                ? L10n.string("moment.noun.one")
                : L10n.string("moment.noun.other")
            return L10n.string("create.media.status.addedSkippingDuplicates", importedCount, momentWord, skippedDuplicateCount)
        }

        return L10n.string("create.media.status.ready")
    }

    private var selectedMediaCount: Int {
        MomentsMediaRules.selectedCount(
            localMedia: selectedMedia,
            syncedMedia: activeWorkspace?.mediaAssets ?? []
        )
    }

    private var activeWorkspaceStoryMedia: [MomentsStoryMedia] {
        let mediaAssets = activeWorkspace?.mediaAssets ?? []
        let selectedAssets = mediaAssets.filter(\.selected)
        return (selectedAssets.isEmpty ? mediaAssets : selectedAssets)
            .sorted { $0.sortOrder < $1.sortOrder }
            .map {
                MomentsStoryMedia(
                    mediaAssetId: $0.id,
                    mediaKind: $0.kind,
                    sortOrder: Int($0.sortOrder),
                    selected: $0.selected,
                    moderationStatus: $0.moderationStatus
                )
            }
    }
}

enum MomentsMediaDeduplicator {
    static func uniqueNewMedia(
        existing: [MomentsSelectedMedia],
        imported: [MomentsSelectedMedia]
    ) -> [MomentsSelectedMedia] {
        var seenSourceIdentifiers = Set(existing.map(\.sourceLocalIdentifier))
        var seenHashes = Set(existing.map(\.sha256))
        var unique: [MomentsSelectedMedia] = []

        for media in imported {
            let sourceIsDuplicate = seenSourceIdentifiers.contains(media.sourceLocalIdentifier)
            let hashIsDuplicate = seenHashes.contains(media.sha256)
            guard !sourceIsDuplicate && !hashIsDuplicate else { continue }

            seenSourceIdentifiers.insert(media.sourceLocalIdentifier)
            seenHashes.insert(media.sha256)
            unique.append(media)
        }

        return unique
    }
}

private extension MomentsSelectedMedia {
    var filenameOrderPrefix: String? {
        filenameOrderMatch?.prefix
    }

    var filenameOrderIndex: Int? {
        filenameOrderMatch?.index
    }

    private var filenameOrderMatch: (prefix: String, index: Int)? {
        let name = (originalFilename as NSString).deletingPathExtension
        guard let match = name.range(
            of: #"^(.+?)(\d+)$"#,
            options: .regularExpression
        ) else {
            return nil
        }

        let prefix = String(name[..<match.upperBound])
            .replacingOccurrences(
                of: #"\d+$"#,
                with: "",
                options: .regularExpression
            )
        let digits = String(name[match])
            .replacingOccurrences(
                of: #"^\D+"#,
                with: "",
                options: .regularExpression
            )

        guard !prefix.isEmpty, let index = Int(digits) else { return nil }
        return (prefix.lowercased(), index)
    }
}
