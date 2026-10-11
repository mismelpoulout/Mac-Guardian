import Foundation
import AppKit

// MARK: - Privacy Permission Types

enum PrivacyPermissionCategory: String, CaseIterable, Identifiable, Sendable {
    case camera = "Cámara"
    case microphone = "Micrófono"
    case location = "Ubicación"
    case photos = "Fotos"
    case contacts = "Contactos"
    case calendars = "Calendario"
    case automation = "Automatización"
    case bluetooth = "Bluetooth"

    var id: String { rawValue }

    var systemSymbol: String {
        switch self {
        case .camera: return "camera.fill"
        case .microphone: return "mic.fill"
        case .location: return "location.fill"
        case .photos: return "photo.fill"
        case .contacts: return "person.crop.circle.fill"
        case .calendars: return "calendar"
        case .automation: return "applescript.fill"
        case .bluetooth: return "dot.radiowaves.left.and.right"
        }
    }

    var plistKeys: [String] {
        switch self {
        case .camera: return ["NSCameraUsageDescription"]
        case .microphone: return ["NSMicrophoneUsageDescription"]
        case .location: return ["NSLocationWhenInUseUsageDescription", "NSLocationAlwaysUsageDescription", "NSLocationUsageDescription"]
        case .photos: return ["NSPhotoLibraryUsageDescription"]
        case .contacts: return ["NSContactsUsageDescription"]
        case .calendars: return ["NSCalendarsUsageDescription", "NSRemindersUsageDescription"]
        case .automation: return ["NSAppleEventsUsageDescription"]
        case .bluetooth: return ["NSBluetoothAlwaysUsageDescription", "NSBluetoothPeripheralUsageDescription"]
        }
    }
}

struct AppPermissionUsage: Identifiable, Sendable {
    let id = UUID()
    let category: PrivacyPermissionCategory
    let usageDescription: String
}

struct AppPrivacyAuditItem: Identifiable, Sendable {
    let id: String
    let appName: String
    let appURL: URL
    let bundleIdentifier: String
    let permissions: [AppPermissionUsage]
}

enum TrackingType: String, Sendable {
    case cookies = "Cookies de Rastreo Web"
    case recentItems = "Lista de Archivos Recientes"
    case quarantineLog = "Registro de Descargas de Internet"

    var systemSymbol: String {
        switch self {
        case .cookies: return "globe.badge.chevron.backward"
        case .recentItems: return "clock.arrow.circlepath"
        case .quarantineLog: return "arrow.down.doc.fill"
        }
    }
}

struct PrivacyTrackingItem: Identifiable, Sendable {
    let id: String
    let displayName: String
    let url: URL
    let allocatedBytes: Int64
    let itemType: TrackingType
    let reason: String
}

struct PrivacyAuditReport: Sendable {
    var appsWithPermissions: [AppPrivacyAuditItem] = []
    var trackingItems: [PrivacyTrackingItem] = []
    var isComplete = false

    var totalTrackingBytes: Int64 {
        trackingItems.reduce(0) { $0 + $1.allocatedBytes }
    }
}

// MARK: - Privacy Scanner Engine

@MainActor
@Observable
final class PrivacyScanner {
    static let shared = PrivacyScanner()

    private(set) var report = PrivacyAuditReport()
    private(set) var isScanning = false
    private(set) var isCleaning = false

    init() {}

