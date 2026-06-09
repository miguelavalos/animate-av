import Foundation
import OSLog
import PhotosUI
import SwiftUI

@MainActor
final class MediaUploadWorkflow: WorkspaceObservingWorkflow {
    @Published private(set) var selectedMedia: [AnimateSelectedMedia] = []
    @Published private(set) var isImporting = false
    @Published private(set) var importProgress: AnimateMediaImportProgress?
    @Published private(set) var statusMessage: String?

    private let currentUserProvider: any AnimateCurrentUserProviding
    private let authTokenProvider: any AnimateAuthTokenProviding
    private let uploadClient: AnimateUploadClient
    private let logger = Logger(subsystem: "com.avalsys.animateav", category: "media-upload")
    private var restoredWorkspaceMomentId: String?
    private var persistenceTimeoutTask: Task<Void, Never>?

    init(
        currentUserProvider: any AnimateCurrentUserProviding,
        authTokenProvider: any AnimateAuthTokenProviding,
        workspaceObserver: any AnimateActiveWorkspaceObserving,
        uploadClient: AnimateUploadClient
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
        template: AnimateVideoTemplate,
        momentId: String?
    ) async {
        guard !items.isEmpty else { return }
        let remainingSlots = AnimateMediaRules.remainingSlots(
            template: template,
            selectedCount: selectedMediaCount
        )
        guard remainingSlots > 0 else {
            statusMessage = L10n.string("workflow.media.templateFull")
            return
        }

        let generation = beginWorkflowGeneration()
        beginImport(totalCount: min(items.count, remainingSlots))
        AnimateMediaUploadDiagnostics.addBreadcrumb(
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
            let uniqueImported = AnimateMediaDeduplicator.uniqueNewMedia(
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
            AnimateMediaUploadDiagnostics.captureImportError(
                error,
                source: "picker",
                requestedCount: min(items.count, remainingSlots),
                remainingSlots: remainingSlots
            )
            statusMessage = AnimateRecoveryCopy.mediaImportFailure()
        }

        guard isCurrentWorkflowGeneration(generation) else { return }
        endImport()
    }

    func remove(_ media: AnimateSelectedMedia) {
        selectedMedia.removeAll { $0.id == media.id }
        normalizeOrder()
    }

    override func workspaceDidChange(_ workspace: AnimateWorkspace?) {
        guard selectedMedia.isEmpty,
              let workspace,
              restoredWorkspaceMomentId != workspace.video.id,
              !workspace.mediaAssets.isEmpty else { return }

        Task { [weak self] in
            await self?.restoreLocalMedia(from: workspace)
        }
    }

    func restoreLocalMediaForEditing() {
        guard selectedMedia.isEmpty,
              let activeWorkspace,
              restoredWorkspaceMomentId != activeWorkspace.video.id,
              !activeWorkspace.mediaAssets.isEmpty else { return }

        Task { [weak self, activeWorkspace] in
            await self?.restoreLocalMedia(from: activeWorkspace)
        }
    }

    func persistSelectedMedia(momentId: String) async -> [AnimateVideoDirectionMedia]? {
        await persistSelectedMedia(
            momentId: momentId,
            requiresProductStateSave: true,
            saveFailureMessage: AnimateRecoveryCopy.mediaStorySaveFailure()
        )
    }

    func persistSelectedMediaForFinalVideo(momentId: String) async -> Bool {
        let selectedCount = selectedMedia.filter(\.selected).count
        let persistedMedia = await persistSelectedMedia(
            momentId: momentId,
            requiresProductStateSave: false,
            saveFailureMessage: AnimateRecoveryCopy.mediaVideoSaveFailure()
        )
        return persistedMedia != nil || selectedCount == 0
    }

    private func persistSelectedMedia(
        momentId: String,
        requiresProductStateSave: Bool,
        saveFailureMessage: String
    ) async -> [AnimateVideoDirectionMedia]? {
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
            return activeWorkspaceVideoDirectionMedia
        }
        let syncedMediaBySourceIdentifier = (activeWorkspace?.mediaAssets ?? []).reduce(into: [String: AnimateMediaAsset]()) {
            guard let sourceIdentifier = $1.platformMediaAssetId else { return }
            $0[sourceIdentifier] = $1
        }
        let alreadySyncedMedia = mediaToSave.compactMap { media -> AnimateVideoDirectionMedia? in
            guard let synced = syncedMediaBySourceIdentifier[media.sourceLocalIdentifier] else { return nil }
            return AnimateVideoDirectionMedia(
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
        importProgress = AnimateMediaImportProgress(completedCount: 0, totalCount: pendingMediaToSave.count)
        statusMessage = L10n.string("workflow.media.uploading")
        startPersistenceTimeout(generation: generation, fallbackMessage: saveFailureMessage)
        AnimateMediaUploadDiagnostics.addBreadcrumb(
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
            cancelPersistenceTimeout()
            statusMessage = result.statusMessage
            isImporting = false
            importProgress = nil
            logger.info(
                "Persisted selected media saved=\(result.savedMedia.count, privacy: .public) total=\((alreadySyncedMedia.count + result.savedMedia.count), privacy: .public)"
            )
            return (alreadySyncedMedia + result.savedMedia).sorted { $0.sortOrder < $1.sortOrder }
        } catch AnimateUploadError.signedUploadUnavailable {
            guard isCurrentWorkflowGeneration(generation) else { return nil }
            cancelPersistenceTimeout()
            AnimateMediaUploadDiagnostics.capturePersistenceError(
                AnimateUploadError.signedUploadUnavailable,
                step: "signed_upload_unavailable",
                selectedCount: mediaToSave.count,
                pendingCount: pendingMediaToSave.count,
                alreadySyncedCount: alreadySyncedMedia.count,
                requiresProductStateSave: requiresProductStateSave
            )
            logger.error(
                "Media persistence failed error=signedUploadUnavailable selected=\(mediaToSave.count, privacy: .public) pending=\(pendingMediaToSave.count, privacy: .public)"
            )
            statusMessage = AnimateRecoveryCopy.mediaUploadUnavailable()
            isImporting = false
            importProgress = nil
            return nil
        } catch let error as AnimateAPIError {
            guard isCurrentWorkflowGeneration(generation) else { return nil }
            cancelPersistenceTimeout()
            AnimateMediaUploadDiagnostics.capturePersistenceError(
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
            statusMessage = mediaUploadMessage(for: error, fallback: saveFailureMessage)
            isImporting = false
            importProgress = nil
            return nil
        } catch {
            guard isCurrentWorkflowGeneration(generation) else { return nil }
            cancelPersistenceTimeout()
            AnimateMediaUploadDiagnostics.capturePersistenceError(
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

    private func mediaUploadMessage(for error: AnimateAPIError, fallback: String) -> String {
        if error.code == "unauthorized" || error.code == "moments_sign_in_required" || error.code == "moments_auth_token_missing" {
            return L10n.string("workflow.media.signInAgainPrepareStory")
        }
        if error.isLikelyConfigurationOrServerContractError {
            return L10n.string("workflow.media.error.contactSupport")
        }
        return fallback
    }

    func reset(force: Bool = false) {
        guard force || !isImporting else { return }
        cancelPersistenceTimeout()
        advanceWorkflowGeneration()
        isImporting = false
        importProgress = nil
        selectedMedia = []
        statusMessage = nil
        restoredWorkspaceMomentId = nil
        clearActiveWorkspace()
    }

    private func restoreLocalMedia(from workspace: AnimateWorkspace) async {
        let selectedAssetCount = workspace.mediaAssets.filter(\.selected).count
        let expectedSelectedCount = selectedAssetCount > 0 ? selectedAssetCount : workspace.mediaAssets.count
        AnimateMediaUploadDiagnostics.addBreadcrumb(
            operation: "restore",
            source: "local_media",
            assetCount: expectedSelectedCount
        )
        do {
            let restoredMedia = try await MediaPickerImport.loadLocalMediaAssets(workspace.mediaAssets)
            guard activeWorkspace?.video.id == workspace.video.id, selectedMedia.isEmpty else { return }
            if restoredMedia.count == expectedSelectedCount {
                restoredWorkspaceMomentId = workspace.video.id
                selectedMedia = restoredMedia
                statusMessage = L10n.string("workflow.media.localReady")
            } else if restoredMedia.isEmpty, expectedSelectedCount > 0 {
                statusMessage = L10n.string("workflow.media.savedReady")
            } else if expectedSelectedCount > 0 {
                statusMessage = L10n.string("workflow.media.savedReadyThumbnailsPending")
            }
        } catch AnimateUploadError.photoLibraryAccessDenied {
            guard activeWorkspace?.video.id == workspace.video.id else { return }
            statusMessage = L10n.string("workflow.media.savedReady")
        } catch {
            guard activeWorkspace?.video.id == workspace.video.id else { return }
            AnimateMediaUploadDiagnostics.captureRestoreError(error, expectedAssetCount: expectedSelectedCount)
            statusMessage = L10n.string("workflow.media.savedReady")
        }
    }

    private func beginImport(totalCount: Int) {
        cancelPersistenceTimeout()
        isImporting = true
        importProgress = AnimateMediaImportProgress(completedCount: 0, totalCount: max(totalCount, 0))
        statusMessage = nil
    }

    private func updateImportProgress(completedCount: Int, totalCount: Int) {
        importProgress = AnimateMediaImportProgress(
            completedCount: max(completedCount, 0),
            totalCount: max(totalCount, completedCount)
        )
    }

    private func endImport() {
        cancelPersistenceTimeout()
        isImporting = false
        importProgress = nil
    }

    private func startPersistenceTimeout(generation: Int, fallbackMessage: String) {
        cancelPersistenceTimeout()
        persistenceTimeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 60_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard let self,
                      self.isCurrentWorkflowGeneration(generation),
                      self.isImporting else { return }
                self.advanceWorkflowGeneration()
                self.isImporting = false
                self.importProgress = nil
                self.statusMessage = fallbackMessage
                self.logger.error("Media persistence timed out")
            }
        }
    }

    private func cancelPersistenceTimeout() {
        persistenceTimeoutTask?.cancel()
        persistenceTimeoutTask = nil
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

    private func sortByFilenameOrderOrSelection(left: AnimateSelectedMedia, right: AnimateSelectedMedia) -> Bool {
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
            let itemWord = importedCount == 1
                ? L10n.string("moment.noun.one")
                : L10n.string("moment.noun.other")
            return L10n.string("create.media.status.addedSkippingDuplicates", importedCount, itemWord, skippedDuplicateCount)
        }

        return L10n.string("create.media.status.ready")
    }

    private var selectedMediaCount: Int {
        AnimateMediaRules.selectedCount(
            localMedia: selectedMedia,
            syncedMedia: activeWorkspace?.mediaAssets ?? []
        )
    }

    private var activeWorkspaceVideoDirectionMedia: [AnimateVideoDirectionMedia] {
        let mediaAssets = activeWorkspace?.mediaAssets ?? []
        let selectedAssets = mediaAssets.filter(\.selected)
        return (selectedAssets.isEmpty ? mediaAssets : selectedAssets)
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
}

enum AnimateMediaDeduplicator {
    static func uniqueNewMedia(
        existing: [AnimateSelectedMedia],
        imported: [AnimateSelectedMedia]
    ) -> [AnimateSelectedMedia] {
        var seenSourceIdentifiers = Set(existing.map(\.sourceLocalIdentifier))
        var seenHashes = Set(existing.map(\.sha256))
        var unique: [AnimateSelectedMedia] = []

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

private extension AnimateSelectedMedia {
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
