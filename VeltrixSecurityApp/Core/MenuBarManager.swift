import SwiftUI
import AppKit

@MainActor
class MenuBarManager: NSObject, ObservableObject {
    static let shared = MenuBarManager()
    
    @Published var isMenuBarVisible = false
    @Published var lastCleanupDate: Date?
    @Published var freedSpaceToday: Int64 = 0
    @Published var systemStatus: String = "Normal"
    
    private var statusItem: NSStatusItem?
    private var mainWindow: NSWindow?
    private var popover: NSPopover?
    
    override init() {
        super.init()
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "shield.fill", accessibilityDescription: "Veltrix Security")
            button.action = #selector(toggleMenuBarPopover)
            button.target = self
        }
    }
    
    @objc private func toggleMenuBarPopover() {
        if let popover = popover, popover.isShown {
            popover.performClose(nil)
            self.popover = nil
        } else {
            showMenuBarPopover()
        }
    }
    
    private func showMenuBarPopover() {
        let popover = NSPopover()
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(manager: self)
        )
        popover.behavior = .transient
        popover.appearance = NSAppearance(named: .darkAqua)
        
        if let statusButton = statusItem?.button {
            popover.show(relativeTo: statusButton.bounds, of: statusButton, preferredEdge: .minY)
        }
        
        self.popover = popover
    }
    
    func toggleMainWindow() {
        if let window = mainWindow {
            if window.isVisible {
                window.orderOut(nil)
            } else {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    func setMainWindow(_ window: NSWindow?) {
        self.mainWindow = window
    }
    
    func updateLastCleanup(freedBytes: Int64, date: Date = Date()) {
        lastCleanupDate = date
        freedSpaceToday += freedBytes
    }
    
    func resetDailyStats() {
        let calendar = Calendar.current
        let lastMidnight = calendar.startOfDay(for: Date())
        if let lastCleanup = lastCleanupDate, lastCleanup < lastMidnight {
            freedSpaceToday = 0
        }
    }
}

struct MenuBarView: View {
    @ObservedObject var manager: MenuBarManager
    @State private var showMainWindow = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "shield.fill")
                    .foregroundColor(.blue)
                Text("Veltrix Security")
                    .font(.headline)
                Spacer()
                Button(action: { NSApp.terminate(nil) }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Estado: \(manager.systemStatus)")
                        .font(.caption)
                }
                
                if let lastCleanup = manager.lastCleanupDate {
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Última limpieza")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(lastCleanup.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                        }
                    }
                }
                
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Liberado hoy")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(formatBytes(manager.freedSpaceToday))
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
            }
            .padding(.vertical, 8)
            
            Divider()
            
            VStack(spacing: 8) {
                Button(action: { manager.toggleMainWindow() }) {
                    HStack {
                        Image(systemName: "window.maximize")
                        Text("Abrir App")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(6)
                
                Button(action: { startQuickScan() }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Escaneo Rápido")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.2))
                .cornerRadius(6)
                
                Button(action: { startCleanup() }) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Limpiar Ahora")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.2))
                .cornerRadius(6)
            }
        }
        .frame(width: 280)
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
    }
    
    private func startQuickScan() {
        manager.toggleMainWindow()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(name: NSNotification.Name("StartQuickScan"), object: nil)
        }
    }
    
    private func startCleanup() {
        manager.toggleMainWindow()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(name: NSNotification.Name("StartCleanup"), object: nil)
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytes)
    }
}
