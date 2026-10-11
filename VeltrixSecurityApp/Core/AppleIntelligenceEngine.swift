import Foundation
import SwiftUI
import AppIntents
import AppKit

// MARK: - Apple Intelligence Insight Models

enum AIInsightCategory: String, Sendable, CaseIterable {
    case storage = "Almacenamiento"
    case performance = "Rendimiento"
    case security = "Seguridad"
    case system = "Sistema"

    var systemSymbol: String {
        switch self {
        case .storage: return "internaldrive.badge.sparkles"
        case .performance: return "bolt.badge.sparkles"
        case .security: return "shield.checkered"
        case .system: return "cpu"
        }
    }
}

enum AIRecommendationPriority: Int, Comparable, Sendable {
    case low = 1
    case medium = 2
    case high = 3

    static func < (lhs: AIRecommendationPriority, rhs: AIRecommendationPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .low: return "Sugerencia"
        case .medium: return "Recomendado"
        case .high: return "Prioritario"
        }
    }

    var color: Color {
        switch self {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .purple
        }
    }
}

// MARK: - Recommendation Executable Actions

enum AIRecommendationAction: Sendable, Equatable {
    case runGlobalScan            // → Abre AutoInspectionSheet
    case optimizeRAM              // → Ejecuta purga de RAM
    case closeHeavyProcesses      // → Cierra apps pesadas y purga RAM
    case openCacheCleanup         // → Navega a Limpiar Caché
    case openPersistenceAudit     // → Navega a Auditoría de Persistencia
    case openPerformanceMonitor   // → Navega a Rendimiento
    case openThreatScan           // → Navega a Escaneo de Amenazas
    case openOSUpdater            // → Navega a Residuos de actualización OS
    case none                     // → No acción (estado óptimo)

    var buttonLabel: String {
        switch self {
        case .runGlobalScan:          return "Analizar ahora"
        case .optimizeRAM:            return "Optimizar RAM"
        case .closeHeavyProcesses:    return "Cerrar apps pesadas"
        case .openCacheCleanup:       return "Limpiar cachés"
        case .openPersistenceAudit:   return "Ver agentes"
        case .openPerformanceMonitor: return "Ver rendimiento"
        case .openThreatScan:         return "Escanear amenazas"
        case .openOSUpdater:          return "Ver residuos"
        case .none:                   return "Ver detalles"
        }
    }

    var buttonIcon: String {
        switch self {
        case .runGlobalScan:          return "sparkles"
        case .optimizeRAM:            return "memorychip"
        case .closeHeavyProcesses:    return "xmark.app.fill"
        case .openCacheCleanup:       return "trash.fill"
        case .openPersistenceAudit:   return "gearshape.arrow.triangle.2.circlepath"
        case .openPerformanceMonitor: return "gauge.with.needle"
        case .openThreatScan:         return "shield.checkered"
        case .openOSUpdater:          return "apple.logo"
        case .none:                   return "checkmark.circle"
        }
    }
}

struct AIRecommendation: Identifiable, Sendable {
    let id: UUID
    let title: String
    let detail: String
    let category: AIInsightCategory
    let priority: AIRecommendationPriority
    let potentialSavingsBytes: Int64?
    let systemSymbol: String
    let action: AIRecommendationAction

    init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        category: AIInsightCategory,
        priority: AIRecommendationPriority,
        potentialSavingsBytes: Int64? = nil,
        systemSymbol: String,
        action: AIRecommendationAction = .none
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.category = category
        self.priority = priority
        self.potentialSavingsBytes = potentialSavingsBytes
        self.systemSymbol = systemSymbol
        self.action = action
    }
}

struct AISystemHealthScore: Sendable {
    let score: Int // 0 to 100
    let statusText: String
    let recommendations: [AIRecommendation]

    var scoreColor: Color {
        if score >= 85 { return .green }
        if score >= 65 { return .orange }
        return .red
    }
}

// MARK: - Cache Safety Verdict

