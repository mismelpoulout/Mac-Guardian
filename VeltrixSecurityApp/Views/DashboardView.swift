import SwiftUI

struct DashboardView: View {
    var onSmartScan: () -> Void = {}
    var onNavigateToSecurity: () -> Void = {}
    var onNavigateToAI: () -> Void = {}
    var onNavigateToPerformance: () -> Void = {}
    var onNavigateToPersistence: () -> Void = {}
    @State private var model = DashboardViewModel()
    @State private var showInspectionSheet = false
    @State private var aiEngine = AppleIntelligenceEngine.shared
    @State private var performanceMonitor = PerformanceMonitor.shared
    @State private var isHoveringSmartButton = false
    @State private var executingActionID: UUID? = nil
    @State private var executedActionIDs: Set<UUID> = []
    @Environment(\.locale) private var locale

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header
                smartAnalysisHeroCard
                if let errorMessageKey = model.errorMessageKey {
                    Label {
                        Text(LocalizedStringKey(errorMessageKey))
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                    }
                        .foregroundStyle(.orange)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }
                appleIntelligenceInsightsSection
                if let overview = model.overview {
                    overviewGrid(overview)
                } else if model.isLoading {
                    ProgressView("Leyendo métricas del sistema…")
                        .frame(maxWidth: .infinity, minHeight: 180)
                }
                Text("Las métricas del sistema se obtienen directamente de las APIs locales de macOS.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 720, alignment: .leading)
            }
            .padding(32)
            .frame(maxWidth: 960, alignment: .leading)
        }
        .task {
            await model.refresh()
            _ = await aiEngine.runAnalysis(overview: model.overview)
        }
        .sheet(isPresented: $showInspectionSheet) {
            AutoInspectionSheet(
                onNavigateToCleanup: {
                    showInspectionSheet = false
                    onSmartScan()
                },
                onNavigateToSecurity: {
                    showInspectionSheet = false
                    onNavigateToSecurity()
                }
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("VELTRIX SECURITY")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(.orange)
                Text("Panel de Control")
                    .font(.largeTitle.weight(.semibold))
                Text("Supervisión y optimización avanzada con Apple Intelligence.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                Task {
                    await model.refresh()
                    _ = await aiEngine.runAnalysis(overview: model.overview)
                }
            } label: {
                Label("Actualizar", systemImage: "arrow.clockwise")
            }
            .disabled(model.isLoading || aiEngine.isAnalyzing)
        }
    }

    // MARK: - Hero Smart Analysis Card (Large Round Button)

    private var smartAnalysisHeroCard: some View {
        HStack(spacing: 28) {
            // Left: Information and status
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.purple)
                        Text("Apple Intelligence")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.purple)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(colors: [.purple.opacity(0.18), .blue.opacity(0.14)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        in: Capsule()
                    )

                    if let health = aiEngine.healthScore {
                        Text("\(health.score)% Salud del Mac")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(health.scoreColor.opacity(0.14), in: Capsule())
                            .foregroundStyle(health.scoreColor)
                    }
                }

                Text("Optimización Inteligente On-Device")
                    .font(.title2.weight(.bold))

                Text("Analiza en paralelo cachés de usuario, instaladores residuales de macOS y agentes de inicio potencialmente peligrosos sin tocar archivos del sistema.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 12) {
                    Label("Modelos locales sin subir datos a la nube", systemImage: "lock.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("•")
                        .foregroundStyle(.tertiary)
                    Label("Siri & Atajos integrados", systemImage: "mic.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }

            Spacer()

            // Right: Big Round Smart Analysis Button
            Button {
                showInspectionSheet = true
            } label: {
                ZStack {
                    // Outer glow / pulse ring
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.4), Color.purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 5
                        )
                        .frame(width: 220, height: 220)

                    // Main circular button body
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.orange,
                                    Color(red: 1.0, green: 0.42, blue: 0.12),
                                    Color(red: 0.92, green: 0.24, blue: 0.14)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 200, height: 200)
                        .shadow(color: Color.orange.opacity(0.45), radius: 20, x: 0, y: 12)

                    // Inner decorative light ring
                    Circle()
                        .strokeBorder(Color.white.opacity(0.4), lineWidth: 3)
                        .frame(width: 184, height: 184)

                    // Content
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundStyle(.white)

                        Text("ANÁLISIS\nINTELIGENTE")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .foregroundStyle(.white)
                    }
                }
                .scaleEffect(isHoveringSmartButton ? 1.04 : 1.0)
                .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHoveringSmartButton)
            }
            .buttonStyle(.plain)
            .onHover { isHoveringSmartButton = $0 }
            .help("Iniciar Análisis Inteligente de Veltrix Security")
        }
        .padding(24)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(
                    LinearGradient(colors: [.orange.opacity(0.3), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1.5
                )
        )
    }

    // MARK: - Apple Intelligence Insights

    @ViewBuilder
    private var appleIntelligenceInsightsSection: some View {
        if let health = aiEngine.healthScore, !health.recommendations.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Sugerencias de Apple Intelligence", systemImage: "sparkles")
                        .font(.headline)
                        .foregroundStyle(
                            LinearGradient(colors: [.purple, .orange], startPoint: .leading, endPoint: .trailing)
                        )
                    Spacer()
                    Text(health.statusText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(health.scoreColor)
                }

                ForEach(health.recommendations) { rec in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: rec.systemSymbol)
                                .font(.title3)
                                .foregroundStyle(rec.priority.color)
                                .frame(width: 26)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(rec.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(rec.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Text(rec.priority.label)
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(rec.priority.color.opacity(0.12), in: Capsule())
                                .foregroundStyle(rec.priority.color)
                        }

                        // Action Button
                        if rec.action != .none {
                            HStack {
                                Spacer()
                                if executedActionIDs.contains(rec.id) {
                                    Label("Ejecutado", systemImage: "checkmark.circle.fill")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.green)
                                } else {
                                    Button {
                                        executeRecommendationAction(rec)
                                    } label: {
                                        if executingActionID == rec.id {
                                            HStack(spacing: 6) {
                                                ProgressView().scaleEffect(0.7)
                                                Text("Ejecutando...")
                                            }
                                            .font(.caption.weight(.semibold))
                                        } else {
                                            Label(rec.action.buttonLabel, systemImage: rec.action.buttonIcon)
                                                .font(.caption.weight(.semibold))
                                        }
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(rec.priority.color)
                                    .controlSize(.small)
                                    .disabled(executingActionID != nil)
                                }
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(rec.priority.color.opacity(executedActionIDs.contains(rec.id) ? 0.5 : 0.12), lineWidth: 1)
                    )
                    .animation(.spring(response: 0.3), value: executedActionIDs.contains(rec.id))
                }

                Button(action: onNavigateToAI) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Abrir Centro de Control Apple Intelligence & Siri")
                        Image(systemName: "arrow.right")
                    }
                    .font(.callout.weight(.medium))
                }
                .foregroundStyle(.purple)
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(18)
            .background(
                LinearGradient(colors: [Color.purple.opacity(0.06), Color.blue.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing),
                in: RoundedRectangle(cornerRadius: 16)
            )
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.purple.opacity(0.15)))
        }
    }

    // MARK: - Execute Recommendation Action

    private func executeRecommendationAction(_ rec: AIRecommendation) {
        executingActionID = rec.id

        switch rec.action {
        case .runGlobalScan:
            executingActionID = nil
            executedActionIDs.insert(rec.id)
            showInspectionSheet = true

        case .optimizeRAM:
            Task {
                try? await Task.sleep(nanoseconds: 400_000_000)
                performanceMonitor.optimizeRAM()
                NotificationManager.shared.playSuccessSound()
                NotificationManager.shared.showNotification(
                    title: "RAM Optimizada",
                    subtitle: "Veltrix Security",
                    body: "Los búfers inactivos del kernel han sido purgados."
                )
                executingActionID = nil
                executedActionIDs.insert(rec.id)
                _ = await aiEngine.runAnalysis()
            }

        case .closeHeavyProcesses:
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                let (_ , _) = performanceMonitor.terminateProcesses(performanceMonitor.heavyProcesses)
                executingActionID = nil
                executedActionIDs.insert(rec.id)
                _ = await aiEngine.runAnalysis()
            }

        case .openCacheCleanup:
            executingActionID = nil
            executedActionIDs.insert(rec.id)
            onSmartScan()

        case .openPersistenceAudit:
            executingActionID = nil
            executedActionIDs.insert(rec.id)
            onNavigateToPersistence()

        case .openPerformanceMonitor:
            executingActionID = nil
            executedActionIDs.insert(rec.id)
            onNavigateToPerformance()

        case .openThreatScan:
            executingActionID = nil
            executedActionIDs.insert(rec.id)
            onNavigateToSecurity()

        case .openOSUpdater:
            executingActionID = nil
            executedActionIDs.insert(rec.id)
            // navigate to OS updater - use smart scan
            showInspectionSheet = true

        case .none:
            executingActionID = nil
        }
    }


    // MARK: - System Overview Grid

    private func overviewGrid(_ overview: SystemOverview) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            if let fraction = overview.storageUsageFraction,
               let capacity = overview.capacityBytes,
               let available = overview.availableBytes {
                MetricCard(
                    title: "Almacenamiento de arranque",
                    value: fraction.formatted(.percent.precision(.fractionLength(0)).locale(locale)),
                    detail: "\(formattedBytes(available, style: .file)) disponibles de \(formattedBytes(capacity, style: .file))",
                    symbol: "internaldrive",
                    progress: fraction
                )
            } else {
                MetricCard(title: "Almacenamiento de arranque", value: "No disponible", detail: "macOS no proporcionó métricas de capacidad.", symbol: "internaldrive")
            }
            MetricCard(
                title: "Memoria física (RAM)",
                value: formattedBytes(Int64(clamping: overview.physicalMemoryBytes), style: .memory),
                detail: "Capacidad instalada del sistema",
                symbol: "memorychip"
            )
            MetricCard(
                title: "Volumen de arranque",
                value: overview.volumeName == "Startup Volume"
                    ? String(localized: "Startup Volume", locale: locale)
                    : overview.volumeName,
                detail: "Volumen montado del sistema",
                symbol: "externaldrive"
            )
            MetricCard(
                title: "Tiempo de actividad",
                value: uptimeText(overview.uptime),
                detail: "Desde el último reinicio",
                symbol: "clock"
            )
        }
    }

    private func formattedBytes(_ bytes: Int64, style: ByteCountFormatStyle.Style) -> String {
        bytes.formatted(.byteCount(style: style).locale(locale))
    }

    private func uptimeText(_ interval: TimeInterval) -> String {
        Duration.seconds(Int64(interval))
            .formatted(.units(allowed: [.days, .hours], width: .abbreviated).locale(locale))
    }
}

private struct MetricCard: View {
    let title: LocalizedStringKey
    let value: String
    let detail: LocalizedStringKey
    let symbol: String
    var progress: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.title, design: .rounded, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            if let progress {
                ProgressView(value: progress)
                    .tint(.orange)
            }
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 150, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.primary.opacity(0.06)))
    }
}
