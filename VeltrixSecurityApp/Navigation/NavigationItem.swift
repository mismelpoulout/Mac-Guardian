import SwiftUI

enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case appleIntelligence = "Apple Intelligence"
    case storage = "Storage"
    case cleanup = "Cleanup"
    case largeFiles = "Large Files"
    case applications = "Applications"
    case developerTools = "Developer Tools"
    case security = "Security"
    case threatScan = "Threat Scan"
    case scheduledCleanup = "Scheduled Cleanup"
    case osUpdater = "OS Updater"
    case privacy = "Privacy"
    case performance = "Performance"

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .dashboard:        return "Dashboard"
        case .appleIntelligence: return "Apple Intelligence & Siri"
        case .storage:          return "Storage"
        case .cleanup:          return "Cleanup"
        case .largeFiles:       return "Large Files"
        case .applications:     return "Applications"
        case .developerTools:   return "Developer Tools"
        case .security:         return "Security"
        case .threatScan:       return "Amenazas"
        case .scheduledCleanup: return "Limpieza Programada"
        case .osUpdater:        return "Actualizaciones OS"
        case .privacy:          return "Privacy"
        case .performance:      return "Performance"
        }
    }

    var symbol: String {
        switch self {
        case .dashboard:        return "square.grid.2x2"
        case .appleIntelligence: return "sparkles"
        case .storage:          return "internaldrive"
        case .cleanup:          return "arrow.triangle.2.circlepath"
        case .largeFiles:       return "doc.text.magnifyingglass"
        case .applications:     return "app.badge"
        case .developerTools:   return "hammer"
        case .security:         return "shield"
        case .threatScan:       return "shield.lefthalf.filled"
        case .scheduledCleanup: return "clock.arrow.circlepath"
        case .osUpdater:        return "arrow.down.app.fill"
        case .privacy:          return "hand.raised"
        case .performance:      return "gauge.with.needle"
        }
    }
}