    func scan() async {
        guard !isScanning else { return }
        isScanning = true
        defer { isScanning = false }

        var auditedApps: [AppPrivacyAuditItem] = []
        var trackingFound: [PrivacyTrackingItem] = []

        // 1. Audit Application Permission Declarations in Info.plist
        let appRoots = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true)
        ]

        for root in appRoots {
            if let contents = try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                for appURL in contents where appURL.pathExtension.lowercased() == "app" {
                    let plistURL = appURL.appendingPathComponent("Contents/Info.plist")
                    guard let data = try? Data(contentsOf: plistURL),
                          let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
                        continue
                    }

                    var declaredPermissions: [AppPermissionUsage] = []

                    for cat in PrivacyPermissionCategory.allCases {
                        for key in cat.plistKeys {
                            if let desc = plist[key] as? String, !desc.isEmpty {
                                declaredPermissions.append(AppPermissionUsage(category: cat, usageDescription: desc))
                                break
                            }
                        }
                    }

                    if !declaredPermissions.isEmpty {
                        let name = (plist["CFBundleDisplayName"] as? String) ?? (plist["CFBundleName"] as? String) ?? appURL.deletingPathExtension().lastPathComponent
                        let bundleID = (plist["CFBundleIdentifier"] as? String) ?? ""

                        auditedApps.append(AppPrivacyAuditItem(
                            id: appURL.path,
                            appName: name,
                            appURL: appURL,
                            bundleIdentifier: bundleID,
                            permissions: declaredPermissions
                        ))
                    }
                }
            }
        }

        // 2. Audit Tracking Footprint & Cookies
        // Soporta: Safari, Chrome, Firefox, Brave, Edge, Arc
        let cookiePaths = [
            // Safari cookies (stored in Preferences)
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Safari", isDirectory: true),
            
            // Chrome
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Google/Chrome/Default/Cookies"),
            
            // Firefox
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Firefox/Profiles", isDirectory: true),
            
            // Brave
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/BraveSoftware/Brave-Browser/Default/Cookies"),
            
            // Microsoft Edge
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Microsoft Edge/Default/Cookies"),
            
            // Arc
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Arc/Default/Cookies"),
            
            // System-wide cookies
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Cookies", isDirectory: true)
        ]

        for path in cookiePaths {
            if FileManager.default.fileExists(atPath: path.path) {
                let size = (try? path.resourceValues(forKeys: [.fileAllocatedSizeKey]).fileAllocatedSize) ?? 4096
                trackingFound.append(PrivacyTrackingItem(
                    id: path.path,
                    displayName: path.lastPathComponent + " (\(path.deletingLastPathComponent().lastPathComponent))",
                    url: path,
                    allocatedBytes: Int64(size),
                    itemType: .cookies,
                    reason: "Base de datos de cookies de rastreo y sesiones de navegación."
                ))
            }
        }

        // 3. Recent Items
        let recentLists = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/com.apple.sharedfilelist", isDirectory: true)
        if FileManager.default.fileExists(atPath: recentLists.path) {
            if let files = try? FileManager.default.contentsOfDirectory(at: recentLists, includingPropertiesForKeys: [.fileAllocatedSizeKey], options: []) {
                for file in files {
                    let size = (try? file.resourceValues(forKeys: [.fileAllocatedSizeKey]).fileAllocatedSize) ?? 2048
                    trackingFound.append(PrivacyTrackingItem(
                        id: file.path,
                        displayName: "Historial de archivos y carpetas recientes de macOS",
                        url: file,
                        allocatedBytes: Int64(size),
                        itemType: .recentItems,
                        reason: "Registro de documentos y aplicaciones abiertas recientemente por el usuario."
                    ))
                    break // One consolidated entry
                }
            }
        }

        self.report = PrivacyAuditReport(
            appsWithPermissions: auditedApps.sorted { $0.permissions.count > $1.permissions.count },
            trackingItems: trackingFound,
            isComplete: true
        )
    }

    func cleanTrackingItems(itemIDs: Set<String>) async -> Int64 {
        isCleaning = true
        defer { isCleaning = false }

        var freed: Int64 = 0
        let targets = report.trackingItems.filter { itemIDs.contains($0.id) }

        for item in targets {
            do {
                if item.url.hasDirectoryPath {
                    let contents = try FileManager.default.contentsOfDirectory(at: item.url, includingPropertiesForKeys: nil)
                    for file in contents {
                        try? FileManager.default.removeItem(at: file)
                    }
                } else {
                    try FileManager.default.removeItem(at: item.url)
                }
                freed += item.allocatedBytes
            } catch {
                continue
            }
        }

        var updated = report.trackingItems
        updated.removeAll { itemIDs.contains($0.id) }
        self.report.trackingItems = updated
        return freed
    }
}
