import Foundation

protocol AnimateGalleryStoring {
    func loadRecords() -> [AnimateGalleryVideoRecord]
    func saveRecords(_ records: [AnimateGalleryVideoRecord])
    func loadImageRecords() -> [AnimateGalleryImageRecord]
    func saveImageRecords(_ records: [AnimateGalleryImageRecord])
    func localFileExists(for record: AnimateGalleryVideoRecord) -> Bool
    func localFileURL(for record: AnimateGalleryVideoRecord) -> URL
    func localFileExists(for record: AnimateGalleryImageRecord) -> Bool
    func localFileURL(for record: AnimateGalleryImageRecord) -> URL
    func contains(artifactId: String) -> Bool
    func containsImage(artifactId: String) -> Bool
    func saveDownloadedVideo(
        temporaryFileURL: URL,
        momentId: String,
        artifactId: String,
        title: String,
        r2Key: String,
        createdAt: Date
    ) throws -> AnimateGalleryVideoRecord
    func saveDownloadedImage(
        temporaryFileURL: URL,
        artifactId: String,
        title: String,
        look: String?,
        r2Key: String,
        createdAt: Date
    ) throws -> AnimateGalleryImageRecord
    func addRecord(_ record: AnimateGalleryVideoRecord)
    func addImageRecord(_ record: AnimateGalleryImageRecord)
    func renameRecord(_ record: AnimateGalleryVideoRecord, title: String)
    func deleteRecord(_ record: AnimateGalleryVideoRecord, deleteLocalFile: Bool)
    func deleteImageRecord(_ record: AnimateGalleryImageRecord, deleteLocalFile: Bool)
}

struct AnimateGalleryStore: AnimateGalleryStoring {
    static let didChangeNotification = Notification.Name("AnimateGalleryStoreDidChange")

    private let fileManager: FileManager
    private let baseDirectory: URL

    init(
        fileManager: FileManager = .default,
        baseDirectory: URL? = nil
    ) {
        self.fileManager = fileManager
        self.baseDirectory = baseDirectory ?? Self.defaultBaseDirectory(fileManager: fileManager)
    }

    func loadRecords() -> [AnimateGalleryVideoRecord] {
        guard let data = try? Data(contentsOf: recordsURL) else { return [] }
        return (try? JSONDecoder().decode([AnimateGalleryVideoRecord].self, from: data)) ?? []
    }

    func saveRecords(_ records: [AnimateGalleryVideoRecord]) {
        save(records, to: recordsURL)
    }

    func loadImageRecords() -> [AnimateGalleryImageRecord] {
        guard let data = try? Data(contentsOf: imageRecordsURL) else { return [] }
        return (try? JSONDecoder().decode([AnimateGalleryImageRecord].self, from: data)) ?? []
    }

    func saveImageRecords(_ records: [AnimateGalleryImageRecord]) {
        save(records, to: imageRecordsURL)
    }

    private func save<T: Encodable>(_ records: T, to url: URL) {
        do {
            try fileManager.createDirectory(
                at: baseDirectory,
                withIntermediateDirectories: true
            )
            let data = try JSONEncoder().encode(records)
            try data.write(to: recordsURL, options: .atomic)
            NotificationCenter.default.post(name: Self.didChangeNotification, object: nil)
        } catch {
            return
        }
    }

    func localFileExists(for record: AnimateGalleryVideoRecord) -> Bool {
        fileManager.fileExists(atPath: localFileURL(for: record).path)
    }

    func localFileURL(for record: AnimateGalleryVideoRecord) -> URL {
        baseDirectory.appendingPathComponent(record.localRelativePath)
    }

    func localFileExists(for record: AnimateGalleryImageRecord) -> Bool {
        fileManager.fileExists(atPath: localFileURL(for: record).path)
    }

    func localFileURL(for record: AnimateGalleryImageRecord) -> URL {
        baseDirectory.appendingPathComponent(record.localRelativePath)
    }

    func contains(artifactId: String) -> Bool {
        loadRecords().contains { $0.artifactId == artifactId }
    }