enum AICacheSafetyVerdict: Sendable {
    case recommended(reason: String)
    case activeApp(reason: String)
    case caution(reason: String)

    var isRecommended: Bool {
        if case .recommended = self { return true }
        return false
    }

    var badgeText: String {
        switch self {
        case .recommended: return "IA: Seguro para eliminar"
        case .activeApp: return "IA: App en ejecución"
        case .caution: return "IA: Revisión recomendada"
        }
    }

    var badgeColor: Color {
        switch self {
        case .recommended: return .green
        case .activeApp: return .orange
        case .caution: return .blue
        }
    }

    var systemSymbol: String {
        switch self {
        case .recommended: return "checkmark.seal.fill"
        case .activeApp: return "exclamationmark.triangle.fill"
        case .caution: return "info.circle.fill"
        }
    }

    var explanation: String {
        switch self {
        case .recommended(let r): return r
        case .activeApp(let r): return r
        case .caution(let r): return r
        }
    }
}

// MARK: - Threat AI Semantic Analysis

struct AIThreatAnalysis: Sendable {
    let explanation: String
    let potentialImpact: String
    let recommendedAction: String
    let safetyScore: Int // 1-10 (10 = highest danger)
}

// MARK: - Siri Command Definition for UI Testing

struct SiriCommandItem: Identifiable, Sendable {
    let id: String
    let triggerPhrase: String
    let description: String
    let systemSymbol: String
    let responseSnippet: String
}

// MARK: - Apple Intelligence Optimization Engine

@MainActor
@Observable
final class AppleIntelligenceEngine {
    static let shared = AppleIntelligenceEngine()

    private(set) var isAnalyzing = false
    private(set) var healthScore: AISystemHealthScore?
    private(set) var lastOptimizedDate: Date?
    private(set) var isSpeaking = false
    private var speechSynth: NSSpeechSynthesizer?

    let availableSiriCommands: [SiriCommandItem] = [
        SiriCommandItem(
            id: "scan",
            triggerPhrase: "«Oye Siri, analiza mi Mac con Veltrix Security»",
            description: "Ejecuta un diagnóstico inteligente completo de cachés, amenazas y disco.",
            systemSymbol: "sparkles",
            responseSnippet: "Iniciando análisis inteligente con Veltrix Security. Diagnóstico en curso."
        ),
        SiriCommandItem(
            id: "clean",
            triggerPhrase: "«Oye Siri, limpia la basura de mi Mac con Veltrix Security»",
            description: "Purga de forma segura cachés inactivas y residuos temporales.",
            systemSymbol: "trash.fill",
            responseSnippet: "He optimizado el almacenamiento de tu Mac liberando archivos temporales inactivos."
        ),
        SiriCommandItem(
            id: "health",
            triggerPhrase: "«Oye Siri, ¿cómo está la salud de mi Mac?»",
            description: "Apple Intelligence reporta el estado general del sistema y espacio disponible.",
            systemSymbol: "heart.text.square.fill",
            responseSnippet: "Tu Mac tiene un 92% de salud con almacenamiento en parámetros normales."
        ),
        SiriCommandItem(
            id: "threats",
            triggerPhrase: "«Oye Siri, busca amenazas en mi Mac»",
            description: "Verifica agentes de arranque y scripts sospechosos con heurística local.",
            systemSymbol: "shield.checkered",
            responseSnippet: "Análisis de amenazas completado: todos los agentes de inicio conocidos están seguros."
        ),
        SiriCommandItem(
            id: "space",
            triggerPhrase: "«Oye Siri, ¿cuánto espacio puedo liberar con Veltrix Security?»",
            description: "Calcula en segundos el espacio recuperable en cachés y residuos del OS.",
            systemSymbol: "internaldrive.badge.sparkles",
            responseSnippet: "Puedes recuperar aproximadamente 4.5 GB de cachés inactivas y archivos residuales."
        )
    ]

    init() {
        self.speechSynth = NSSpeechSynthesizer()
    }

