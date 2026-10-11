import Foundation

/// Risk level assigned to a detected persistence item.
enum ThreatRisk: Int, Comparable, Sendable {
    case low = 1
    case medium = 2
    case high = 3

    static func < (lhs: ThreatRisk, rhs: ThreatRisk) -> Bool { lhs.rawValue < rhs.rawValue }

    var label: String {
        switch self {
        case .low: return "Bajo"
        case .medium: return "Medio"
        case .high: return "Alto"
        }
    }

    var systemSymbol: String {
        switch self {
        case .low: return "checkmark.shield"
        case .medium: return "exclamationmark.triangle"
        case .high: return "xmark.shield.fill"
        }
    }
}

/// A suspicious item found during the threat scan.
struct ThreatItem: Identifiable, Sendable {
    let id: String
    let url: URL
    let displayName: String
    let risk: ThreatRisk
    let reason: String
}

struct ThreatScanReport: Sendable {
    let items: [ThreatItem]
    let skippedItems: Int
    var highRiskCount: Int { items.filter { $0.risk == .high }.count }
    var mediumRiskCount: Int { items.filter { $0.risk == .medium }.count }
    var isEmpty: Bool { items.isEmpty }
}

struct ThreatScanner: Sendable {

    // MARK: - Public

    func scan() async -> ThreatScanReport {
        await Task.detached(priority: .utility) {
            Self.performScan()
        }.value
    }

    // MARK: - Private

    private static func performScan() -> ThreatScanReport {
        var items: [ThreatItem] = []
        var skipped = 0

        let home = FileManager.default.homeDirectoryForCurrentUser
        let launchAgentRoots: [URL] = [
            home.appendingPathComponent("Library/LaunchAgents", isDirectory: true),
            URL(fileURLWithPath: "/Library/LaunchAgents", isDirectory: true),
            URL(fileURLWithPath: "/Library/LaunchDaemons", isDirectory: true)
        ]

        for root in launchAgentRoots {
            guard FileManager.default.fileExists(atPath: root.path) else { continue }
            guard let files = try? FileManager.default.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else { skipped += 1; continue }

            for file in files where file.pathExtension.caseInsensitiveCompare("plist") == .orderedSame {
                guard let data = try? Data(contentsOf: file),
                      let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
                else { skipped += 1; continue }

                let label = plist["Label"] as? String ?? file.deletingPathExtension().lastPathComponent
                let program = (plist["Program"] as? String)
                    ?? (plist["ProgramArguments"] as? [String])?.first
                    ?? ""

                if let threat = evaluateLaunchItem(label: label, program: program, location: file) {
                    items.append(threat)
                }
            }
        }

        // Check for suspicious scripts in known user-writable locations
        items += scanSuspiciousScripts(home: home, skipped: &skipped)

        return ThreatScanReport(
            items: items.sorted { $0.risk > $1.risk },
            skippedItems: skipped
        )
    }

    // MARK: - Evaluators

    /// Classifies a LaunchAgent/Daemon plist by its program path.
    private static func evaluateLaunchItem(label: String, program: String, location: URL) -> ThreatItem? {
        let prog = program.lowercased()

        // High risk: program pointing to /tmp, /var/tmp, or hidden directories
        let highRiskPatterns = ["/tmp/", "/var/tmp/", "/.hidden", "/private/tmp/"]
        for pattern in highRiskPatterns where prog.contains(pattern) {
            return ThreatItem(
                id: location.path,
                url: location,
                displayName: label,
                risk: .high,
                reason: "El programa apunta a una ruta temporal sospechosa: \(program)"
            )
        }

        // High risk: shell/python script with unusual extension in LaunchAgent
        let scriptExtensions = [".sh", ".py", ".rb", ".pl", ".bash"]
        for ext in scriptExtensions where prog.hasSuffix(ext) {
            return ThreatItem(
                id: location.path,
                url: location,
                displayName: label,
                risk: .high,
                reason: "LaunchAgent ejecuta un script (\(URL(fileURLWithPath: program).lastPathComponent)) en lugar de un binario firmado."
            )
        }

        // Medium risk: program does not exist on disk (broken/zombie launch item)
        if !program.isEmpty && program != "—" && !FileManager.default.fileExists(atPath: program) {
            return ThreatItem(
                id: location.path,
                url: location,
                displayName: label,
                risk: .medium,
                reason: "El binario referenciado no existe en disco: \(program). Puede ser un residuo de una app desinstalada."
            )
        }

        // Medium risk: program outside standard application directories
        let allowedPrefixes = [
            "/Applications/", "/System/", "/usr/", "/Library/Application Support/",
            FileManager.default.homeDirectoryForCurrentUser.path + "/Library/",
            FileManager.default.homeDirectoryForCurrentUser.path + "/Applications/"
        ]
        if !program.isEmpty && program != "—" {
            let isAllowed = allowedPrefixes.contains { program.hasPrefix($0) }
            if !isAllowed {
                return ThreatItem(
                    id: location.path,
                    url: location,
                    displayName: label,
                    risk: .medium,
                    reason: "El programa está fuera de las rutas estándar del sistema: \(program)"
                )
            }
        }

        return nil
    }

    /// Scans well-known locations for executable scripts that shouldn't normally be there.
    private static func scanSuspiciousScripts(home: URL, skipped: inout Int) -> [ThreatItem] {
        var results: [ThreatItem] = []
        let scanRoots: [URL] = [
            home.appendingPathComponent("Library/Application Support", isDirectory: true)
        ]
        let suspiciousExtensions = Set(["sh", "py", "rb", "pl", "bash"])
        let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .isExecutableKey]

        for root in scanRoots {
            guard FileManager.default.fileExists(atPath: root.path) else { continue }
            // Use a local counter to avoid capturing inout in the errorHandler closure
            var localSkipped = 0
            let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: Array(resourceKeys),
                options: [.skipsHiddenFiles],
                errorHandler: { _, _ in localSkipped += 1; return true }
            )
            guard let enumerator else { continue }

            for case let fileURL as URL in enumerator {
                guard let values = try? fileURL.resourceValues(forKeys: resourceKeys),
                      values.isRegularFile == true,
                      values.isExecutable == true,
                      suspiciousExtensions.contains(fileURL.pathExtension.lowercased())
                else { continue }

                results.append(ThreatItem(
                    id: fileURL.path,
                    url: fileURL,
                    displayName: fileURL.lastPathComponent,
                    risk: .medium,
                    reason: "Script ejecutable encontrado en Application Support: puede ser legítimo, pero conviene verificarlo."
                ))
            }
            skipped += localSkipped
        }
        return results
    }
}
