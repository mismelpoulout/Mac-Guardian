import Foundation
import SwiftUI
import AppKit

// MARK: - Global Scan Categories & Subcategories

enum GlobalScanCategory: String, CaseIterable, Identifiable, Sendable {
    case threats = "Amenazas y Seguridad"
    case downloadsAndUser = "Descargas y Archivos"
    case caches = "Cachés del Equipo y Apps"
    case tempAndHidden = "Temporales, Logs y Ocultos"

    var id: String { rawValue }

    var systemSymbol: String {
        switch self {
        case .threats: return "shield.lefthalf.filled"
        case .downloadsAndUser: return "arrow.down.circle.fill"
        case .caches: return "bolt.badge.sparkles"
        case .tempAndHidden: return "trash.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .threats: return .red
        case .downloadsAndUser: return .blue
        case .caches: return .orange
        case .tempAndHidden: return .purple
        }
    }

    var shortDescription: String {
        switch self {
        case .threats: return "Agentes de persistencia, scripts sospechosos y autorruns"
        case .downloadsAndUser: return "Instaladores DMG/PKG, archivos ZIP, duplicados y pesados"
        case .caches: return "Cachés de usuario, navegadores, Xcode y residuos del OS"
        case .tempAndHidden: return "Carpetas /tmp, Darwin tmp, logs de diagnóstico y archivos ocultos"
        }
    }
}

enum GlobalScanSubcategory: String, CaseIterable, Identifiable, Sendable {
    // Amenazas
    case launchAgent = "Agente de Inicio (LaunchAgent)"
    case launchDaemon = "Demonio del Sistema (LaunchDaemon)"
    case suspiciousScript = "Script Sospechoso"

    // Descargas y Usuario
    case appInstaller = "Instalador (.dmg, .pkg, .iso)"
    case zipArchive = "Archivo Comprimido (.zip, .rar, .7z)"
    case heavyFile = "Archivo Pesado (>100 MB)"
    case duplicateFile = "Archivo Duplicado"
    case oldScreenshot = "Captura de Pantalla Antigua"

    // Cachés
    case userAppCache = "Caché de Aplicación"
    case browserCache = "Caché de Navegador Web"
    case developerCache = "Caché de Desarrollo (Xcode, npm, pods)"
    case systemCache = "Caché del Sistema"
    case osUpdateResidual = "Instalador Residual de macOS"

    // Temporales y Ocultos
    case tempDirectoryFile = "Archivo Temporal (/tmp, Darwin)"
    case systemLog = "Registro del Sistema (.log)"
    case crashReport = "Reporte de Bloqueo (Crash Report)"
    case hiddenJunk = "Archivo Oculto (.DS_Store, .tmp)"
    case trashBin = "Papelera de Reciclaje"

    var id: String { rawValue }

    var systemSymbol: String {
        switch self {
        case .launchAgent, .launchDaemon: return "gearshape.arrow.triangle.2.circlepath"
        case .suspiciousScript: return "exclamationmark.shield.fill"
        case .appInstaller: return "arrow.down.app.fill"
        case .zipArchive: return "archivebox.fill"
        case .heavyFile: return "scalemass.fill"
        case .duplicateFile: return "doc.on.doc.fill"
        case .oldScreenshot: return "camera.metering.unknown"
        case .userAppCache: return "folder.badge.gearshape"
        case .browserCache: return "globe"
        case .developerCache: return "hammer.fill"
        case .systemCache: return "cpu"
        case .osUpdateResidual: return "apple.logo"
        case .tempDirectoryFile: return "clock.arrow.2.circlepath"
        case .systemLog: return "doc.text.fill"
        case .crashReport: return "exclamationmark.triangle.fill"
        case .hiddenJunk: return "eye.slash.fill"
        case .trashBin: return "trash.fill"
        }
    }
}

// MARK: - Global Scan Item

struct GlobalScanItem: Identifiable, Sendable {
    let id: String
    let url: URL
    let displayName: String
    let allocatedBytes: Int64
    let category: GlobalScanCategory
    let subcategory: GlobalScanSubcategory
    let modifiedAt: Date?
    let reason: String
    let isSafeToDelete: Bool
    let aiVerdict: String
    let threatRisk: ThreatRisk?

