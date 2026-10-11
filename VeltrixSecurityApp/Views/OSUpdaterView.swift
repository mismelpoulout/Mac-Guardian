import AppKit
import SwiftUI

struct OSUpdaterView: View {
    @State private var report: OSUpdaterFinderReport?
    @State private var isScanning = false
    @State private var selectedArtifactIDs: Set<String> = []
    @State private var showBatchTrashConfirmation = false
    @State private var alertTitleKey: String?
    @State private var alertMessage = ""
    @Environment(\.locale) private var locale

    private var selectedBytes: Int64 {
        guard let report else { return 0 }
        return report.artifacts.filter { selectedArtifactIDs.contains($0.id) }.reduce(0) { $0 + $1.allocatedBytes }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            content
            Spacer(minLength: 0)
        }
        .padding(30)
        .task { await runScan() }
        .confirmationDialog("¿Mover los \(selectedArtifactIDs.count) instaladores/residuos seleccionados a la Papelera?", isPresented: $showBatchTrashConfirmation, titleVisibility: .visible) {
            Button("Mover a la Papelera", role: .destructive) { moveSelectedToTrash() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se enviarán a la Papelera \(selectedArtifactIDs.count) elementos seleccionados (\(formatBytes(selectedBytes))). Podrás restaurarlos desde la Papelera si fuera necesario.")
        }
        .alert(LocalizedStringKey(alertTitleKey ?? ""), isPresented: Binding(
            get: { alertTitleKey != nil },
            set: { if !$0 { alertTitleKey = nil } }
        )) {
            Button("OK", role: .cancel) { alertTitleKey = nil }
        } message: {
            Text(alertMessage)
        }
    }