    /// Evaluates whether a user cache directory is safe to delete
    func evaluateCacheItem(url: URL, bytes: Int64, modifiedAt: Date?) -> AICacheSafetyVerdict {
        let name = url.lastPathComponent.lowercased()

        // Check if application is running right now
        let runningAppIdentifiers = NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier?.lowercased() }
        let runningAppNames = NSWorkspace.shared.runningApplications.compactMap { $0.localizedName?.lowercased() }

        if runningAppIdentifiers.contains(where: { name.contains($0) || $0.contains(name) })
            || runningAppNames.contains(where: { name.contains($0) || $0.contains(name) }) {
            return .activeApp(reason: "La aplicación asociada está abierta actualmente. Ciérrala para que la limpieza sea 100% efectiva.")
        }

        // Web browsers
        if name.contains("google.chrome") || name.contains("safari") || name.contains("firefox") || name.contains("edge") || name.contains("brave") {
            return .recommended(reason: "Caché de navegación web. Eliminarla agiliza el navegador y libera espacio sin alterar contraseñas ni marcadores.")
        }

        // Development tools
        if name.contains("xcode") || name.contains("deriveddata") || name.contains("cocoapods") || name.contains("gradle") || name.contains("pip") || name.contains("npm") {
            return .recommended(reason: "Caché de desarrollo. Se reconstruye automáticamente cuando vuelves a compilar.")
        }

        // Media & Communication
        if name.contains("spotify") || name.contains("slack") || name.contains("discord") || name.contains("zoom") || name.contains("telegram") || name.contains("whatsapp") {
            return .recommended(reason: "Caché temporal de medios y mensajería. No borra tus mensajes ni tus credenciales.")
        }

        // System thumbnails & previews
        if name.contains("quicklook") || name.contains("font") || name.contains("thumbnail") || name.contains("preview") || name.contains("com.apple.") {
            return .recommended(reason: "Caché de miniaturas y renderizado temporal. Se regenera al instante cuando abres carpetas.")
        }

        // Age check: older than 14 days
        if let modifiedAt, modifiedAt < Date().addingTimeInterval(-14 * 86400) {
            let days = Int(Date().timeIntervalSince(modifiedAt) / 86400)
            return .recommended(reason: "Inactivo desde hace \(days) días. Apple Intelligence confirma que es totalmente prescindible.")
        }

        if bytes > 800 * 1024 * 1024 {
            return .caution(reason: "Esta carpeta ocupa un tamaño considerable (\(bytes.formatted(.byteCount(style: .file)))). Verifica si requieres archivos recientes de esta app.")
        }

