import XCTest
@testable import MacGuardian

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
    }
}
