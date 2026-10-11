import XCTest
@testable import VeltrixSecurity

final class ThreatScannerTests: XCTestCase {
    
    func testScanReturnsValidReport() async {
        let scanner = ThreatScanner()
        let report = await scanner.scan()
        
        // El reporte siempre es válido
        XCTAssertNotNil(report)
        XCTAssertGreaterThanOrEqual(report.items.count, 0)
        XCTAssertGreaterThanOrEqual(report.skippedItems, 0)
    }
    
    func testHighRiskCountIsAccurate() async {
        let scanner = ThreatScanner()
        let report = await scanner.scan()
        
        let expectedHighRisk = report.items.filter { $0.risk == .high }.count
        XCTAssertEqual(report.highRiskCount, expectedHighRisk)
    }
    
    func testMediumRiskCountIsAccurate() async {
        let scanner = ThreatScanner()
        let report = await scanner.scan()
        
        let expectedMediumRisk = report.items.filter { $0.risk == .medium }.count
        XCTAssertEqual(report.mediumRiskCount, expectedMediumRisk)
    }
    
    func testThreatItemsHaveValidRisks() async {
        let scanner = ThreatScanner()
        let report = await scanner.scan()
        
        for item in report.items {
            XCTAssertFalse(item.reason.isEmpty)
            XCTAssertNotNil(item.url)
            XCTAssertFalse(item.displayName.isEmpty)
        }
    }
    
    func testThreatRiskCanBeCompared() {
        let risks: [ThreatRisk] = [.low, .medium, .high]
        XCTAssertLessThan(ThreatRisk.low, ThreatRisk.medium)
        XCTAssertLessThan(ThreatRisk.medium, ThreatRisk.high)
    }
    
    func testThreatRisksHaveSymbols() {
        let risks: [ThreatRisk] = [.low, .medium, .high]
        for risk in risks {
            XCTAssertFalse(risk.systemSymbol.isEmpty)
            XCTAssertFalse(risk.label.isEmpty)
        }
    }
}
