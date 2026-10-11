import SwiftUI
import AppKit

// MARK: - ThreatScanView

struct ThreatScanView: View {
    @State private var report: ThreatScanReport?
    @State private var isScanning = false
    @State private var selectedRisk: ThreatRisk? = nil
    @State private var selectedThreatIDs: Set<String> = []
    @State private var expandedThreatID: String? = nil
    @State private var alertTitleKey: String?
    @State private var alertMessage = ""
    @State private var engine = AppleIntelligenceEngine.shared
    @Environment(\.locale) private var locale

    private var displayedItems: [ThreatItem] {
        guard let report else { return [] }
        if let filter = selectedRisk {
            return report.items.filter { $0.risk == filter }
        }
        return report.items
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            filterBar
            content
            Spacer(minLength: 0)
        }
        .padding(30)
        .task { await runScan() }
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
                HStack(spacing: 8) {
                    Text("Análisis de Amenazas")
                        .font(.largeTitle.weight(.semibold))
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.purple)
                        Text("Apple Intelligence Heuristics")
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

                Text("Inspecciona agentes de inicio, scripts sospechosos y configuraciones de persistencia analizadas semánticamente por Apple Intelligence.")
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
                    Label("Analizar", systemImage: "arrow.clockwise")
                }
                .disabled(isScanning)
            }
        }
    }

    private var filterBar: some View {
        HStack(spacing: 10) {
            filterChip(label: "Todos", risk: nil, count: report?.items.count ?? 0)
            filterChip(label: "Alto riesgo", risk: .high, count: report?.highRiskCount ?? 0)
            filterChip(label: "Riesgo medio", risk: .medium, count: report?.mediumRiskCount ?? 0)
            filterChip(label: "Bajo riesgo", risk: .low, count: report?.items.filter { $0.risk == .low }.count ?? 0)
        }
    }

    @ViewBuilder
    private var content: some View {
        if isScanning {
            ProgressView("Analizando agentes de inicio y scripts con Apple Intelligence…")
                .frame(maxWidth: .infinity, minHeight: 180)
        } else if let report {
            if report.isEmpty {
                ContentUnavailableView(
                    "Sin amenazas detectadas",
                    systemImage: "checkmark.shield.fill",
                    description: Text("Apple Intelligence no encontró scripts maliciosos ni elementos sospechosos en las rutas de inicio.")
                )
            } else {
                multiSelectionToolbar

                List(displayedItems) { item in
                    threatRow(item)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))

                if report.skippedItems > 0 {
                    Label("No se pudieron leer \(report.skippedItems) elemento(s). El análisis puede estar incompleto.", systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .foregroundStyle(.orange)
                }
                Label("Apple Intelligence no modifica archivos sin tu consentimiento explícito.", systemImage: "info.circle")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        } else {
            ContentUnavailableView("Ejecuta el análisis", systemImage: "shield.lefthalf.filled",
                description: Text("Pulsa Analizar para inspeccionar los agentes de inicio y rutas del sistema."))
        }
    }

    private var multiSelectionToolbar: some View {
        HStack(spacing: 14) {
            Button {
                if selectedThreatIDs.count == displayedItems.count {
                    selectedThreatIDs.removeAll()
                } else {
                    selectedThreatIDs = Set(displayedItems.map(\.id))
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selectedThreatIDs.count == displayedItems.count && !displayedItems.isEmpty ? "checkmark.circle.fill" : (selectedThreatIDs.isEmpty ? "circle" : "minus.circle.fill"))
                        .foregroundStyle(selectedThreatIDs.isEmpty ? .secondary : Color.orange)
                    Text(selectedThreatIDs.count == displayedItems.count && !displayedItems.isEmpty ? "Deseleccionar todos" : "Seleccionar todos")
                }
            }
            .buttonStyle(.bordered)

            if !selectedThreatIDs.isEmpty {
                Text("\(selectedThreatIDs.count) seleccionado(s)")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.12), in: Capsule())

                Spacer()

                Button {
                    showSelectedInFinder()
                } label: {
                    Label("Mostrar en Finder", systemImage: "arrow.up.forward.app")
                }
                .buttonStyle(.bordered)

                Button {
                    copySelectedPaths()
                } label: {
                    Label("Copiar rutas", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
            } else {
                Spacer()
                Text("Toca «Análisis IA» en cada ítem para ver el veredicto")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }

    private func filterChip(label: String, risk: ThreatRisk?, count: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedRisk = risk
                selectedThreatIDs.removeAll()
            }
        } label: {
            HStack(spacing: 5) {
                Text(label)
                if count > 0 {
                    Text("\(count)")
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(.primary.opacity(0.12), in: Capsule())
                }
            }
            .font(.callout.weight(selectedRisk == risk ? .semibold : .regular))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(selectedRisk == risk ? Color.accentColor.opacity(0.15) : Color.clear,
                        in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func threatRow(_ item: ThreatItem) -> some View {
        let isExpanded = expandedThreatID == item.id
        let aiAnalysis = engine.analyzeThreatWithAI(item: item)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Button {
                    toggleSelection(item.id)
                } label: {
                    Image(systemName: selectedThreatIDs.contains(item.id) ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(selectedThreatIDs.contains(item.id) ? Color.orange : Color.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)

                Image(systemName: item.risk.systemSymbol)
                    .font(.title3)
                    .foregroundStyle(item.risk == .high ? .red : item.risk == .medium ? .orange : .green)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.displayName)
                        .font(.headline)
                    Text(item.reason)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(item.url.path)
                        .font(.caption.monospaced())
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                Spacer()

                riskBadge(item.risk)

                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        expandedThreatID = isExpanded ? nil : item.id
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text(isExpanded ? "Ocultar IA" : "Veredicto IA")
                    }
                    .font(.caption.weight(.medium))
                }
                .buttonStyle(.bordered)
                .tint(.purple)

                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([item.url])
                } label: {
                    Label("Mostrar en Finder", systemImage: "arrow.up.forward.app")
                }
                .labelStyle(.iconOnly)
                .help("Mostrar en Finder")
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .foregroundStyle(.purple)
                        Text("Evaluación de Apple Intelligence")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.purple)
                        Spacer()
                        Text("Peligro estimado: \(aiAnalysis.safetyScore)/10")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(aiAnalysis.safetyScore > 6 ? .red : .orange)
                    }

                    Text(aiAnalysis.explanation)
                        .font(.caption)
                    Text("• Impacto potencial: " + aiAnalysis.potentialImpact)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("• Recomendación: " + aiAnalysis.recommendedAction)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.primary)
                }
                .padding(10)
                .background(Color.purple.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.purple.opacity(0.2)))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 6)
    }

    private func toggleSelection(_ id: String) {
        if selectedThreatIDs.contains(id) {
            selectedThreatIDs.remove(id)
        } else {
            selectedThreatIDs.insert(id)
        }
    }

    private func showSelectedInFinder() {
        guard let report else { return }
        let urls = report.items.filter { selectedThreatIDs.contains($0.id) }.map(\.url)
        if !urls.isEmpty {
            NSWorkspace.shared.activateFileViewerSelecting(urls)
        }
    }

    private func copySelectedPaths() {
        guard let report else { return }
        let paths = report.items.filter { selectedThreatIDs.contains($0.id) }.map { $0.url.path }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(paths, forType: .string)
        alertTitleKey = "Rutas copiadas"
        alertMessage = "Se copiaron \(selectedThreatIDs.count) ruta(s) al portapapeles."
    }

    private func riskBadge(_ risk: ThreatRisk) -> some View {
        let color: Color = risk == .high ? .red : risk == .medium ? .orange : .green
        return Text(risk.label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
    }

    @MainActor
    private func runScan() async {
        guard !isScanning else { return }
        isScanning = true
        selectedThreatIDs.removeAll()
        report = await ThreatScanner().scan()
        isScanning = false
    }
}
