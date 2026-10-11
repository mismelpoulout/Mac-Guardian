import SwiftUI

struct StatusWidget: View {
    @ObservedObject var engine = GlobalSmartScanEngine.shared
    @ObservedObject var menuBar = MenuBarManager.shared
    @State private var systemSpaceInfo: (used: Int64, total: Int64)?
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "shield.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Veltrix Security")
                        .font(.headline)
                    Text("Estado: Normal")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            Divider()
            
            // Quick Stats
            HStack(spacing: 12) {
                StatCard(
                    title: "Espacio Libre",
                    value: formatBytes(getFreeSpace()),
                    icon: "internaldrive.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Archivos",
                    value: "\(engine.filesExaminedCount)",
                    icon: "doc.fill",
                    color: .blue
                )
            }
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Liberado",
                    value: formatBytes(menuBar.freedSpaceToday),
                    icon: "trash.fill",
                    color: .red
                )
                
                StatCard(
                    title: "Amenazas",
                    value: "\(engine.report.items(for: .threats).count)",
                    icon: "exclamationmark.triangle.fill",
                    color: .orange
                )
            }
            
            Divider()
            
            // Recent Activity
            VStack(alignment: .leading, spacing: 8) {
                Text("Actividad Reciente")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if let lastCleanup = menuBar.lastCleanupDate {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Última limpieza")
                                .font(.caption)
                            Text(lastCleanup.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                } else {
                    Text("Sin limpiezas registradas")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding(10)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Divider()
            
            // Quick Actions
            HStack(spacing: 8) {
                Button(action: { startScan() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "magnifyingglass")
                        Text("Escanear")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                
                Button(action: { startCleanup() }) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                        Text("Limpiar")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding(16)
        .frame(maxWidth: 320)
        .onAppear {
            getSystemSpace()
        }
    }
    
    private func startScan() {
        engine.startScan()
    }
    
    private func startCleanup() {
        NotificationCenter.default.post(name: NSNotification.Name("StartCleanup"), object: nil)
    }
    
    private func getSystemSpace() {
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory())
            if let totalSize = attributes[.systemSize] as? Int64,
               let freeSize = attributes[.systemFreeSize] as? Int64 {
                systemSpaceInfo = (used: totalSize - freeSize, total: totalSize)
            }
        } catch {
            print("Error getting space: \(error)")
        }
    }
    
    private func getFreeSpace() -> Int64 {
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory())
            return (attributes[.systemFreeSize] as? Int64) ?? 0
        } catch {
            return 0
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    StatusWidget()
}