    init(
        id: String,
        url: URL,
        displayName: String,
        allocatedBytes: Int64,
        category: GlobalScanCategory,
        subcategory: GlobalScanSubcategory,
        modifiedAt: Date? = nil,
        reason: String,
        isSafeToDelete: Bool,
        aiVerdict: String,
        threatRisk: ThreatRisk? = nil
    ) {
        self.id = id
        self.url = url
        self.displayName = displayName
        self.allocatedBytes = allocatedBytes
        self.category = category
        self.subcategory = subcategory
        self.modifiedAt = modifiedAt
        self.reason = reason
        self.isSafeToDelete = isSafeToDelete
        self.aiVerdict = aiVerdict
        self.threatRisk = threatRisk
    }
}

// MARK: - Global Scan Report

struct GlobalScanReport: Sendable {
    var items: [GlobalScanItem] = []
    var isComplete = false
    var scanDurationSeconds: Double = 0

    var totalBytes: Int64 {
        items.reduce(0) { $0 + $1.allocatedBytes }
    }

    var safeToDeleteBytes: Int64 {
        items.filter { $0.isSafeToDelete }.reduce(0) { $0 + $1.allocatedBytes }
    }

    var threatCount: Int {
        items.filter { $0.category == .threats }.count
    }

    func items(for category: GlobalScanCategory) -> [GlobalScanItem] {
        items.filter { $0.category == category }
    }

    func bytes(for category: GlobalScanCategory) -> Int64 {
        items(for: category).reduce(0) { $0 + $1.allocatedBytes }
    }
}

// MARK: - Global Smart Scan Engine

@MainActor
@Observable
final class GlobalSmartScanEngine {
    static let shared = GlobalSmartScanEngine()

    private(set) var isScanning = false
    private(set) var isCleaning = false
    private(set) var currentTaskName: String = ""
    private(set) var filesExaminedCount: Int = 0
    private(set) var bytesAccumulated: Int64 = 0
    private(set) var report = GlobalScanReport()
    private(set) var cleanProgressText: String = ""

    private var scanTask: Task<Void, Never>?

    init() {}

    // MARK: - Start Global Scan

