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
}
