import AppKit
import SwiftUI

struct PrivacyAuditView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Privacy").font(.largeTitle.weight(.semibold))
            Text("macOS does not provide a public API to read a complete inventory of all app privacy grants. Mac Guardian will not inspect the protected TCC database or claim permission states it cannot verify.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: 680, alignment: .leading)
            Label("Permission states not available through public macOS APIs are shown as unknown.", systemImage: "questionmark.circle")
                .foregroundStyle(.secondary)
            Button {
                openSystemSettings()
            } label: {
                Label("Open System Settings", systemImage: "gearshape")
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding(30)
    }

    private func openSystemSettings() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
    }
}

struct PerformanceView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Performance").font(.largeTitle.weight(.semibold))
            Text("For live CPU, memory pressure, and per-process measurements, macOS provides Activity Monitor. Mac Guardian will not report a performance score without measuring it.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: 680, alignment: .leading)
            Button {
                let activityMonitor = URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app")
                NSWorkspace.shared.open(activityMonitor)
            } label: {
                Label("Open Activity Monitor", systemImage: "gauge.with.needle")
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding(30)
    }
}

struct PersistenceAuditView: View {
    @State private var definitions: [PersistenceDefinition] = []
    @State private var skippedItems = 0
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Persistence Audit").font(.largeTitle.weight(.semibold))
                    Text("Inventory launch definitions in common user and third-party system folders. Presence alone does not mean an item is malicious or running.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    Task { await refresh() }
                } label: {
                    Label("Refresh Audit", systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }

            if isLoading {
                ProgressView("Reading launch definitions…")
            } else if definitions.isEmpty {
                ContentUnavailableView("No launch definitions found", systemImage: "checkmark.shield")
            } else {
                List(definitions) { definition in
                    HStack {
                        Image(systemName: "gearshape.2")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(definition.label).font(.headline)
                            Text(definition.program)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Text(definition.location.path)
                                .font(.caption2.monospaced())
                                .foregroundStyle(.tertiary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([definition.location])
                        } label: {
                            Label("Show in Finder", systemImage: "arrow.up.forward.app")
                        }
                        .labelStyle(.iconOnly)
                        .help("Show in Finder")
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
            if skippedItems > 0 {
                Label("Some launch files or folders could not be read; the inventory may be incomplete.", systemImage: "exclamationmark.triangle")
                    .font(.callout)
                    .foregroundStyle(.orange)
            }
            Label("This inventory does not disable or remove any startup item.", systemImage: "info.circle")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(30)
        .task { await refresh() }
    }

    @MainActor
    private func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        let report = await PersistenceAuditScanner().scan()
        definitions = report.definitions
        skippedItems = report.skippedItems
        isLoading = false
    }
}