    func startScan() {
        guard !isScanning else { return }
        isScanning = true
        report = GlobalScanReport()
        filesExaminedCount = 0
        bytesAccumulated = 0
        currentTaskName = "Iniciando análisis global inteligente…"

        let startTime = Date()

        scanTask = Task { [weak self] in
            guard let self else { return }

            var collectedItems: [GlobalScanItem] = []

            // Phase 1: Threat Scan (Security & Persistence)
            self.currentTaskName = "1/4 Inspeccionando amenazas y persistencia…"
            let threatItems = await self.performThreatsScan()
            collectedItems.append(contentsOf: threatItems)
            self.bytesAccumulated = collectedItems.reduce(0) { $0 + $1.allocatedBytes }

            guard !Task.isCancelled else { self.finishCancelled(); return }

            // Phase 2: Caches of System, Apps, Browsers & Developer tools
            self.currentTaskName = "2/4 Analizando cachés de todo el equipo y programas…"
            let cacheItems = await self.performCachesScan()
            collectedItems.append(contentsOf: cacheItems)
            self.bytesAccumulated = collectedItems.reduce(0) { $0 + $1.allocatedBytes }

            guard !Task.isCancelled else { self.finishCancelled(); return }

            // Phase 3: Downloads, Installers, ZIPs, Duplicates & Heavy Files
            self.currentTaskName = "3/4 Examinando descargas, instaladores, duplicados y pesados…"
            let downloadItems = await self.performDownloadsAndUserScan()
            collectedItems.append(contentsOf: downloadItems)
            self.bytesAccumulated = collectedItems.reduce(0) { $0 + $1.allocatedBytes }

            guard !Task.isCancelled else { self.finishCancelled(); return }

            // Phase 4: Temp folders, Logs, Crash Reports & Hidden Junk
            self.currentTaskName = "4/4 Rastreando carpetas temporales (/tmp, Darwin) y archivos ocultos…"
            let tempItems = await self.performTempAndHiddenScan()
            collectedItems.append(contentsOf: tempItems)
            self.bytesAccumulated = collectedItems.reduce(0) { $0 + $1.allocatedBytes }

            // Completion
            var finalReport = GlobalScanReport()
            finalReport.items = collectedItems
            finalReport.isComplete = true
            finalReport.scanDurationSeconds = Date().timeIntervalSince(startTime)

            self.report = finalReport
            self.isScanning = false
            self.currentTaskName = ""
        }
    }

    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
        currentTaskName = ""
    }

    private func finishCancelled() {
        isScanning = false
        currentTaskName = ""
    }

    // MARK: - Phase 1: Threats & Persistence

    private func performThreatsScan() async -> [GlobalScanItem] {
        var items: [GlobalScanItem] = []

        // Core threat scanner
        let threatReport = await ThreatScanner().scan()
        for threat in threatReport.items {
            let allocated = (try? threat.url.resourceValues(forKeys: [.fileAllocatedSizeKey]).fileAllocatedSize) ?? 4096
            let modDate = (try? threat.url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)
            let subcategory: GlobalScanSubcategory = threat.url.path.contains("LaunchDaemons") ? .launchDaemon : .launchAgent

            items.append(GlobalScanItem(
                id: threat.id,
                url: threat.url,
                displayName: threat.displayName,
                allocatedBytes: Int64(allocated),
                category: .threats,
                subcategory: subcategory,
                modifiedAt: modDate,
                reason: threat.reason,
                isSafeToDelete: false, // Threats need deliberate user action
                aiVerdict: "Apple Intelligence: Agente de persistencia no firmado o con parámetros sospechosos.",
                threatRisk: threat.risk
            ))
            self.filesExaminedCount += 1
        }

        // Additional /tmp executable scripts check
        let tmpURLs = [
            URL(fileURLWithPath: "/private/tmp", isDirectory: true),
            URL(fileURLWithPath: "/private/var/tmp", isDirectory: true)
        ]

        let scriptExts: Set<String> = ["sh", "bash", "py", "pl", "rb", "command", "php", "zsh"]

        for tmpURL in tmpURLs {
            if let enumerator = FileManager.default.enumerator(at: tmpURL, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey], options: [.skipsSubdirectoryDescendants]) {
                while let fileURL = enumerator.nextObject() as? URL {
                    self.filesExaminedCount += 1
                    let ext = fileURL.pathExtension.lowercased()
                    if scriptExts.contains(ext) || fileURL.lastPathComponent.hasPrefix(".hidden") {
                        let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 1024
                        let modDate = (try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate)

                        items.append(GlobalScanItem(
                            id: fileURL.path,
                            url: fileURL,
                            displayName: fileURL.lastPathComponent,
                            allocatedBytes: Int64(size),
                            category: .threats,
                            subcategory: .suspiciousScript,
                            modifiedAt: modDate,
                            reason: "Script ejecutable detectado en carpeta temporal (\(tmpURL.lastPathComponent)).",
                            isSafeToDelete: false,
                            aiVerdict: "Apple Intelligence: Riesgo alto de ejecución de comandos remotos.",
                            threatRisk: .high
                        ))
                    }
                }
            }
        }

        return items
    }

    // MARK: - Phase 2: Caches (System, Apps, Browsers, Dev, OS Updaters)

    private func performCachesScan() async -> [GlobalScanItem] {
        var items: [GlobalScanItem] = []

        // 1. User Caches (~/Library/Caches)
        let userCacheRoot = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Caches", isDirectory: true)
        if let cacheReport = try? await FolderScanner().scan(rootURL: userCacheRoot, mode: .folderUsage, progress: { count in
            Task { @MainActor in self.filesExaminedCount += count }
        }) {
            for file in cacheReport.files {
                let name = file.url.lastPathComponent.lowercased()
                let subcategory: GlobalScanSubcategory
                let verdict: String

                if name.contains("chrome") || name.contains("safari") || name.contains("firefox") || name.contains("edge") || name.contains("brave") {
                    subcategory = .browserCache
                    verdict = "Apple Intelligence: Caché de navegación. 100% seguro de purgar."
                } else if name.contains("xcode") || name.contains("deriveddata") || name.contains("cocoapods") || name.contains("npm") || name.contains("gradle") {
                    subcategory = .developerCache
                    verdict = "Apple Intelligence: Caché de desarrollo. Se reconstruye al compilar."
                } else {
                    subcategory = .userAppCache
                    verdict = "Apple Intelligence: Caché de aplicación estándar."
                }

                items.append(GlobalScanItem(
                    id: file.id,
                    url: file.url,
                    displayName: file.url.lastPathComponent,
                    allocatedBytes: file.allocatedBytes,
                    category: .caches,
                    subcategory: subcategory,
                    modifiedAt: file.modifiedAt,
                    reason: "Caché de usuario acumulada por \(file.url.lastPathComponent).",
                    isSafeToDelete: true,
                    aiVerdict: verdict
                ))
            }
        }

        // 2. Extra Developer Caches
        let devRoots = [
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Developer/Xcode/DerivedData", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".npm/_cacache", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".gradle/caches", isDirectory: true)
        ]

        for devURL in devRoots {
            if FileManager.default.fileExists(atPath: devURL.path) {
                if let devReport = try? await FolderScanner().scan(rootURL: devURL, mode: .folderUsage, progress: { _ in }) {
                    if devReport.totalAllocatedBytes > 5_000_000 {
                        items.append(GlobalScanItem(
                            id: devURL.path,
                            url: devURL,
                            displayName: devURL.lastPathComponent + " (\(devURL.deletingLastPathComponent().lastPathComponent))",
                            allocatedBytes: devReport.totalAllocatedBytes,
                            category: .caches,
                            subcategory: .developerCache,
                            modifiedAt: nil,
                            reason: "Caché de compilación de desarrollo.",
                            isSafeToDelete: true,
                            aiVerdict: "Apple Intelligence: Totalmente seguro de purgar para recuperar espacio de compilador."
                        ))
                    }
                }
            }
        }

        // 3. OS Updater Artifacts
        let updaterReport = await OSUpdaterFinder().scan()
        for artifact in updaterReport.artifacts {
            items.append(GlobalScanItem(
                id: artifact.id,
                url: artifact.url,
                displayName: artifact.displayName,
                allocatedBytes: artifact.allocatedBytes,
                category: .caches,
                subcategory: .osUpdateResidual,
                modifiedAt: nil,
                reason: "Instalador o paquete de actualización de macOS residual.",
                isSafeToDelete: true,
                aiVerdict: "Apple Intelligence: Tu macOS actual ya no requiere este instalador."
            ))
            self.filesExaminedCount += 1
        }

        return items
    }

    // MARK: - Phase 3: Downloads, Installers, ZIPs, Duplicates & Heavy Files

    private func performDownloadsAndUserScan() async -> [GlobalScanItem] {
        var items: [GlobalScanItem] = []

        let scanDirs = [
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop", isDirectory: true)
        ]

        let installerExts: Set<String> = ["dmg", "pkg", "iso"]
        let archiveExts: Set<String> = ["zip", "rar", "7z", "tar", "gz", "tgz", "bz2"]

        var filesBySize: [Int64: [URL]] = [:]

        for dir in scanDirs {
            guard FileManager.default.fileExists(atPath: dir.path) else { continue }

            if let enumerator = FileManager.default.enumerator(
                at: dir,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey],
                options: [.skipsSubdirectoryDescendants]
            ) {
                while let fileURL = enumerator.nextObject() as? URL {
                    self.filesExaminedCount += 1
                    do {
                        let values = try fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey])
                        guard values.isRegularFile == true else { continue }

                        let size = Int64(values.fileSize ?? 0)
                        let modDate = values.contentModificationDate
                        let ext = fileURL.pathExtension.lowercased()
                        let filename = fileURL.lastPathComponent

                        // 1. App Installers
                        if installerExts.contains(ext) {
                            items.append(GlobalScanItem(
                                id: fileURL.path,
                                url: fileURL,
                                displayName: filename,
                                allocatedBytes: size,
                                category: .downloadsAndUser,
                                subcategory: .appInstaller,
                                modifiedAt: modDate,
                                reason: "Instalador de aplicación descargado. Si ya instalaste la app, no es necesario conservarlo.",
                                isSafeToDelete: true,
                                aiVerdict: "Apple Intelligence: Instalador prescindible tras la instalación."
                            ))
                        }
                        // 2. Archives (.zip, .rar, etc.)
                        else if archiveExts.contains(ext) {
                            items.append(GlobalScanItem(
                                id: fileURL.path,
                                url: fileURL,
                                displayName: filename,
                                allocatedBytes: size,
                                category: .downloadsAndUser,
                                subcategory: .zipArchive,
                                modifiedAt: modDate,
                                reason: "Archivo comprimido descargado en \(dir.lastPathComponent).",
                                isSafeToDelete: true,
                                aiVerdict: "Apple Intelligence: Archivo comprimido residual."
                            ))
                        }
                        // 3. Old Screenshots (> 14 days)
                        else if (filename.contains("Captura de pantalla") || filename.contains("Screen Shot")) && (modDate ?? Date()) < Date().addingTimeInterval(-14 * 86400) {
                            items.append(GlobalScanItem(
                                id: fileURL.path,
                                url: fileURL,
                                displayName: filename,
                                allocatedBytes: size,
                                category: .downloadsAndUser,
                                subcategory: .oldScreenshot,
                                modifiedAt: modDate,
                                reason: "Captura de pantalla antigua en el escritorio.",
                                isSafeToDelete: true,
                                aiVerdict: "Apple Intelligence: Captura de pantalla de más de 14 días."
                            ))
                        }
                        // 4. Heavy Files (> 100 MB)
                        else if size > 100 * 1024 * 1024 {
                            items.append(GlobalScanItem(
                                id: fileURL.path,
                                url: fileURL,
                                displayName: filename,
                                allocatedBytes: size,
                                category: .downloadsAndUser,
                                subcategory: .heavyFile,
                                modifiedAt: modDate,
                                reason: "Archivo de gran tamaño (\(size.formatted(.byteCount(style: .file)))).",
                                isSafeToDelete: false, // Needs user review
                                aiVerdict: "Apple Intelligence: Archivo pesado. Revisa si aún lo necesitas."
                            ))
                        }

                        // Duplicate candidate tracking (files > 1 MB)
                        if size > 1_000_000 {
                            filesBySize[size, default: []].append(fileURL)
                        }
                    } catch {
                        continue
                    }
                }
            }
        }

        // Detect duplicates
        for (size, urls) in filesBySize where urls.count > 1 {
            // Keep the first, flag other copies
            for dupURL in urls.dropFirst() {
                // If not already in items
                if !items.contains(where: { $0.id == dupURL.path }) {
                    items.append(GlobalScanItem(
                        id: dupURL.path,
                        url: dupURL,
                        displayName: dupURL.lastPathComponent,
                        allocatedBytes: size,
                        category: .downloadsAndUser,
                        subcategory: .duplicateFile,
                        modifiedAt: (try? dupURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate),
                        reason: "Archivo duplicado encontrado con tamaño idéntico a \(urls.first?.lastPathComponent ?? "otro archivo").",
                        isSafeToDelete: true,
                        aiVerdict: "Apple Intelligence: Copia redundante detectada con mismo tamaño."
                    ))
                }
            }
        }

        return items
    }

    // MARK: - Phase 4: Temp folders, Logs, Crash Reports & Hidden Junk

    private func performTempAndHiddenScan() async -> [GlobalScanItem] {
        var items: [GlobalScanItem] = []

        // 1. User and System Logs (~/Library/Logs)
        let userLogs = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs", isDirectory: true)
        if FileManager.default.fileExists(atPath: userLogs.path) {
            if let report = try? await FolderScanner().scan(rootURL: userLogs, mode: .folderUsage, progress: { _ in }) {
                for file in report.files {
                    self.filesExaminedCount += 1
                    items.append(GlobalScanItem(
                        id: file.id,
                        url: file.url,
                        displayName: file.url.lastPathComponent,
                        allocatedBytes: file.allocatedBytes,
                        category: .tempAndHidden,
                        subcategory: .systemLog,
                        modifiedAt: file.modifiedAt,
                        reason: "Registro de depuración / log de aplicación.",
                        isSafeToDelete: true,
                        aiVerdict: "Apple Intelligence: Registro de texto temporal. Seguro de borrar."
                    ))
                }
            }
        }

        // 2. Crash & Diagnostic Reports (~/Library/DiagnosticReports)
        let diagURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/DiagnosticReports", isDirectory: true)
        if FileManager.default.fileExists(atPath: diagURL.path) {
            if let diagContents = try? FileManager.default.contentsOfDirectory(at: diagURL, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey], options: []) {
                for fileURL in diagContents {
                    self.filesExaminedCount += 1
                    let size = Int64((try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 2048)
                    let mod = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                    items.append(GlobalScanItem(
                        id: fileURL.path,
                        url: fileURL,
                        displayName: fileURL.lastPathComponent,
                        allocatedBytes: size,
                        category: .tempAndHidden,
                        subcategory: .crashReport,
                        modifiedAt: mod,
                        reason: "Informe de error o cuelgue del sistema pasado.",
                        isSafeToDelete: true,
                        aiVerdict: "Apple Intelligence: Crash report antiguo sin utilidad para el usuario."
                    ))
                }
            }
        }

        // 3. User Trash Bin (~/.Trash)
        let trashURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash", isDirectory: true)
        if FileManager.default.fileExists(atPath: trashURL.path) {
            if let trashReport = try? await FolderScanner().scan(rootURL: trashURL, mode: .folderUsage, progress: { _ in }) {
                if trashReport.totalAllocatedBytes > 0 {
                    items.append(GlobalScanItem(
                        id: trashURL.path,
                        url: trashURL,
                        displayName: "Papelera del Usuario (\(trashReport.files.count) elementos)",
                        allocatedBytes: trashReport.totalAllocatedBytes,
                        category: .tempAndHidden,
                        subcategory: .trashBin,
                        modifiedAt: nil,
                        reason: "Archivos descartados que aún ocupan espacio en el disco.",
                        isSafeToDelete: true,
                        aiVerdict: "Apple Intelligence: Archivos que ya habías enviado a la papelera."
                    ))
                }
            }
        }

        // 4. Temporary Directory (Darwin / NSTemporaryDirectory)
        let darwinTempURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        if let tempContents = try? FileManager.default.contentsOfDirectory(at: darwinTempURL, includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey], options: []) {
            for fileURL in tempContents.prefix(60) {
                self.filesExaminedCount += 1
                let size = Int64((try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 4096)
                let mod = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
                items.append(GlobalScanItem(
                    id: fileURL.path,
                    url: fileURL,
                    displayName: fileURL.lastPathComponent,
                    allocatedBytes: size,
                    category: .tempAndHidden,
                    subcategory: .tempDirectoryFile,
                    modifiedAt: mod,
                    reason: "Archivo de proceso temporal en \(darwinTempURL.lastPathComponent).",
                    isSafeToDelete: true,
                    aiVerdict: "Apple Intelligence: Archivo de intercambio temporal."
                ))
            }
        }

        return items
    }

    // MARK: - Safe Cleaning Engine

    func cleanSelectedItems(itemIDs: Set<String>) async -> (freedBytes: Int64, deletedCount: Int, failedCount: Int) {
        guard !isCleaning else { return (0, 0, 0) }
        isCleaning = true
        defer { isCleaning = false }

        let targets = report.items.filter { itemIDs.contains($0.id) }
        var freed: Int64 = 0
        var deleted = 0
        var failed = 0

        for (index, item) in targets.enumerated() {
            self.cleanProgressText = "Eliminando \(index + 1) de \(targets.count): \(item.displayName)…"

            do {
                if item.subcategory == .trashBin {
                    // Empty trash contents
                    let trashURL = item.url
                    if let contents = try? FileManager.default.contentsOfDirectory(at: trashURL, includingPropertiesForKeys: nil) {
                        for sub in contents {
                            try? FileManager.default.removeItem(at: sub)
                        }
                    }
                    freed += item.allocatedBytes
                    deleted += 1
                } else if item.url.path.hasPrefix(NSTemporaryDirectory()) || item.url.path.hasPrefix("/private/tmp") {
                    try FileManager.default.removeItem(at: item.url)
                    freed += item.allocatedBytes
                    deleted += 1
                } else {
                    // Send to trash safely
                    try FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
                    freed += item.allocatedBytes
                    deleted += 1
                }
            } catch {
                failed += 1
            }
        }

        // Update current report by removing deleted items
        var updatedItems = report.items
        updatedItems.removeAll { itemIDs.contains($0.id) }
        self.report.items = updatedItems
        self.cleanProgressText = ""

        return (freed, deleted, failed)
    }
}
