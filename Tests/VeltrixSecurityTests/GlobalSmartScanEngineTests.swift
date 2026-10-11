import XCTest
@testable import VeltrixSecurity

final class GlobalSmartScanEngineTests: XCTestCase {
    
    func testEngineIsNotScanningInitially() {
        let engine = GlobalSmartScanEngine.shared
        XCTAssertFalse(engine.isScanning)
    }
    
    func testEngineIsNotCleaningInitially() {
        let engine = GlobalSmartScanEngine.shared
        XCTAssertFalse(engine.isCleaning)
    }
    
    func testReportIsInitiallyEmpty() {
        let engine = GlobalSmartScanEngine.shared
        XCTAssertTrue(engine.report.items.isEmpty)
    }
    
    func testGlobalScanCategoriesHaveSymbols() {
        let categories = GlobalScanCategory.allCases
        for category in categories {
            XCTAssertFalse(category.systemSymbol.isEmpty)
            XCTAssertFalse(category.rawValue.isEmpty)
        }
    }
    
    func testGlobalScanItemHasRequiredFields() {
        let item = GlobalScanItem(
            id: "test-item",
            url: URL(fileURLWithPath: "/tmp/test"),
            displayName: "Test Item",
            allocatedBytes: 1024,
            category: .caches,
            subcategory: .userAppCache,
            modifiedAt: Date(),
            reason: "Test reason",
            isSafeToDelete: true,
            aiVerdict: "This is safe"
        )
        
        XCTAssertEqual(item.id, "test-item")
        XCTAssertEqual(item.allocatedBytes, 1024)
        XCTAssertTrue(item.isSafeToDelete)
        XCTAssertFalse(item.aiVerdict.isEmpty)
    }
    
    func testGlobalScanReportCalculatesTotalBytes() {
        let items = [
            GlobalScanItem(
                id: "1",
                url: URL(fileURLWithPath: "/tmp/1"),
                displayName: "Item 1",
                allocatedBytes: 1000,
                category: .caches,
                subcategory: .userAppCache,
                reason: "Test",
                isSafeToDelete: true,
                aiVerdict: "Safe"
            ),
            GlobalScanItem(
                id: "2",
                url: URL(fileURLWithPath: "/tmp/2"),
                displayName: "Item 2",
                allocatedBytes: 2000,
                category: .caches,
                subcategory: .userAppCache,
                reason: "Test",
                isSafeToDelete: false,
                aiVerdict: "Keep"
            )
        ]
        
        let report = GlobalScanReport(items: items, isComplete: true)
        XCTAssertEqual(report.totalBytes, 3000)
        XCTAssertEqual(report.safeToDeleteBytes, 1000)
    }
    
    func testThreatRiskCanBeCompared() {
        XCTAssertLessThan(ThreatRisk.low, ThreatRisk.medium)
        XCTAssertLessThan(ThreatRisk.medium, ThreatRisk.high)
    }
}
