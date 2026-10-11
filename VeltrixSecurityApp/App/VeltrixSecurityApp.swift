import SwiftUI

@main
struct VeltrixSecurityApp: App {
    init() {
        handleCommandLineArguments()
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 900, minHeight: 620)
        }
        .windowStyle(.titleBar)
    }

    private func handleCommandLineArguments() {
        let arguments = CommandLine.arguments
        if arguments.contains("--scheduled-cleanup") {
            executeScheduledCleanup()
            // Exit after cleanup completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                exit(0)
            }
        }
    }

    private func executeScheduledCleanup() {
        Task {
            let engine = GlobalSmartScanEngine.shared
            let manager = ScheduledCleanupManager.shared

            print("[VeltrixSecurity] Iniciando limpieza programada...")
            
            // Load current settings to know what to clean
            let settings = manager.settings
            guard settings.isEnabled else {
                print("[VeltrixSecurity] Limpieza programada deshabilitada. Abortando.")
                NotificationManager.shared.showNotification(
                    title: "Veltrix Security",
                    subtitle: "Limpieza programada",
                    body: "La limpieza programada está deshabilitada en la configuración."
                )
                return
            }

            // Start scan
            engine.startScan()
            
            // Wait for scan to complete (max 120 seconds)
            var elapsed = 0
            while engine.isScanning && elapsed < 120 {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                elapsed += 1
            }

            print("[VeltrixSecurity] Escaneo completado. Elementos encontrados: \(engine.filesExaminedCount)")

            // Collect items to clean based on settings
            var itemsToClean = Set<String>()
            
            if settings.cleanCaches {
                let cacheItems = engine.report.items(for: .caches)
                itemsToClean.formUnion(cacheItems.map { $0.id })
                print("[VeltrixSecurity] Cachés: \(cacheItems.count) elementos")
            }

            if settings.scanThreats {
                let threatItems = engine.report.items(for: .threats)
                itemsToClean.formUnion(threatItems.map { $0.id })
                print("[VeltrixSecurity] Amenazas: \(threatItems.count) elementos")
            }

            if settings.cleanLargeFiles {
                let largeItems = engine.report.items(for: .downloadsAndUser)
                    .filter { $0.allocatedBytes > 100_000_000 } // >100MB
                itemsToClean.formUnion(largeItems.map { $0.id })
                print("[VeltrixSecurity] Archivos grandes: \(largeItems.count) elementos")
            }

            // Execute cleanup
            if !itemsToClean.isEmpty {
                print("[VeltrixSecurity] Limpiando \(itemsToClean.count) elementos...")
                let (freedBytes, deletedCount, failedCount) = await engine.cleanSelectedItems(itemIDs: itemsToClean)
                
                let freedMB = freedBytes / 1_000_000
                let message = failedCount > 0
                    ? "Se liberaron \(freedMB) MB (\(deletedCount) elementos). Fallos: \(failedCount)"
                    : "Se liberaron \(freedMB) MB (\(deletedCount) elementos)"
                
                print("[VeltrixSecurity] Limpieza completada: \(message)")
                
                NotificationManager.shared.showNotification(
                    title: "Veltrix Security",
                    subtitle: "Limpieza programada completada",
                    body: message
                )
            } else {
                print("[VeltrixSecurity] No hay elementos para limpiar.")
                NotificationManager.shared.showNotification(
                    title: "Veltrix Security",
                    subtitle: "Limpieza programada completada",
                    body: "No se encontraron elementos para limpiar."
                )
            }
        }
    }
}
