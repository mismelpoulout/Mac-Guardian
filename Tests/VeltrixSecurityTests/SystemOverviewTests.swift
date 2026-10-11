import XCTest
@testable import VeltrixSecurity

final class SystemOverviewTests: XCTestCase {
    func testStorageUsageFractionUsesCapacityAndAvailableBytes() {
        let overview = SystemOverview(
            volumeName: "Test",
            capacityBytes: 1_000,
            availableBytes: 250,
            physicalMemoryBytes: 8_000,
            uptime: 1
        )

        XCTAssertEqual(overview.usedBytes, 750)
        XCTAssertEqual(overview.storageUsageFraction, 0.75)
    }

    func testStorageUsageIsUnavailableWhenCapacityIsUnknown() {
        let overview = SystemOverview(
            volumeName: "Test",
            capacityBytes: nil,
            availableBytes: 250,
            physicalMemoryBytes: 8_000,
            uptime: 1
        )

        XCTAssertNil(overview.usedBytes)
        XCTAssertNil(overview.storageUsageFraction)
    }

    func testStorageUsageIsClampedToValidRange() {
        let overview = SystemOverview(
            volumeName: "Test",
            capacityBytes: 1_000,
            availableBytes: 1_200,
            physicalMemoryBytes: 8_000,
            uptime: 1
        )

        XCTAssertEqual(overview.storageUsageFraction, 0)
    }

    func testFolderScannerGroupsFilesByTopLevelFolder() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacGuardianScan-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let firstFolder = root.appendingPathComponent("First", isDirectory: true)
        let secondFolder = root.appendingPathComponent("Second", isDirectory: true)
        try FileManager.default.createDirectory(at: firstFolder, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: secondFolder, withIntermediateDirectories: true)
        try Data(repeating: 1, count: 32_768).write(to: firstFolder.appendingPathComponent("large.bin"))
        try Data(repeating: 2, count: 32).write(to: secondFolder.appendingPathComponent("small.bin"))

        let report = try await FolderScanner().scan(rootURL: root, mode: .folderUsage) { _ in }

        XCTAssertEqual(report.filesScanned, 2)
        XCTAssertEqual(Set(report.files.map(\.id)), ["First", "Second"])
        XCTAssertGreaterThan(report.totalAllocatedBytes, 0)
    }

    func testFolderScannerAppliesLargeFileThreshold() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacGuardianLargeFileScan-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }

        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data(repeating: 1, count: 32_768).write(to: root.appendingPathComponent("large.bin"))
        try Data(repeating: 2, count: 32).write(to: root.appendingPathComponent("small.bin"))

        let report = try await FolderScanner().scan(rootURL: root, mode: .largeFiles(minimumBytes: 10_000)) { _ in }

        XCTAssertEqual(report.files.map(\.url.lastPathComponent), ["large.bin"])
        XCTAssertFalse(report.resultsTruncated)
    }

    func testFolderScannerReportsWhenLargeFileResultsAreLimited() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacGuardianLimitedScan-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)

        for index in 0..<301 {
            try Data([UInt8(index % 255)]).write(to: root.appendingPathComponent("file-\(index).bin"))
        }

        let report = try await FolderScanner().scan(rootURL: root, mode: .largeFiles(minimumBytes: 0)) { _ in }

        XCTAssertEqual(report.files.count, 300)
        XCTAssertTrue(report.resultsTruncated)
    }

    func testTrashPolicyAllowsOnlyDirectCacheChildren() {
        let cacheRoot = URL(fileURLWithPath: "/Users/test/Library/Caches", isDirectory: true)

        XCTAssertTrue(TrashService.isEligibleCacheItem(
            cacheRoot.appendingPathComponent("Example", isDirectory: true),
            cacheRoot: cacheRoot
        ))
        XCTAssertFalse(TrashService.isEligibleCacheItem(
            cacheRoot.appendingPathComponent("Example/nested", isDirectory: true),
            cacheRoot: cacheRoot
        ))
        XCTAssertFalse(TrashService.isEligibleCacheItem(cacheRoot, cacheRoot: cacheRoot))
        XCTAssertFalse(TrashService.isEligibleCacheItem(
            URL(fileURLWithPath: "/Users/test/Documents/important.txt"),
            cacheRoot: cacheRoot
        ))
    }

    func testTrashServiceRejectsSymbolicLinks() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacGuardianTrashPolicy-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let target = root.appendingPathComponent("target", isDirectory: true)
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
        let link = root.appendingPathComponent("cache-link", isDirectory: true)
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: target)

        XCTAssertThrowsError(try TrashService.moveCacheItemToTrash(link, cacheRoot: root)) { error in
            XCTAssertEqual(error as? TrashServiceError, .symbolicLinkNotSupported)
        }
        XCTAssertTrue(FileManager.default.fileExists(atPath: target.path))
    }

    func testUninstallPolicyRejectsSystemAndNestedApplications() {
        XCTAssertTrue(TrashService.canMoveAppToTrash(URL(fileURLWithPath: "/Applications/Example.app")))
        XCTAssertTrue(TrashService.canMoveAppToTrash(
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications/Example.app")
        ))
        XCTAssertFalse(TrashService.canMoveAppToTrash(URL(fileURLWithPath: "/System/Applications/Safari.app")))
        XCTAssertFalse(TrashService.canMoveAppToTrash(URL(fileURLWithPath: "/Applications/Utilities/Example.app")))
        XCTAssertFalse(TrashService.canMoveAppToTrash(URL(fileURLWithPath: "/Applications/Notes.txt")))
    }
}