    // MARK: - Sub-views

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Actualizaciones Residuales del OS")
                    .font(.largeTitle.weight(.semibold))
                Text("Cuando macOS se actualiza deja instaladores y archivos de caché en disco. Selecciona múltiples elementos con los checks para enviarlos a la Papelera en bloque.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 700, alignment: .leading)
            }
            Spacer()
            if isScanning {
                ProgressView()
            } else {
                Button {
                    Task { await runScan() }
                } label: {
                    Label("Buscar", systemImage: "arrow.clockwise")
                }
                .disabled(isScanning)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if isScanning {
            ProgressView("Buscando instaladores y cachés de actualización…")
                .frame(maxWidth: .infinity, minHeight: 200)
        } else if let report {
            if report.isEmpty {
                ContentUnavailableView(
                    "No se encontraron residuos de actualización",
                    systemImage: "checkmark.circle.fill",
                    description: Text("No se detectaron instaladores de macOS ni cachés de actualización en las rutas conocidas.")
                )
            } else {
                // Summary
                HStack(spacing: 20) {
                    summaryValue("Total recuperable", value: formatBytes(report.totalAllocatedBytes))
                    summaryValue("Elementos detectados", value: report.artifacts.count.formatted(.number.locale(locale)))
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))

                // Multi-selection bar
                multiSelectionToolbar(report: report)

                List(report.artifacts) { artifact in
                    artifactRow(artifact)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))

                Label("Veltrix Security envía los instaladores a la Papelera del sistema de forma segura sin eliminaciones irreversibles.", systemImage: "info.circle")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        } else {
            ContentUnavailableView("Buscando…", systemImage: "arrow.down.app.fill")
        }
    }

    private func multiSelectionToolbar(report: OSUpdaterFinderReport) -> some View {
        HStack(spacing: 14) {
            Button {
                if selectedArtifactIDs.count == report.artifacts.count {
                    selectedArtifactIDs.removeAll()
                } else {
                    selectedArtifactIDs = Set(report.artifacts.map(\.id))
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selectedArtifactIDs.count == report.artifacts.count ? "checkmark.circle.fill" : (selectedArtifactIDs.isEmpty ? "circle" : "minus.circle.fill"))
                        .foregroundStyle(selectedArtifactIDs.isEmpty ? .secondary : Color.orange)
                    Text(selectedArtifactIDs.count == report.artifacts.count ? "Deseleccionar todos" : "Seleccionar todos")
                }
            }
            .buttonStyle(.bordered)

            if !selectedArtifactIDs.isEmpty {
                HStack(spacing: 6) {
                    Text("\(selectedArtifactIDs.count) seleccionado(s)")
                        .font(.subheadline.weight(.semibold))
                    Text("(\(formatBytes(selectedBytes)))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.purple.opacity(0.12), in: Capsule())

                Spacer()

                Button(role: .destructive) {
                    showBatchTrashConfirmation = true
                } label: {
                    Label("Mover seleccionados a Papelera", systemImage: "trash.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            } else {
                Spacer()
                Text("Marca las casillas para eliminar varios instaladores a la vez")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }

    private func artifactRow(_ artifact: OSUpdaterArtifact) -> some View {
        HStack(spacing: 14) {
            // Checkbox
            Button {
                toggleSelection(artifact.id)
            } label: {
                Image(systemName: selectedArtifactIDs.contains(artifact.id) ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selectedArtifactIDs.contains(artifact.id) ? Color.purple : Color.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
            .help("Seleccionar elemento")

            Image(systemName: kindSymbol(artifact.kind))
                .font(.title3)
                .foregroundStyle(.purple)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(artifact.displayName)
                    .font(.headline)
                Text(artifact.url.path)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(kindDescription(artifact.kind))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Text(formatBytes(artifact.allocatedBytes))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)

            Button {
                NSWorkspace.shared.activateFileViewerSelecting([artifact.url])
            } label: {
                Label("Mostrar en Finder", systemImage: "arrow.up.forward.app")
            }
            .labelStyle(.iconOnly)
            .help("Mostrar en Finder")

            Button(role: .destructive) {
                moveToTrash(artifact)
            } label: {
                Label("Mover a Papelera", systemImage: "trash")
            }
            .labelStyle(.iconOnly)
            .help("Mover instalador a la Papelera")
        }
        .padding(.vertical, 6)
    }

    private func toggleSelection(_ id: String) {
        if selectedArtifactIDs.contains(id) {
            selectedArtifactIDs.remove(id)
        } else {
            selectedArtifactIDs.insert(id)
        }
    }

    private func summaryValue(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline.monospacedDigit())
        }
    }

    // MARK: - Helpers

    private func kindSymbol(_ kind: OSUpdaterArtifact.ArtifactKind) -> String {
        switch kind {
        case .macOSInstaller: return "arrow.down.app.fill"
        case .softwareUpdateCache: return "externaldrive.badge.timemachine"
        case .seedCatalog: return "doc.badge.clock"
        }
    }

    private func kindDescription(_ kind: OSUpdaterArtifact.ArtifactKind) -> String {
        switch kind {
        case .macOSInstaller: return "Instalador de macOS — se puede eliminar tras actualizar"
        case .softwareUpdateCache: return "Área de staging de SoftwareUpdate — archivos de actualización temporales"
        case .seedCatalog: return "Caché de catálogo/delta de Apple — descargado durante actualizaciones"
        }
    }

    private func formatBytes(_ bytes: Int64) -> String {
        bytes.formatted(.byteCount(style: .file).locale(locale))
    }

    // MARK: - Actions

    private func moveToTrash(_ artifact: OSUpdaterArtifact) {
        do {
            try FileManager.default.trashItem(at: artifact.url, resultingItemURL: nil)
            selectedArtifactIDs.remove(artifact.id)
            Task { await runScan() }
        } catch {
            alertTitleKey = "No se pudo mover a la Papelera"
            alertMessage = error.localizedDescription
        }
    }

    private func moveSelectedToTrash() {
        guard let report else { return }
        let selected = report.artifacts.filter { selectedArtifactIDs.contains($0.id) }
        var moved = 0
        var failed = 0

        for item in selected {
            do {
                try FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
                moved += 1
            } catch {
                failed += 1
            }
        }

        selectedArtifactIDs.removeAll()
        alertTitleKey = "Eliminación completada"
        if failed == 0 {
            alertMessage = "Se enviaron \(moved) elementos a la Papelera."
        } else {
            alertMessage = "Se enviaron \(moved) elementos a la Papelera. \(failed) elementos no pudieron moverse."
        }
        Task { await runScan() }
    }

    @MainActor
    private func runScan() async {
        guard !isScanning else { return }
        isScanning = true
        report = await OSUpdaterFinder().scan()
        isScanning = false
    }
}
