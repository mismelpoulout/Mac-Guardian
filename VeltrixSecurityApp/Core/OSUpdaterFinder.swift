import Foundation

/// A single OS installer or update cache artifact found on disk.
struct OSUpdaterArtifact: Identifiable, Sendable {
    let id: String
    let url: URL
    let displayName: String
    let allocatedBytes: Int64
    let kind: ArtifactKind

    enum ArtifactKind: Sendable {
        case macOSInstaller   // e.g. "Install macOS Ventura.app"
        case softwareUpdateCache // /private/var SoftwareUpdate staging area
        case seedCatalog      // SoftwareUpdate catalogs / delta downloads
    }
}

struct OSUpdaterFinderReport: Sendable {
    let artifacts: [OSUpdaterArtifact]
    let totalAllocatedBytes: Int64
    var isEmpty: Bool { artifacts.isEmpty }
}

struct OSUpdaterFinder: Sendable {

    // MARK: - Public

    func scan() async -> OSUpdaterFinderReport {
        await Task.detached(priority: .utility) {
            Self.performScan()
        }.value
    }

    // MARK: - Private

    private static func performScan() -> OSUpdaterFinderReport {
        var artifacts: [OSUpdaterArtifact] = []

        // 1. macOS installer bundles left in /Applications or ~/Downloads
        artifacts += scanInstallerBundles()

        // 2. SoftwareUpdate staging areas under /private/var/folders
        artifacts += scanSoftwareUpdateCache()

        // 3. SeedCatalog / delta update leftovers under ~/Library/Caches
        artifacts += scanUserUpdateCaches()

        let total = artifacts.reduce(0) { $0 + $1.allocatedBytes }
        return OSUpdaterFinderReport(
            artifacts: artifacts.sorted { $0.allocatedBytes > $1.allocatedBytes },
            totalAllocatedBytes: total
        )
    }

    // MARK: - Scan helpers

    /// Looks for "Install macOS *.app" in /Applications and ~/Downloads.
    private static func scanInstallerBundles() -> [OSUpdaterArtifact] {
        var results: [OSUpdaterArtifact] = []
        let searchRoots: [URL] = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Downloads", isDirectory: true)
        ]
        for root in searchRoots {
            guard let contents = try? FileManager.default.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey, .fileAllocatedSizeKey],
                options: [.skipsHiddenFiles]
            ) else { continue }

            for url in contents {
                let name = url.lastPathComponent
                guard name.hasPrefix("Install macOS") && url.pathExtension == "app" else { continue }
                let bytes = allocatedSize(of: url)
                results.append(OSUpdaterArtifact(
                    id: url.standardizedFileURL.path,
                    url: url,
                    displayName: url.deletingPathExtension().lastPathComponent,
                    allocatedBytes: bytes,
                    kind: .macOSInstaller
                ))
            }
        }
        return results
    }

    /// Scans /private/var/folders for com.apple.SoftwareUpdate staging directories.
    private static func scanSoftwareUpdateCache() -> [OSUpdaterArtifact] {
        var results: [OSUpdaterArtifact] = []
        // SoftwareUpdate puts staged packages in temporary GUID folders
        let varFolders = URL(fileURLWithPath: "/private/var/folders", isDirectory: true)
        guard let tier1 = try? FileManager.default.contentsOfDirectory(
            at: varFolders,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return results }

        for t1 in tier1 {
            guard let tier2 = try? FileManager.default.contentsOfDirectory(
                at: t1,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { continue }
            for t2 in tier2 {
                let swuPath = t2.appendingPathComponent("com.apple.SoftwareUpdate", isDirectory: true)
                guard FileManager.default.fileExists(atPath: swuPath.path) else { continue }
                let bytes = allocatedSize(of: swuPath)
                guard bytes > 0 else { continue }
                results.append(OSUpdaterArtifact(
                    id: swuPath.standardizedFileURL.path,
                    url: swuPath,
                    displayName: "macOS Update Cache (SoftwareUpdate)",
                    allocatedBytes: bytes,
                    kind: .softwareUpdateCache
                ))
            }
        }
        return results
    }

    /// Scans ~/Library/Caches for Apple SoftwareUpdate / seed catalog leftovers.
    private static func scanUserUpdateCaches() -> [OSUpdaterArtifact] {
        var results: [OSUpdaterArtifact] = []
        let cachesRoot = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches", isDirectory: true)
        let targets = [
            "com.apple.SoftwareUpdate",
            "com.apple.MobileAsset"
        ]
        for name in targets {
            let url = cachesRoot.appendingPathComponent(name, isDirectory: true)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            let bytes = allocatedSize(of: url)
            guard bytes > 0 else { continue }
            results.append(OSUpdaterArtifact(
                id: url.standardizedFileURL.path,
                url: url,
                displayName: "Apple Update Cache (\(name))",
                allocatedBytes: bytes,
                kind: .seedCatalog
            ))
        }
        return results
    }

    // MARK: - Utilities

    /// Recursively computes allocated size of a directory or file.
    private static func allocatedSize(of url: URL) -> Int64 {
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .fileAllocatedSizeKey, .isSymbolicLinkKey]
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: [],
            errorHandler: nil
        ) else {
            if let v = try? url.resourceValues(forKeys: [.fileAllocatedSizeKey]),
               let s = v.fileAllocatedSize { return Int64(s) }
            return 0
        }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: keys),
                  values.isSymbolicLink != true,
                  values.isRegularFile == true else { continue }
            total += Int64(values.fileAllocatedSize ?? 0)
        }
        return total
    }
}


// MARK: - System Version Detection

extension OSUpdaterFinder {
    /// Obtiene la versión actual de macOS
    static func getCurrentMacOSVersion() -> String {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        return "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
    }

    /// Obtiene el nombre amigable de la versión de macOS
    static func getMacOSVersionName() -> String {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        switch osVersion.majorVersion {
        case 14: return "macOS Sonoma"
        case 13: return "macOS Ventura"
        case 12: return "macOS Monterey"
        case 11: return "macOS Big Sur"
        default: return "macOS \(osVersion.majorVersion)"
        }
    }
    
    /// URL para abrir configuración de actualización de macOS
    static var systemPreferencesURL: URL? {
        URL(string: "x-apple.systempreferences:com.apple.Software-Update-Settings.extension")
    }
}
