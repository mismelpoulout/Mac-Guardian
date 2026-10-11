import SwiftUI
import AppKit

struct AppleIntelligenceView: View {
    var onNavigateToPerformance: () -> Void = {}
    var onNavigateToCleanup: () -> Void = {}
    var onNavigateToSecurity: () -> Void = {}

    @State private var engine = AppleIntelligenceEngine.shared
    @State private var selectedTab = 0
    @State private var lastSiriResponse: String?
    @State private var executingCommandId: String?
    @State private var enableAutoAlerts = true
    @State private var enableVoiceFeedback = true
    @State private var enableAgentMonitoring = true
    @State private var executingActionID: UUID?
    @State private var executedActionIDs: Set<UUID> = []
    @Environment(\.locale) private var locale

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                aiHealthCard
                siriCommandsConsole
                smartRulesSection
            }
            .padding(30)
            .frame(maxWidth: 960, alignment: .leading)
        }
        .task {
            _ = await engine.runAnalysis()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.headline)
                        .foregroundStyle(.purple)
                    Text("Apple Intelligence & Siri")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(
                            LinearGradient(colors: [.purple, .indigo, .blue], startPoint: .leading, endPoint: .trailing)
                        )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    LinearGradient(colors: [.purple.opacity(0.16), .blue.opacity(0.12)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: Capsule()
                )

                Spacer()

                Label("Procesamiento 100% On-Device", systemImage: "lock.shield.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text("Inteligencia del Sistema y Asistente Siri")
                .font(.largeTitle.weight(.semibold))

            Text("Veltrix Security aprovecha modelos heurísticos locales y los App Intents de macOS e iOS para optimizar tu almacenamiento y responder a órdenes de voz con Siri.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: 750, alignment: .leading)
        }
    }

    // MARK: - AI Health Card

    private var aiHealthCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("DIAGNÓSTICO EN TIEMPO REAL")
                        .font(.caption.weight(.bold))
                        .tracking(1.5)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        if let health = engine.healthScore {
                            Text("\(health.score)%")
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundStyle(health.scoreColor)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(health.statusText)
                                    .font(.headline.weight(.semibold))
                                Text("Evaluado según presión de RAM, espacio libre y cachés inactivas.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ProgressView()
                            Text("Evaluando estado con Apple Intelligence…")
                                .font(.headline)
                        }
                    }
                }

                Spacer()

                Button {
                    Task { _ = await engine.runAnalysis() }
                } label: {
                    Label("Reevaluar", systemImage: "arrow.clockwise")
                }
                .disabled(engine.isAnalyzing)
            }

            if let health = engine.healthScore, !health.recommendations.isEmpty {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recomendaciones activas:")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ForEach(health.recommendations) { rec in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                Image(systemName: rec.systemSymbol)
                                    .font(.callout)
                                    .foregroundStyle(rec.priority.color)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(rec.title)
                                        .font(.subheadline.weight(.medium))
                                    Text(rec.detail)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(rec.priority.label)
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(rec.priority.color.opacity(0.12), in: Capsule())
                                    .foregroundStyle(rec.priority.color)
                            }

                            if rec.action != .none {
                                HStack {
                                    Spacer()
                                    if executedActionIDs.contains(rec.id) {
                                        Label("Ejecutado", systemImage: "checkmark.circle.fill")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.green)
                                    } else {
                                        Button {
                                            executeRecommendation(rec)
                                        } label: {
                                            if executingActionID == rec.id {
                                                HStack(spacing: 4) {
                                                    ProgressView().scaleEffect(0.6)
                                                    Text("Ejecutando...")
                                                }
                                                .font(.caption2.weight(.semibold))
                                            } else {
                                                Label(rec.action.buttonLabel, systemImage: rec.action.buttonIcon)
                                                    .font(.caption2.weight(.semibold))
                                            }
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(rec.priority == .high ? .red : .purple)
                                        .controlSize(.small)
                                        .disabled(executingActionID != nil)
                                    }
                                }
                            }
                        }
                        .padding(10)
                        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .padding(20)
        .background(
            LinearGradient(colors: [Color.purple.opacity(0.08), Color.blue.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.purple.opacity(0.2)))
    }

    private func executeRecommendation(_ rec: AIRecommendation) {
        executingActionID = rec.id

        switch rec.action {
        case .closeHeavyProcesses:
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                let monitor = PerformanceMonitor.shared
                _ = monitor.terminateProcesses(monitor.heavyProcesses)
                executingActionID = nil
                executedActionIDs.insert(rec.id)
                _ = await engine.runAnalysis()
            }

        case .optimizeRAM:
            Task {
                try? await Task.sleep(nanoseconds: 300_000_000)
                PerformanceMonitor.shared.optimizeRAM()
                NotificationManager.shared.playSuccessSound()
                NotificationManager.shared.showNotification(
                    title: "RAM Optimizada",
                    subtitle: "Veltrix Security",
                    body: "Búferes de memoria purgados por Apple Intelligence."
                )
                executingActionID = nil
                executedActionIDs.insert(rec.id)
                _ = await engine.runAnalysis()
            }

        case .openPerformanceMonitor:
            executingActionID = nil
            executedActionIDs.insert(rec.id)
            onNavigateToPerformance()

        case .runGlobalScan, .openCacheCleanup, .openOSUpdater:
            executingActionID = nil
            executedActionIDs.insert(rec.id)
            onNavigateToCleanup()

        case .openPersistenceAudit, .openThreatScan:
            executingActionID = nil
            executedActionIDs.insert(rec.id)
            onNavigateToSecurity()

        case .none:
            executingActionID = nil
        }
    }

    // MARK: - Siri Commands Console

    private var siriCommandsConsole: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .foregroundStyle(.purple)
                        Text("Consola de Comandos de Siri")
                            .font(.title3.weight(.bold))
                    }
                    Text("Pide cualquiera de estas órdenes a Siri desde tu Mac, iPhone o iPad vinculado.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if engine.isSpeaking {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform")
                            .symbolEffect(.variableColor.iterative)
                            .foregroundStyle(.purple)
                        Text("Siri hablando…")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.purple)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.purple.opacity(0.12), in: Capsule())
                }
            }

            // Siri live feedback banner
            if let response = lastSiriResponse {
                HStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Respuesta de Siri:")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.purple)
                        Text(response)
                            .font(.subheadline)
                    }
                    Spacer()
                    Button {
                        lastSiriResponse = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(14)
                .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.purple.opacity(0.25)))
            }

            // Command cards
            VStack(spacing: 10) {
                ForEach(engine.availableSiriCommands) { cmd in
                    commandRow(cmd)
                }
            }
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.primary.opacity(0.06)))
    }

    private func commandRow(_ cmd: SiriCommandItem) -> some View {
        HStack(spacing: 14) {
            Image(systemName: cmd.systemSymbol)
                .font(.title3)
                .foregroundStyle(
                    LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(cmd.triggerPhrase)
                    .font(.subheadline.weight(.bold))
                Text(cmd.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                executeSiriTest(cmd)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "play.fill")
                    Text("Probar voz y acción")
                }
                .font(.caption.weight(.medium))
            }
            .buttonStyle(.bordered)
            .tint(.purple)
            .disabled(executingCommandId == cmd.id)
        }
        .padding(12)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
    }

    private func executeSiriTest(_ cmd: SiriCommandItem) {
        executingCommandId = cmd.id
        lastSiriResponse = cmd.responseSnippet

        if enableVoiceFeedback {
            engine.speakSiriResponse(cmd.responseSnippet)
        }

        Task {
            switch cmd.id {
            case "scan":
                _ = await engine.runAnalysis()
            case "clean":
                engine.recordOptimizationComplete()
            case "health":
                _ = await engine.runAnalysis()
            case "threats":
                _ = await ThreatScanner().scan()
            default:
                break
            }
            try? await Task.sleep(nanoseconds: 800_000_000)
            executingCommandId = nil
        }
    }

    // MARK: - Smart Rules Section

    private var smartRulesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Ajustes Inteligentes de Apple Intelligence", systemImage: "slider.horizontal.3")
                .font(.headline)

            VStack(spacing: 10) {
                Toggle(isOn: $enableAutoAlerts) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Alertas predictivas de espacio crítico")
                            .font(.subheadline.weight(.medium))
                        Text("Apple Intelligence avisará antes de que el disco alcance el 85% para evitar congelamientos.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                Toggle(isOn: $enableAgentMonitoring) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Supervisión heurística de nuevos agentes de arranque")
                            .font(.subheadline.weight(.medium))
                        Text("Examina en segundo plano cualquier script que se agregue a LaunchAgents.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Divider()

                Toggle(isOn: $enableVoiceFeedback) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Respuestas audibles de Siri en pruebas")
                            .font(.subheadline.weight(.medium))
                        Text("Emite la confirmación por voz del sistema al probar comandos interactivos.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        }
    }
}