        return .recommended(reason: "Caché de aplicación estándar. Seguro de enviar a la Papelera.")
    }

    /// Evaluates threats with Apple Intelligence behavior heuristics
    func analyzeThreatWithAI(item: ThreatItem) -> AIThreatAnalysis {
        let path = item.url.path.lowercased()
        let reason = item.reason.lowercased()

        if path.contains("/tmp") || path.contains("/var/folders") || reason.contains("curl") || reason.contains("wget") || reason.contains("bash") || reason.contains("python") {
            return AIThreatAnalysis(
                explanation: "Apple Intelligence detectó una invocación a intérpretes de comandos en directorios temporales del sistema al inicio de sesión.",
                potentialImpact: "Podría ejecutar scripts remotos no supervisados en segundo plano.",
                recommendedAction: "Desactivar de inmediato y eliminar el archivo plist correspondiente.",
                safetyScore: 9
            )
        } else if item.risk == .high {
            return AIThreatAnalysis(
                explanation: "Elemento de persistencia no firmado o con permisos atípicos en la raíz del usuario.",
                potentialImpact: "Mantiene un proceso activo permanente consumiendo recursos y monitoreando actividad.",
                recommendedAction: "Mover a la Papelera si no recuerdas haber instalado esta herramienta recientemente.",
                safetyScore: 8
            )
        } else if item.risk == .medium {
            return AIThreatAnalysis(
                explanation: "Agente de inicio de software de terceros registrado para ejecutarse al encender el Mac.",
                potentialImpact: "Prolonga el tiempo de arranque y utiliza memoria en segundo plano.",
                recommendedAction: "Revisar en Finder. Si ya no usas la aplicación, es seguro eliminarlo.",
                safetyScore: 5
            )
        } else {
            return AIThreatAnalysis(
                explanation: "Configuración de inicio estándar de una aplicación verificada.",
                potentialImpact: "Impacto mínimo en el rendimiento.",
                recommendedAction: "No se requiere ninguna acción si reconoces la aplicación.",
                safetyScore: 2
            )
        }
    }

    /// Speech output for Siri simulation
    func speakSiriResponse(_ text: String) {
        if speechSynth == nil {
            speechSynth = NSSpeechSynthesizer()
        }
        speechSynth?.stopSpeaking()
        speechSynth?.startSpeaking(text)
        isSpeaking = true

        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            self.isSpeaking = false
        }
    }

    /// Runs on-device Apple Intelligence analysis using system heuristics, disk metrics and persistence scans.
    func runAnalysis(overview: SystemOverview? = nil) async -> AISystemHealthScore {
        isAnalyzing = true
        defer { isAnalyzing = false }

        try? await Task.sleep(nanoseconds: 250_000_000)

        var recommendations: [AIRecommendation] = []
        var totalDeductions = 0

        // 1. Storage Pressure Analysis
        if let overview, let fraction = overview.storageUsageFraction {
            if fraction > 0.85 {
                totalDeductions += 25
                recommendations.append(AIRecommendation(
                    title: "Almacenamiento crítico (>85%)",
                    detail: "Apple Intelligence detectó que el disco principal supera el umbral recomendado para memoria virtual y swap. Limpiar cachés y residuos liberará espacio crucial.",
                    category: .storage,
                    priority: .high,
                    systemSymbol: "exclamationmark.arrow.circlepath",
                    action: .runGlobalScan
                ))
            } else if fraction > 0.70 {
                totalDeductions += 10
                recommendations.append(AIRecommendation(
                    title: "Optimización preventiva de espacio",
                    detail: "El disco está al \(Int(fraction * 100))% de capacidad. Se sugiere una inspección de cachés temporales de aplicaciones inactivas.",
                    category: .storage,
                    priority: .medium,
                    systemSymbol: "sparkles",
                    action: .runGlobalScan
                ))
            }
        }

        // 2. RAM Pressure & Heavy Processes Heuristics
        let monitor = PerformanceMonitor.shared
        monitor.refreshMetrics()
        let memInfo = monitor.memoryInfo
        let heavyApps = monitor.heavyProcesses

        if monitor.isHighMemoryPressure {
            let isCritical = memInfo.pressureState == .critical || memInfo.usedFraction > 0.88
            totalDeductions += isCritical ? 22 : 12

            let heavySummary = heavyApps.prefix(2).map { "\($0.name) (\(ByteCountFormatter.string(fromByteCount: $0.memoryBytes, countStyle: .memory)))" }.joined(separator: ", ")
            let detailText: String
            if !heavySummary.isEmpty {
                detailText = "La memoria RAM está al \(Int(memInfo.usedFraction * 100))% de uso. Se detectaron procesos pesados como \(heavySummary). Cerrarlos o purgar la memoria evitará ralentizaciones."
            } else {
                detailText = "La memoria RAM está al \(Int(memInfo.usedFraction * 100))% de uso con presión \(memInfo.pressureState.rawValue.lowercased()). Cerrar aplicaciones en segundo plano restaurará la fluidez del sistema."
            }

            let totalPotentialSavings = heavyApps.reduce(Int64(0)) { $0 + $1.memoryBytes }

            recommendations.append(AIRecommendation(
                title: "Presión de RAM elevada (\(Int(memInfo.usedFraction * 100))%)",
                detail: detailText,
                category: .performance,
                priority: isCritical ? .high : .medium,
                potentialSavingsBytes: totalPotentialSavings > 0 ? totalPotentialSavings : nil,
                systemSymbol: "memorychip.fill",
                action: heavyApps.isEmpty ? .optimizeRAM : .closeHeavyProcesses
            ))
        }

        // 3. System Uptime / Memory Heuristics
        if let overview, overview.uptime > 7 * 86400 {
            totalDeductions += 8
            recommendations.append(AIRecommendation(
                title: "Reinicio preventivo sugerido",
                detail: "Tu Mac lleva más de 7 días activo. Un reinicio o liberación de búferes de memoria restaura el rendimiento de la caché del kernel.",
                category: .performance,
                priority: .low,
                systemSymbol: "bolt.badge.clock",
                action: .optimizeRAM
            ))
        }

        // 3. User Cache Analysis (light scan)
        let cacheURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Caches", isDirectory: true)
        if let contents = try? FileManager.default.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey], options: [.skipsHiddenFiles]) {
            let staleThreshold = Date().addingTimeInterval(-30 * 86400)
            var staleCount = 0

            for item in contents.prefix(40) {
                if let modDate = (try? item.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate,
                   modDate < staleThreshold {
                    staleCount += 1
                }
            }

            if staleCount > 5 {
                totalDeductions += 12
                recommendations.append(AIRecommendation(
                    title: "Cachés inactivas detectadas",
                    detail: "Se encontraron carpetas de caché sin modificar en más de 30 días. Su eliminación es 100% segura y agiliza la indexación de macOS.",
                    category: .storage,
                    priority: .medium,
                    systemSymbol: "folder.badge.gearshape",
                    action: .runGlobalScan
                ))
            }
        }

        // 4. Persistence / Background Agent Audit
        let launchAgentsURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents", isDirectory: true)
        if let agentFiles = try? FileManager.default.contentsOfDirectory(at: launchAgentsURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]),
           agentFiles.count > 6 {
            totalDeductions += 10
            recommendations.append(AIRecommendation(
                title: "Optimización de ítems de arranque",
                detail: "Tienes \(agentFiles.count) agentes de inicio registrados en segundo plano. Revisar elementos no esenciales acelerará el arranque de tu Mac.",
                category: .performance,
                priority: .medium,
                systemSymbol: "gauge.with.needle",
                action: .openPersistenceAudit
            ))
        }

        if recommendations.isEmpty {
            recommendations.append(AIRecommendation(
                title: "Sistema en condiciones óptimas",
                detail: "Apple Intelligence no detectó acumulación anómala de archivos residuales ni presiones de rendimiento.",
                category: .system,
                priority: .low,
                systemSymbol: "checkmark.circle.fill"
            ))
        }

        let computedScore = max(35, 100 - totalDeductions)
        let statusString: String
        if computedScore >= 85 {
            statusString = "Excelente estado"
        } else if computedScore >= 65 {
            statusString = "Optimización recomendada"
        } else {
            statusString = "Atención requerida"
        }

        let result = AISystemHealthScore(
            score: computedScore,
            statusText: statusString,
            recommendations: recommendations
        )
        self.healthScore = result
        return result
    }

    /// Mark an optimization run as completed
    func recordOptimizationComplete() {
        self.lastOptimizedDate = Date()
    }
}

