import Foundation

protocol AnimateGalleryStoring {
    func loadRecords() -> [AnimateGalleryVideoRecord]
    func saveRecords(_ records: [AnimateGalleryVideoRecord])
    func localFileExists(for record: AnimateGalleryVideoRecord) -> Bool
    func localFileURL(for record: AnimateGalleryVideoRecord) -> URL
    func contains(artifactId: String) -> Bool
    func saveDownloadedVideo(
        temporaryFileURL: URL,
        momentId: String,
        artifactId: String,
        title: String,
        r2Key: String,
        createdAt: Date
    ) throws -> AnimateGalleryVideoRecord
    func addRecord(_ record: AnimateGalleryVideoRecord)
    func renameRecord(_ record: AnimateGalleryVideoRecord, title: String)
    func deleteRecord(_ record: AnimateGalleryVideoRecord, deleteLocalFile: Bool)
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

    func contains(artifactId: String) -> Bool {
        loadRecords().contains { $0.artifactId == artifactId }
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

    func addRecord(_ record: AnimateGalleryVideoRecord) {
        let remainingRecords = loadRecords().filter { $0.artifactId != record.artifactId }
        saveRecords([record] + remainingRecords)
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

    private var recordsURL: URL {
        baseDirectory.appendingPathComponent("gallery-records.json")
    }

    private var videosDirectory: URL {
        baseDirectory.appendingPathComponent("Videos", isDirectory: true)
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
