import XCTest
@testable import AnimateAV

final class AnimateMediaDeduplicatorTests: XCTestCase {
    func testSkipsMediaAlreadySelectedBySourceIdentifier() {
        let existing = [
            AnimateCreateTestFixtures.makeSelectedMedia(
                id: "00000000-0000-0000-0000-000000000001",
                sourceLocalIdentifier: "asset-1",
                sha256: "hash-1"
            )
        ]
        let imported = [
            AnimateCreateTestFixtures.makeSelectedMedia(
                id: "00000000-0000-0000-0000-000000000002",
                sourceLocalIdentifier: "asset-1",
                sha256: "hash-2"
            ),
            AnimateCreateTestFixtures.makeSelectedMedia(
                id: "00000000-0000-0000-0000-000000000003",
                sourceLocalIdentifier: "asset-3",
                sha256: "hash-3"
            )
        ]

        let unique = AnimateMediaDeduplicator.uniqueNewMedia(existing: existing, imported: imported)

        XCTAssertEqual(unique.map(\.sourceLocalIdentifier), ["asset-3"])
    }

    func testSkipsMediaAlreadySelectedByContentHash() {
        let existing = [
            AnimateCreateTestFixtures.makeSelectedMedia(
                id: "00000000-0000-0000-0000-000000000001",
                sourceLocalIdentifier: "asset-1",
                sha256: "hash-1"
            )
        ]
        let imported = [
            AnimateCreateTestFixtures.makeSelectedMedia(
                id: "00000000-0000-0000-0000-000000000002",
                sourceLocalIdentifier: "asset-2",
                sha256: "hash-1"
            ),
            AnimateCreateTestFixtures.makeSelectedMedia(
                id: "00000000-0000-0000-0000-000000000003",
                sourceLocalIdentifier: "asset-3",
                sha256: "hash-3"
            )
        ]

        let unique = AnimateMediaDeduplicator.uniqueNewMedia(existing: existing, imported: imported)

        XCTAssertEqual(unique.map(\.sourceLocalIdentifier), ["asset-3"])
    }

    func testSkipsDuplicatesWithinSameImportBatch() {
        let imported = [
            AnimateCreateTestFixtures.makeSelectedMedia(
                id: "00000000-0000-0000-0000-000000000001",
                sourceLocalIdentifier: "asset-1",
                sha256: "hash-1"
            ),
            AnimateCreateTestFixtures.makeSelectedMedia(
                id: "00000000-0000-0000-0000-000000000002",
                sourceLocalIdentifier: "asset-1",
                sha256: "hash-2"
            ),
            AnimateCreateTestFixtures.makeSelectedMedia(
                id: "00000000-0000-0000-0000-000000000003",
                sourceLocalIdentifier: "asset-3",
                sha256: "hash-1"
            )
        ]

        let unique = AnimateMediaDeduplicator.uniqueNewMedia(existing: [], imported: imported)

        XCTAssertEqual(unique.map(\.sourceLocalIdentifier), ["asset-1"])
    }
}
