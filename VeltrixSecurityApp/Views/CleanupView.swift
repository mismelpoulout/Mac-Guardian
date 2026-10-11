import AppKit
import SwiftUI

struct CleanupView: View {
    private let cacheRoot = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Caches", isDirectory: true)

    @State private var model = FolderScanViewModel()
    @State private var selectedItemIDs: Set<String> = []
    @State private var pendingItem: ScannedFile?
    @State private var showTrashConfirmation = false
    @State private var showBatchTrashConfirmation = false
    @State private var selectedPopoverItem: ScannedFile?
    @State private var alertTitleKey: String?
    @State private var alertMessage = ""
    @State private var engine = AppleIntelligenceEngine.shared
    @Environment(\.locale) private var locale

    private var selectedBytes: Int64 {
        guard let files = model.report?.files else { return 0 }
        return files.filter { selectedItemIDs.contains($0.id) }.reduce(0) { $0 + $1.allocatedBytes }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text("Revisión de Limpieza").font(.largeTitle.weight(.semibold))
                    aiBadge
                }
                Text("Revisa y purga cachés de usuario. Usa la Selección Inteligente con Apple Intelligence para seleccionar con un clic solo los elementos 100% seguros sin tocar apps activas.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 760, alignment: .leading)
            }

            HStack(spacing: 12) {
                if model.isScanning {
                    ProgressView("Analizando cachés de usuario…")
                    Text(model.filesScanned.formatted(.number.locale(locale)))
                        .monospacedDigit()
                    Button("Cancelar análisis", role: .cancel) { model.cancelScan() }
                } else {
                    Button {
                        scanCaches()
                    } label: {
                        Label("Analizar cachés de usuario", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)

                    if let report = model.report, !report.files.isEmpty {
                        Button {
                            smartSelectWithAI(files: report.files)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(.purple)
                                Text("Selección Inteligente Apple Intelligence")
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(.purple)
                        .help("Selecciona automáticamente solo las cachés seguras e inactivas recomendadas por Apple Intelligence")
                    }
                }
            }

            if let key = model.errorMessageKey {
                Label(LocalizedStringKey(key), systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }

            if let report = model.report {
                if report.skippedItems > 0 {
                    Label("Algunos elementos no se pudieron leer; el tamaño mostrado puede ser parcial.", systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .foregroundStyle(.orange)
                }
                HStack(spacing: 22) {
                    summary("Total asignado", report.totalAllocatedBytes.formatted(.byteCount(style: .file).locale(locale)))
                    summary("Elementos de caché", report.files.count.formatted(.number.locale(locale)))
                    if report.skippedItems > 0 {
                        summary("Omitidos", report.skippedItems.formatted(.number.locale(locale)))
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))

                if report.files.isEmpty {
                    ContentUnavailableView("No se encontraron elementos de caché", systemImage: "checkmark.circle")
                } else {
                    // Multi-selection bar
                    multiSelectionToolbar(report: report)

                    List(report.files) { item in
                        cacheRow(item)
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                }
            } else if !model.isScanning {
                ContentUnavailableView(
                    "Analiza tus cachés de usuario",
                    systemImage: "sparkles",
                    description: Text("Veltrix Security y Apple Intelligence clasifican los elementos de caché antes de enviarlos a la Papelera.")
                )
            }
            Spacer(minLength: 0)
        }
        .padding(30)
        .confirmationDialog("¿Mover elemento a la Papelera?", isPresented: $showTrashConfirmation, titleVisibility: .visible) {
            Button("Mover a la Papelera", role: .destructive) { movePendingItemToTrash() }
            Button("Cancelar", role: .cancel) { pendingItem = nil }
        } message: {
            if pendingItem != nil {
                Text("El elemento se moverá a la Papelera. Puedes restaurarlo en cualquier momento.")
            }
        }
        .confirmationDialog("¿Mover los \(selectedItemIDs.count) elementos seleccionados a la Papelera?", isPresented: $showBatchTrashConfirmation, titleVisibility: .visible) {
            Button("Mover seleccionados a la Papelera", role: .destructive) { moveSelectedItemsToTrash() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se moverán \(selectedItemIDs.count) elementos seleccionados (\(selectedBytes.formatted(.byteCount(style: .file).locale(locale)))) a la Papelera de tu Mac.")
        }
        .alert(LocalizedStringKey(alertTitleKey ?? ""), isPresented: Binding(
            get: { alertTitleKey != nil },
            set: { if !$0 { alertTitleKey = nil } }
        )) {
            Button("OK", role: .cancel) { alertTitleKey = nil }
        } message: {
            Text(alertMessage)
        }
        .task { scanCaches() }
    }

    private var aiBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.bold))
                .foregroundStyle(.purple)
            Text("Apple Intelligence Activo")
                .font(.caption.weight(.bold))
                .foregroundStyle(.purple)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(
            LinearGradient(colors: [.purple.opacity(0.18), .blue.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: Capsule()
        )
    }

    // MARK: - Row

    private func cacheRow(_ item: ScannedFile) -> some View {
        let verdict = engine.evaluateCacheItem(url: item.url, bytes: item.allocatedBytes, modifiedAt: item.modifiedAt)

        return HStack(spacing: 12) {
            Button {
                toggleSelection(item.id)
            } label: {
                Image(systemName: selectedItemIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selectedItemIDs.contains(item.id) ? Color.orange : Color.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
            .help("Seleccionar elemento")

            Image(systemName: item.url.hasDirectoryPath ? "folder" : "doc")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(item.url.lastPathComponent)
                        .font(.headline)

                    // AI Verdict Pill
                    HStack(spacing: 4) {
                        Image(systemName: verdict.systemSymbol)
                            .font(.caption2)
                        Text(verdict.badgeText)
                            .font(.caption2.weight(.semibold))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(verdict.badgeColor.opacity(0.14), in: Capsule())
                    .foregroundStyle(verdict.badgeColor)
                }

                Text(verdict.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer()

            Text(item.allocatedBytes.formatted(.byteCount(style: .file).locale(locale)))
                .monospacedDigit()
                .foregroundStyle(.secondary)

            Button {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            } label: {
                Label("Mostrar en Finder", systemImage: "arrow.up.forward.app")
            }
            .labelStyle(.iconOnly)
            .help("Mostrar en Finder")

            Button(role: .destructive) {
                pendingItem = item
                showTrashConfirmation = true
            } label: {
                Label("Mover a Papelera", systemImage: "trash")
            }
            .labelStyle(.iconOnly)
            .disabled(model.isScanning)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Multi-selection Toolbar

    private func multiSelectionToolbar(report: FolderScanReport) -> some View {
        HStack(spacing: 14) {
            Button {
                if selectedItemIDs.count == report.files.count {
                    selectedItemIDs.removeAll()
                } else {
                    selectedItemIDs = Set(report.files.map(\.id))
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selectedItemIDs.count == report.files.count ? "checkmark.circle.fill" : (selectedItemIDs.isEmpty ? "circle" : "minus.circle.fill"))
                        .foregroundStyle(selectedItemIDs.isEmpty ? .secondary : Color.orange)
                    Text(selectedItemIDs.count == report.files.count ? "Deseleccionar todos" : "Seleccionar todos")
                }
            }
            .buttonStyle(.bordered)

            if !selectedItemIDs.isEmpty {
                HStack(spacing: 6) {
                    Text("\(selectedItemIDs.count) seleccionado(s)")
                        .font(.subheadline.weight(.semibold))
                    Text("(\(selectedBytes.formatted(.byteCount(style: .file).locale(locale))))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.orange.opacity(0.12), in: Capsule())

                Spacer()

                Button(role: .destructive) {
                    showBatchTrashConfirmation = true
                } label: {
                    Label("Eliminar seleccionados", systemImage: "trash.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            } else {
                Spacer()
                Text("Marca casillas o usa Selección Inteligente")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }

    private func smartSelectWithAI(files: [ScannedFile]) {
        let safeIDs = files.compactMap { file -> String? in
            let verdict = engine.evaluateCacheItem(url: file.url, bytes: file.allocatedBytes, modifiedAt: file.modifiedAt)
            return verdict.isRecommended ? file.id : nil
        }
        selectedItemIDs = Set(safeIDs)
    }

    private func toggleSelection(_ id: String) {
        if selectedItemIDs.contains(id) {
            selectedItemIDs.remove(id)
        } else {
            selectedItemIDs.insert(id)
        }
    }

    private func summary(_ title: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline.monospacedDigit())
        }
    }

    private func scanCaches() {
        selectedItemIDs.removeAll()
        model.selectFolder(cacheRoot)
        model.startScan(mode: .folderUsage)
    }

    private func movePendingItemToTrash() {
        guard let pendingItem else { return }
        do {
            try TrashService.moveCacheItemToTrash(pendingItem.url, cacheRoot: cacheRoot)
            alertTitleKey = "Movido a la Papelera"
            alertMessage = "El elemento se movió a la Papelera correctamente."
            self.pendingItem = nil
            scanCaches()
        } catch {
            alertTitleKey = "No se pudo mover el elemento a la Papelera"
            alertMessage = "macOS no pudo mover este ítem. Comprueba permisos."
            self.pendingItem = nil
        }
    }

    private func moveSelectedItemsToTrash() {
        guard let files = model.report?.files else { return }
        let itemsToMove = files.filter { selectedItemIDs.contains($0.id) }
        var movedCount = 0
        var failedCount = 0

        for item in itemsToMove {
            do {
                try TrashService.moveCacheItemToTrash(item.url, cacheRoot: cacheRoot)
                movedCount += 1
            } catch {
                failedCount += 1
            }
        }

        selectedItemIDs.removeAll()
        alertTitleKey = "Limpieza completada"
        if failedCount == 0 {
            alertMessage = "Se movieron exitosamente \(movedCount) elementos a la Papelera."
        } else {
            alertMessage = "Se movieron \(movedCount) elementos a la Papelera. \(failedCount) elementos no pudieron ser movidos."
        }
        scanCaches()
    }
}
