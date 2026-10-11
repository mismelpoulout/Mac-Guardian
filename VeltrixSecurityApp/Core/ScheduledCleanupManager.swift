import Foundation
import UserNotifications

// MARK: - Domain Types

enum CleanupFrequency: String, CaseIterable, Identifiable, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .daily: return "Diaria"
        case .weekly: return "Semanal"
        case .monthly: return "Mensual"
        }
    }

    var systemSymbol: String {
        switch self {
        case .daily: return "clock.arrow.circlepath"
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        }
    }
}

enum Weekday: Int, CaseIterable, Identifiable, Codable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    var displayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es")
        return formatter.weekdaySymbols[rawValue - 1].capitalized
    }
}

struct ScheduledCleanupSettings: Codable, Equatable {
    var isEnabled: Bool = false
    var frequency: CleanupFrequency = .weekly
    var hour: Int = 2          // Hour (0-23) for the cleanup
    var minute: Int = 0
    var weekday: Weekday = .sunday        // Used when frequency == .weekly
    var dayOfMonth: Int = 1               // Used when frequency == .monthly (1-28)
    var cleanCaches: Bool = true
    var cleanLargeFiles: Bool = false
    var scanThreats: Bool = true
}

// MARK: - Manager

/// Manages scheduled automatic cleanup using launchd plists written to ~/Library/LaunchAgents.
/// Also schedules UserNotification reminders as a fallback for sandbox environments.
@MainActor
@Observable
final class ScheduledCleanupManager {

    static let shared = ScheduledCleanupManager()

    private(set) var settings = ScheduledCleanupSettings()
    private(set) var isSaving = false
    private(set) var lastError: String?
    private(set) var lastScheduledDescription: String?

    // Legacy "macguardian" identifiers are kept so existing settings and installed LaunchAgents stay valid after the rename.
    private static let settingsKey = "com.cynaxia.macguardian.scheduledCleanup.settings"
    private static let launchAgentLabel = "com.cynaxia.macguardian.scheduledcleanup"
    private static var launchAgentPlistURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/\(launchAgentLabel).plist")
    }

    private init() {
        loadSettings()
    }

    // MARK: - Public API

    func save(settings newSettings: ScheduledCleanupSettings) async {
        guard !isSaving else { return }
        isSaving = true
        lastError = nil
        defer { isSaving = false }

        settings = newSettings
        persistSettings(newSettings)

        if newSettings.isEnabled {
            await requestNotificationPermission()
            let result = scheduleNotifications(for: newSettings)
            writeLaunchAgentPlist(for: newSettings)
            lastScheduledDescription = result
        } else {
            cancelNotifications()
            removeLaunchAgentPlist()
            lastScheduledDescription = nil
        }
    }

    func disable() async {
        var disabled = settings
        disabled.isEnabled = false
        await save(settings: disabled)
    }

    // MARK: - Persistence

    private func loadSettings() {
        guard let data = UserDefaults.standard.data(forKey: Self.settingsKey),
              let decoded = try? JSONDecoder().decode(ScheduledCleanupSettings.self, from: data)
        else { return }
        settings = decoded
    }

    private func persistSettings(_ s: ScheduledCleanupSettings) {
        guard let data = try? JSONEncoder().encode(s) else { return }
        UserDefaults.standard.set(data, forKey: Self.settingsKey)
    }

    // MARK: - UserNotifications

    private func requestNotificationPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    @discardableResult
    private func scheduleNotifications(for s: ScheduledCleanupSettings) -> String {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.launchAgentLabel])

        let content = UNMutableNotificationContent()
        content.title = "Veltrix Security — Limpieza Programada"
        content.body = "Es hora de la limpieza automática de tu Mac."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = s.hour
        dateComponents.minute = s.minute

        switch s.frequency {
        case .daily:
            break // hour + minute is enough
        case .weekly:
            dateComponents.weekday = s.weekday.rawValue
        case .monthly:
            dateComponents.day = s.dayOfMonth
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.launchAgentLabel,
            content: content,
            trigger: trigger
        )
        center.add(request)

        return buildDescription(settings: s)
    }

    private func cancelNotifications() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.launchAgentLabel])
    }

    // MARK: - launchd plist

    /// Writes a launchd plist to ~/Library/LaunchAgents/ so the cleanup runs even when the app is closed.
    /// Note: In a sandboxed app this write may be blocked — in that case, UserNotifications acts as fallback.
    private func writeLaunchAgentPlist(for s: ScheduledCleanupSettings) {
        // Build StartCalendarInterval dict
        var calInterval: [String: Int] = [
            "Hour": s.hour,
            "Minute": s.minute
        ]
        switch s.frequency {
        case .weekly:
            calInterval["Weekday"] = s.weekday.rawValue
        case .monthly:
            calInterval["Day"] = s.dayOfMonth
        case .daily:
            break
        }

        let appPath = Bundle.main.bundlePath
        let plist: [String: Any] = [
            "Label": Self.launchAgentLabel,
            "ProgramArguments": [appPath, "--scheduled-cleanup"],
            "StartCalendarInterval": calInterval,
            "RunAtLoad": false,
            "StandardOutPath": NSHomeDirectory() + "/Library/Logs/MacGuardian_cleanup.log",
            "StandardErrorPath": NSHomeDirectory() + "/Library/Logs/MacGuardian_cleanup_err.log"
        ]

        do {
            let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
            try data.write(to: Self.launchAgentPlistURL, options: .atomic)
            // Attempt to load/reload the agent (will fail in strict sandbox - ok)
            _ = try? Process.run(
                URL(fileURLWithPath: "/bin/launchctl"),
                arguments: ["load", "-w", Self.launchAgentPlistURL.path]
            )
        } catch {
            lastError = "No se pudo escribir el plist de launchd: \(error.localizedDescription). La notificación del sistema sigue activa."
        }
    }

    private func removeLaunchAgentPlist() {
        guard FileManager.default.fileExists(atPath: Self.launchAgentPlistURL.path) else { return }
        _ = try? Process.run(
            URL(fileURLWithPath: "/bin/launchctl"),
            arguments: ["unload", Self.launchAgentPlistURL.path]
        )
        try? FileManager.default.removeItem(at: Self.launchAgentPlistURL)
    }

    // MARK: - Helpers

    private func buildDescription(settings s: ScheduledCleanupSettings) -> String {
        let timeStr = String(format: "%02d:%02d", s.hour, s.minute)
        switch s.frequency {
        case .daily:
            return "Cada día a las \(timeStr)"
        case .weekly:
            return "Cada \(s.weekday.displayName) a las \(timeStr)"
        case .monthly:
            return "El día \(s.dayOfMonth) de cada mes a las \(timeStr)"
        }
    }
}