    func containsImage(artifactId: String) -> Bool {
        loadImageRecords().contains { $0.artifactId == artifactId }
    }

    func saveDownloadedVideo(
        temporaryFileURL: URL,
        momentId: String,
        artifactId: String,
        title: String,
        r2Key: String,
        createdAt: Date = Date()
    ) throws -> AnimateGalleryVideoRecord {
        try fileManager.createDirectory(
            at: videosDirectory,
            withIntermediateDirectories: true
        )
        let localRelativePath = "Videos/\(Self.safeFilename(momentId))-\(Self.safeFilename(artifactId)).mp4"
        let destinationURL = baseDirectory.appendingPathComponent(localRelativePath)
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.moveItem(at: temporaryFileURL, to: destinationURL)

        let record = AnimateGalleryVideoRecord(
            id: artifactId,
            momentId: momentId,
            artifactId: artifactId,
            title: title,
            r2Key: r2Key,
            localRelativePath: localRelativePath,
            createdAt: createdAt.timeIntervalSince1970 * 1000
        )
        return record
    }

    func saveDownloadedImage(
        temporaryFileURL: URL,
        artifactId: String,
        title: String,
        look: String?,
        r2Key: String,
        createdAt: Date = Date()
    ) throws -> AnimateGalleryImageRecord {
        try fileManager.createDirectory(
            at: imagesDirectory,
            withIntermediateDirectories: true
        )
        let localRelativePath = "Images/\(Self.safeFilename(artifactId)).jpg"
        let destinationURL = baseDirectory.appendingPathComponent(localRelativePath)
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.moveItem(at: temporaryFileURL, to: destinationURL)

        return AnimateGalleryImageRecord(
            id: artifactId,
            artifactId: artifactId,
            title: title,
            look: look,
            r2Key: r2Key,
            localRelativePath: localRelativePath,
            createdAt: createdAt.timeIntervalSince1970 * 1000
        )
    }

    func addRecord(_ record: AnimateGalleryVideoRecord) {
        let remainingRecords = loadRecords().filter { $0.artifactId != record.artifactId }
        saveRecords([record] + remainingRecords)
    }

    func addImageRecord(_ record: AnimateGalleryImageRecord) {
        let remainingRecords = loadImageRecords().filter { $0.artifactId != record.artifactId }
        saveImageRecords([record] + remainingRecords)
    }

    func renameRecord(_ record: AnimateGalleryVideoRecord, title: String) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        saveRecords(loadRecords().map { currentRecord in
            currentRecord.id == record.id ? currentRecord.renamed(trimmedTitle) : currentRecord
        })
    }

    func deleteRecord(_ record: AnimateGalleryVideoRecord, deleteLocalFile: Bool = true) {
        let remainingRecords = loadRecords().filter { $0.id != record.id }
        if deleteLocalFile {
            try? fileManager.removeItem(at: localFileURL(for: record))
        }
        saveRecords(remainingRecords)
    }

    func deleteImageRecord(_ record: AnimateGalleryImageRecord, deleteLocalFile: Bool = true) {
        let remainingRecords = loadImageRecords().filter { $0.id != record.id }
        if deleteLocalFile {
            try? fileManager.removeItem(at: localFileURL(for: record))
        }
        saveImageRecords(remainingRecords)
    }

    private var recordsURL: URL {
        baseDirectory.appendingPathComponent("gallery-records.json")
    }

    private var imageRecordsURL: URL {
        baseDirectory.appendingPathComponent("gallery-image-records.json")
    }

    private var videosDirectory: URL {
        baseDirectory.appendingPathComponent("Videos", isDirectory: true)
    }

    private var imagesDirectory: URL {
        baseDirectory.appendingPathComponent("Images", isDirectory: true)
    }

    private static func defaultBaseDirectory(fileManager: FileManager) -> URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AnimateAVGallery", isDirectory: true)
    }

    private static func safeFilename(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return value.unicodeScalars
            .map { allowed.contains($0) ? String($0) : "-" }
            .joined()
    }
}