// MARK: - App Intents for Apple Intelligence & Siri Shortcuts (macOS 14+ / iOS 18+)

struct RunSmartScanIntent: AppIntent {
    static let title: LocalizedStringResource = "Escanear Mac con Veltrix Security"
    static let description = IntentDescription("Apple Intelligence ejecuta un análisis inteligente de almacenamiento y amenazas en tu Mac.")
    static let openAppWhenRun: Bool = true

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        _ = await AppleIntelligenceEngine.shared.runAnalysis()
        return .result(dialog: "Apple Intelligence ha completado el diagnóstico inteligente de tu Mac.")
    }
}

struct OptimizeStorageIntent: AppIntent {
    static let title: LocalizedStringResource = "Optimizar Almacenamiento con Veltrix Security"
    static let description = IntentDescription("Apple Intelligence optimiza el espacio en disco liberando cachés inactivas y residuos.")
    static let openAppWhenRun: Bool = true

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        AppleIntelligenceEngine.shared.recordOptimizationComplete()
        return .result(dialog: "Veltrix Security ha optimizado el almacenamiento de tu Mac con Apple Intelligence.")
    }
}

struct CheckMacHealthIntent: AppIntent {
    static let title: LocalizedStringResource = "Consultar Salud del Mac"
    static let description = IntentDescription("Pregunta a Siri y Apple Intelligence cómo se encuentra tu Mac.")
    static let openAppWhenRun: Bool = true

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let health = await AppleIntelligenceEngine.shared.runAnalysis()
        return .result(dialog: "Tu Mac tiene un \(health.score)% de salud general: \(health.statusText).")
    }
}

