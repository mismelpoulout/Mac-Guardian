import SwiftUI

enum NavigationItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case storage = "Storage"
    case cleanup = "Cleanup"
    case largeFiles = "Large Files"
    case applications = "Applications"
    case developerTools = "Developer Tools"
    case security = "Security"
    case privacy = "Privacy"
    case performance = "Performance"

    var id: String { rawValue }

    var title: LocalizedStringKey { LocalizedStringKey(rawValue) }

    var symbol: String {
        switch self {
        case .dashboard: "square.grid.2x2"
        case .storage: "internaldrive"
        case .cleanup: "sparkles"
        case .largeFiles: "doc.text.magnifyingglass"
        case .applications: "app.badge"
        case .developerTools: "hammer"
        case .security: "shield"
        case .privacy: "hand.raised"
        case .performance: "gauge.with.needle"
        }
    }
}
