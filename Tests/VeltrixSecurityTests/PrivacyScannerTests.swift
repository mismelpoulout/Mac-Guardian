import XCTest
@testable import VeltrixSecurity

final class PrivacyScannerTests: XCTestCase {
    
    func testScanReturnsValidReport() async {
        let scanner = PrivacyScanner()
        let report = await scanner.scan()
        
        XCTAssertNotNil(report)
        XCTAssertGreaterThanOrEqual(report.appsWithPermissions.count, 0)
        XCTAssertGreaterThanOrEqual(report.trackingItems.count, 0)
    }
    
    func testPermissionCategoriesHaveSymbols() {
        let categories = PrivacyPermissionCategory.allCases
        for category in categories {
            XCTAssertFalse(category.systemSymbol.isEmpty)
            XCTAssertFalse(category.displayName.isEmpty)
        }
    }
    
    func testTrackingTypesHaveLabelAndSymbol() {
        let trackingTypes = TrackingType.allCases
        for type in trackingTypes {
            XCTAssertFalse(type.displayName.isEmpty)
            XCTAssertFalse(type.systemSymbol.isEmpty)
        }
    }
    
    func testPrivacyAuditItemHasValidData() {
        let item = AppPrivacyAuditItem(
            id: "test.app",
            appName: "Test App",
            appURL: URL(fileURLWithPath: "/Applications/Test.app"),
            bundleIdentifier: "com.test.app",
            permissions: []
        )
        
        XCTAssertEqual(item.id, "test.app")
        XCTAssertEqual(item.appName, "Test App")
        XCTAssertFalse(item.bundleIdentifier.isEmpty)
    }
    
    func testPrivacyTrackingItemHasAllocatedBytes() {
        let item = PrivacyTrackingItem(
            id: "cookies",
            displayName: "Cookies",
            url: URL(fileURLWithPath: "/tmp/cookies"),
            allocatedBytes: 1024,
            itemType: .cookies,
            reason: "Web tracking cookies"
        )
        
        XCTAssertGreaterThan(item.allocatedBytes, 0)
        XCTAssertEqual(item.itemType, .cookies)
    }
    
    func testPrivacyAuditReportCalculatesTotalBytes() {
        let items = [
            PrivacyTrackingItem(
                id: "1",
                displayName: "Cookies",
                url: URL(fileURLWithPath: "/tmp/1"),
                allocatedBytes: 1000,
                itemType: .cookies,
                reason: "Test"
            ),
            PrivacyTrackingItem(
                id: "2",
                displayName: "Cache",
                url: URL(fileURLWithPath: "/tmp/2"),
                allocatedBytes: 2000,
                itemType: .recentItems,
                reason: "Test"
            )
        ]
        
        let report = PrivacyAuditReport(
            appsWithPermissions: [],
            trackingItems: items
        )
        
        XCTAssertEqual(report.totalTrackingBytes, 3000)
    }
}