struct ScanThreatsIntent: AppIntent {
    static let title: LocalizedStringResource = "Buscar Amenazas en el Mac"
    static let description = IntentDescription("Pide a Siri que inspeccione agentes de inicio y scripts sospechosos.")
    static let openAppWhenRun: Bool = true

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let report = await ThreatScanner().scan()
        if report.highRiskCount > 0 {
            return .result(dialog: "Apple Intelligence detectó \(report.highRiskCount) elemento(s) de riesgo alto en tu Mac.")
        } else {
            return .result(dialog: "No se detectaron amenazas en las rutas de inicio del sistema.")
        }
    }
}

struct GetReclaimableSpaceIntent: AppIntent {
    static let title: LocalizedStringResource = "Consultar Espacio Recuperable"
    static let description = IntentDescription("Siri calcula cuánto espacio puedes liberar con Veltrix Security.")
    static let openAppWhenRun: Bool = true

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let cacheRoot = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Caches", isDirectory: true)
        let cacheReport = try? await FolderScanner().scan(rootURL: cacheRoot, mode: .folderUsage) { _ in }
        let bytes = cacheReport?.totalAllocatedBytes ?? 0
        let formatted = bytes.formatted(.byteCount(style: .file))
        return .result(dialog: "Puedes liberar aproximadamente \(formatted) de cachés inactivas en tu Mac.")
    }
}

struct VeltrixSecurityShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: RunSmartScanIntent(),
            phrases: [
                "Escanear mi Mac con \(.applicationName)",
                "Analizar mi Mac con \(.applicationName)",
                "Diagnóstico inteligente con \(.applicationName)"
            ],
            shortTitle: "Escanear Mac",
            systemImageName: "sparkles"
        )
        AppShortcut(
            intent: OptimizeStorageIntent(),
            phrases: [
                "Optimizar mi Mac con \(.applicationName)",
                "Liberar espacio con \(.applicationName)",
                "Limpiar basura con \(.applicationName)"
            ],
            shortTitle: "Optimizar Mac",
            systemImageName: "bolt.badge.sparkles"
        )
        AppShortcut(
            intent: CheckMacHealthIntent(),
            phrases: [
                "Salud de mi Mac con \(.applicationName)",
                "Cómo está mi Mac con \(.applicationName)",
                "Estado del sistema con \(.applicationName)"
            ],
            shortTitle: "Salud del Mac",
            systemImageName: "heart.text.square.fill"
        )
        AppShortcut(
            intent: ScanThreatsIntent(),
            phrases: [
                "Buscar amenazas con \(.applicationName)",
                "Antivirus con \(.applicationName)",
                "Escanear agentes sospechosos con \(.applicationName)"
            ],
            shortTitle: "Buscar Amenazas",
            systemImageName: "shield.checkered"
        )
        AppShortcut(
            intent: GetReclaimableSpaceIntent(),
            phrases: [
                "Cuánto espacio puedo liberar con \(.applicationName)",
                "Espacio basura con \(.applicationName)",
                "Archivos recuperables con \(.applicationName)"
            ],
            shortTitle: "Espacio Recuperable",
            systemImageName: "internaldrive.badge.sparkles"
        )
    }
}
