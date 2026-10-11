import XCTest
@testable import VeltrixSecurity

final class ScheduledCleanupManagerTests: XCTestCase {
    
    func testDefaultSettingsAreDisabled() {
        let manager = ScheduledCleanupManager.shared
        XCTAssertFalse(manager.settings.isEnabled)
    }
    
    func testDefaultFrequencyIsWeekly() {
        let manager = ScheduledCleanupManager.shared
        XCTAssertEqual(manager.settings.frequency, .weekly)
    }
    
    func testDefaultCleanupIncludesCaches() {
        let manager = ScheduledCleanupManager.shared
        XCTAssertTrue(manager.settings.cleanCaches)
    }
    
    func testDefaultCleanupExcludesLargeFiles() {
        let manager = ScheduledCleanupManager.shared
        XCTAssertFalse(manager.settings.cleanLargeFiles)
    }
    
    func testCanEnableScheduledCleanup() async {
        let manager = ScheduledCleanupManager.shared
        var settings = manager.settings
        settings.isEnabled = true
        settings.frequency = .daily
        settings.hour = 3
        settings.minute = 0
        
        // Guardar settings
        await manager.save(settings: settings)
        
        // Verificar que se guardaron
        XCTAssertTrue(manager.settings.isEnabled)
        XCTAssertEqual(manager.settings.frequency, .daily)
    }
    
    func testCleanupFrequenciesHaveDisplayNames() {
        let frequencies: [CleanupFrequency] = [.daily, .weekly, .monthly]
        for freq in frequencies {
            XCTAssertFalse(freq.displayName.isEmpty)
        }
    }
    
    func testWeekdaysHaveValidRange() {
        let weekdays = Weekday.allCases
        for day in weekdays {
            XCTAssertGreaterThanOrEqual(day.rawValue, 1)
            XCTAssertLessThanOrEqual(day.rawValue, 7)
        }
    }
}
