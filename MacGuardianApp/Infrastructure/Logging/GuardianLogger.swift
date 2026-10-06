import OSLog

enum GuardianLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.cynaxia.macguardian"

    static let scanner = Logger(subsystem: subsystem, category: "scanner")
    static let cleanup = Logger(subsystem: subsystem, category: "cleanup")
    static let security = Logger(subsystem: subsystem, category: "security")
    static let permissions = Logger(subsystem: subsystem, category: "permissions")
    static let storage = Logger(subsystem: subsystem, category: "storage")
    static let performance = Logger(subsystem: subsystem, category: "performance")
}
