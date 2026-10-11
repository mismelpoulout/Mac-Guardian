import SwiftUI
import AppKit

struct AutoInspectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var engine = GlobalSmartScanEngine.shared
    @State private var selectedCategory: GlobalScanCategory = .caches
    @State private var selectedSubcategoryFilter: String = "all"
    @State private var selectedItemIDs: Set<String> = []
    @State private var showCleaningConfirmation = false
    @State private var cleaningSummaryText: String? = nil
    @State private var trashEmptiedText: String? = nil
    @State private var isEmptyingTrash = false
    @State private var alertTitleKey: String?
    @State private var alertMessage = ""
    @Environment(\.locale) private var locale

    var onNavigateToCleanup: () -> Void = {}
    var onNavigateToSecurity: () -> Void = {}

    private var displayedItems: [GlobalScanItem] {
        let categoryItems = engine.report.items(for: selectedCategory)
        if selectedSubcategoryFilter == "all" {
            return categoryItems
        }
        return categoryItems.filter { $0.subcategory.rawValue == selectedSubcategoryFilter }
    }

    private var selectedBytes: Int64 {
        engine.report.items.filter { selectedItemIDs.contains($0.id) }.reduce(0) { $0 + $1.allocatedBytes }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if engine.isScanning {
                scanningBody
            } else if engine.isCleaning {
                cleaningProgressBody
            } else if let summary = cleaningSummaryText {
                cleanSuccessBody(summary)
            } else if engine.report.isComplete {
                resultsBody
            } else {
                idleBody
            }

            Divider()
            footer
        }
        .frame(minWidth: 880, minHeight: 640)
        .onAppear {
            if !engine.isScanning && !engine.report.isComplete {
                engine.startScan()
            }
            applySmartSelection()
        }
        .onChange(of: engine.report.isComplete) { _, isDone in
            if isDone {
                applySmartSelection()
                // Default to threats if any, otherwise caches
                if engine.report.threatCount > 0 {
                    selectedCategory = .threats
                } else {
                    selectedCategory = .caches
                }
            }
        }
        .confirmationDialog(
            "¿Confirmas la limpieza de los \(selectedItemIDs.count) elementos seleccionados?",
            isPresented: $showCleaningConfirmation,
            titleVisibility: .visible
        ) {
            Button("Limpiar ahora (\(selectedBytes.formatted(.byteCount(style: .file).locale(locale))))", role: .destructive) {
                executeCleanup()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Veltrix Security enviará los elementos a la Papelera de forma segura y vaciará los archivos temporales obsoletos sin tocar tus archivos de sistema.")
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Análisis Global Inteligente")
                        .font(.title2.weight(.bold))
                    aiBadge
                }
                Text("Escaneo exhaustivo de amenazas, descargas, cachés de apps y archivos temporales ocultos.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if engine.report.isComplete && !engine.isCleaning {
                Button {
                    engine.startScan()
                } label: {
                    Label("Volver a escanear", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(20)
    }

    private var aiBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.bold))
                .foregroundStyle(.purple)
            Text("Apple Intelligence")
                .font(.caption.weight(.bold))
                .foregroundStyle(.purple)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 3)
        .background(
            LinearGradient(colors: [.purple.opacity(0.18), .blue.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: Capsule()
        )
    }

    // MARK: - Scanning Phase

    private var scanningBody: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                // Outer pulsing glow
                Circle()
                    .strokeBorder(
                        LinearGradient(colors: [.orange.opacity(0.4), .purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 3
                    )
                    .frame(width: 170, height: 170)

                Circle()
                    .fill(
                        LinearGradient(colors: [Color.orange.opacity(0.15), Color.purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 140, height: 140)

                VStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(1.3)
                    Text("Escaneando")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
            }

            VStack(spacing: 6) {
                Text(engine.currentTaskName)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                HStack(spacing: 16) {
                    Label("\(engine.filesExaminedCount) archivos examinados", systemImage: "doc.text.magnifyingglass")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.tertiary)

                    Label("\(engine.bytesAccumulated.formatted(.byteCount(style: .file).locale(locale))) detectados", systemImage: "internaldrive")
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.orange)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }

    // MARK: - Cleaning Progress Phase

    private var cleaningProgressBody: some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.4)
            Text("Optimizando tu Mac…")
                .font(.title2.weight(.bold))
            Text(engine.cleanProgressText)
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }

    // MARK: - Clean Success Phase

    private func cleanSuccessBody(_ summary: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("¡Veltrix Security ha completado la optimización!")
                .font(.title2.weight(.bold))
            Text(summary)
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if let trashMsg = trashEmptiedText {
                Label(trashMsg, systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.green)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    .transition(.scale.combined(with: .opacity))
            }

            HStack(spacing: 16) {
                if trashEmptiedText == nil {
                    Button {
                        emptyTrashNow()
                    } label: {
                        if isEmptyingTrash {
                            ProgressView()
                                .scaleEffect(0.8)
                                .padding(.horizontal, 8)
                        } else {
                            Label("Vaciar Papelera", systemImage: "trash.fill")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(isEmptyingTrash)
                }

                Button("Cerrar") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(.top, 10)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(32)
        .animation(.spring(response: 0.3), value: trashEmptiedText)
    }

    // MARK: - Results Phase

    private var resultsBody: some View {
        VStack(spacing: 0) {
            // Summary Top Bar
            summaryTopBar
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Category Tab Picker
            categoryTabBar
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.quaternary.opacity(0.2))

            Divider()

            // Subcategory Filter & Multi-selection Toolbar
            toolbarSection
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

            Divider()

            // List of Items
            if displayedItems.isEmpty {
                ContentUnavailableView(
                    "Sin elementos en esta sección",
                    systemImage: "checkmark.circle.fill",
                    description: Text("No se encontraron archivos que requieran atención en esta categoría.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(displayedItems) { item in
                    itemRow(item)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }

    // MARK: - Summary Top Bar

    private var summaryTopBar: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 2) {
                Text("TOTAL DETECTADO")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(engine.report.totalBytes.formatted(.byteCount(style: .file).locale(locale)))
                    .font(.title2.weight(.heavy).monospacedDigit())
            }

            Divider().frame(height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("SEGURO DE LIBERAR")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.green)
                Text(engine.report.safeToDeleteBytes.formatted(.byteCount(style: .file).locale(locale)))
                    .font(.title2.weight(.heavy).monospacedDigit())
                    .foregroundStyle(.green)
            }

            if engine.report.threatCount > 0 {
                Divider().frame(height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text("AMENAZAS DETECTADAS")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.red)
                    Text("\(engine.report.threatCount) elementos")
                        .font(.title2.weight(.heavy).monospacedDigit())
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            // Giant Quick Clean Button
            if !selectedItemIDs.isEmpty {
                Button {
                    showCleaningConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Limpiar Seleccionados (\(selectedBytes.formatted(.byteCount(style: .file).locale(locale))))")
                            .font(.headline.weight(.bold))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(
                    LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            }
        }
    }

    // MARK: - Category Tab Bar

    private var categoryTabBar: some View {
        HStack(spacing: 12) {
            ForEach(GlobalScanCategory.allCases) { cat in
                let count = engine.report.items(for: cat).count
                let bytes = engine.report.bytes(for: cat)

                Button {
                    selectedCategory = cat
                    selectedSubcategoryFilter = "all"
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: cat.systemSymbol)
                            .foregroundStyle(cat.color)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(cat.rawValue)
                                .font(.callout.weight(selectedCategory == cat ? .bold : .medium))
                            Text("\(count) items • \(bytes.formatted(.byteCount(style: .file).locale(locale)))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        selectedCategory == cat ? Color.accentColor.opacity(0.15) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(selectedCategory == cat ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: - Toolbar Section

    private var toolbarSection: some View {
        HStack(spacing: 14) {
            // Smart select with AI
            Button {
                applySmartSelection()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.purple)
                    Text("Selección Inteligente IA")
                }
                .font(.callout.weight(.medium))
            }
            .buttonStyle(.bordered)
            .tint(.purple)
            .help("Marca automáticamente solo los archivos 100% seguros y desmarca los que requieran tu revisión")

            // Select all / Deselect all for current category
            Button {
                let currentCatIDs = Set(displayedItems.map(\.id))
                if currentCatIDs.isSubset(of: selectedItemIDs) {
                    selectedItemIDs.subtract(currentCatIDs)
                } else {
                    selectedItemIDs.formUnion(currentCatIDs)
                }
            } label: {
                Text(Set(displayedItems.map(\.id)).isSubset(of: selectedItemIDs) && !displayedItems.isEmpty ? "Deseleccionar vista" : "Seleccionar vista")
                    .font(.callout)
            }
            .buttonStyle(.bordered)

            Spacer()

            // Subcategory filter picker
            subcategoriesPicker
        }
    }

    @ViewBuilder
    private var subcategoriesPicker: some View {
        let items = engine.report.items(for: selectedCategory)
        let uniqueSubcats = Array(Set(items.map(\.subcategory))).sorted { $0.rawValue < $1.rawValue }

        if uniqueSubcats.count > 1 {
            Picker("Filtro:", selection: $selectedSubcategoryFilter) {
                Text("Todos (\(items.count))").tag("all")
                ForEach(uniqueSubcats) { subcat in
                    let subCount = items.filter { $0.subcategory == subcat }.count
                    Text("\(subcat.rawValue) (\(subCount))").tag(subcat.rawValue)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: 240)
        }
    }

    // MARK: - Item Row

    private func itemRow(_ item: GlobalScanItem) -> some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                if selectedItemIDs.contains(item.id) {
                    selectedItemIDs.remove(item.id)
                } else {
                    selectedItemIDs.insert(item.id)
                }
            } label: {
                Image(systemName: selectedItemIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selectedItemIDs.contains(item.id) ? Color.orange : Color.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)

            // Subcategory icon
            Image(systemName: item.subcategory.systemSymbol)
                .font(.title3)
                .foregroundStyle(item.category.color)
                .frame(width: 28)

            // Name, reason & AI verdict
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(item.displayName)
                        .font(.headline)

                    // Subcategory Pill
                    Text(item.subcategory.rawValue)
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.primary.opacity(0.08), in: Capsule())

                    if item.isSafeToDelete {
                        Text("Seguro")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.12), in: Capsule())
                    } else if let risk = item.threatRisk {
                        Text(risk.label)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(risk == .high ? .red : .orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(risk == .high ? .red.opacity(0.12) : .orange.opacity(0.12), in: Capsule())
                    }
                }

                Text(item.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Text(item.aiVerdict)
                    .font(.caption2)
                    .foregroundStyle(.purple)
                    .lineLimit(1)
            }

            Spacer()

            // Size
            Text(item.allocatedBytes.formatted(.byteCount(style: .file).locale(locale)))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)

            // Reveal in Finder
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            } label: {
                Label("Mostrar en Finder", systemImage: "arrow.up.forward.app")
            }
            .labelStyle(.iconOnly)
            .help("Mostrar en Finder")
        }
        .padding(.vertical, 4)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            if engine.isScanning {
                Button("Cancelar análisis") {
                    engine.cancelScan()
                }
            } else if engine.report.isComplete {
                HStack(spacing: 8) {
                    Text("\(selectedItemIDs.count) seleccionados")
                        .font(.subheadline.weight(.semibold))
                    Text("(\(selectedBytes.formatted(.byteCount(style: .file).locale(locale))))")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Cerrar") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                if !selectedItemIDs.isEmpty {
                    Button {
                        showCleaningConfirmation = true
                    } label: {
                        Label("Eliminar seleccionados", systemImage: "trash.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            } else {
                Spacer()
                Button("Cerrar") { dismiss() }
            }
        }
        .padding(16)
    }

    private var idleBody: some View {
        VStack {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
            Text("Preparado para el análisis inteligente")
                .font(.headline)
            Spacer()
        }
    }

    // MARK: - Actions

    private func applySmartSelection() {
        // AI selects only 100% safe to delete items
        let safeIDs = engine.report.items.filter { $0.isSafeToDelete }.map(\.id)
        selectedItemIDs = Set(safeIDs)
    }

    private func executeCleanup() {
        Task {
            let result = await engine.cleanSelectedItems(itemIDs: selectedItemIDs)
            selectedItemIDs.removeAll()
            let formattedFreed = result.freedBytes.formatted(.byteCount(style: .file).locale(locale))
            cleaningSummaryText = "Se liberaron exitosamente \(formattedFreed) de tu Mac (\(result.deletedCount) elementos eliminados)."
            
            NotificationManager.shared.playSuccessSound()
            NotificationManager.shared.showNotification(
                title: "Optimización Completada",
                subtitle: "Veltrix Security",
                body: "Se liberaron exitosamente \(formattedFreed) de tu Mac."
            )
        }
    }

    private func emptyTrashNow() {
        isEmptyingTrash = true
        Task.detached(priority: .userInitiated) {
            let result = TrashService.emptyTrash()
            await MainActor.run {
                isEmptyingTrash = false
                if result.deletedCount > 0 {
                    let bodyStr: String
                    if result.freedBytes > 0 {
                        let freed = result.freedBytes.formatted(.byteCount(style: .file))
                        trashEmptiedText = "Papelera vaciada: \(result.deletedCount) elemento(s) — \(freed) liberados"
                        bodyStr = "\(result.deletedCount) elemento(s) eliminados permanentemente (\(freed))."
                    } else {
                        trashEmptiedText = "Papelera vaciada: \(result.deletedCount) elemento(s)"
                        bodyStr = "\(result.deletedCount) elemento(s) eliminados permanentemente."
                    }
                    NotificationManager.shared.playSuccessSound()
                    NotificationManager.shared.showNotification(
                        title: "Papelera Vaciada",
                        subtitle: "Veltrix Security",
                        body: bodyStr
                    )
                } else {
                    trashEmptiedText = "La papelera ya estaba vacía"
                }
            }
        }
    }
}
