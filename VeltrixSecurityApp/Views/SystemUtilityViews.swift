import AppKit
import SwiftUI

struct PrivacyAuditView: View {
    @State private var scanner = PrivacyScanner.shared
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Privacidad y Rastreo").font(.largeTitle.weight(.bold))
                    Text("Audita los permisos de tus apps y el rastro que dejas en el equipo.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    Task { await scanner.scan() }
                } label: {
                    Label("Escanear Privacidad", systemImage: "magnifyingglass")
                }
                .buttonStyle(.borderedProminent)
                .disabled(scanner.isScanning)
            }
            .padding(30)
            
            Picker("", selection: $selectedTab) {
                Text("Permisos de Apps").tag(0)
                Text("Huella de Rastreo").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
            
            if scanner.isScanning {
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Analizando configuraciones de privacidad...")
                        .foregroundStyle(.secondary)
                        .padding(.top, 10)
                    Spacer()
                }
            } else if !scanner.report.isComplete {
                VStack {
                    Spacer()
                    Image(systemName: "lock.shield")
                        .font(.system(size: 64))
                        .foregroundStyle(.blue.opacity(0.8))
                    Text("Listo para auditar")
                        .font(.title2)
                        .padding(.top, 10)
                    Spacer()
                }
            } else {
                if selectedTab == 0 {
                    appPermissionsList
                } else {
                    trackingList
                }
            }
            Spacer()
        }
        .onAppear {
            if !scanner.report.isComplete {
                Task { await scanner.scan() }
            }
        }
    }
    
    private var appPermissionsList: some View {
        List(scanner.report.appsWithPermissions) { app in
            HStack(spacing: 16) {
                Image(systemName: "app.dashed")
                    .font(.title)
                    .foregroundStyle(.blue)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.appName).font(.headline)
                    Text(app.bundleIdentifier)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(app.permissions) { perm in
                                Label(perm.category.rawValue, systemImage: perm.category.systemSymbol)
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                                    .help(perm.usageDescription)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var trackingList: some View {
        List(scanner.report.trackingItems) { item in
            HStack {
                Image(systemName: item.itemType.systemSymbol)
                    .font(.title2)
                    .foregroundStyle(.orange)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName).font(.headline)
                    Text(item.reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(item.allocatedBytes.formatted(.byteCount(style: .file)))
                    .font(.subheadline.monospacedDigit())
            }
            .padding(.vertical, 8)
        }
    }
}

struct PerformanceView: View {
    @State private var monitor = PerformanceMonitor.shared
    @State private var selectedProcess: ProcessItem? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Rendimiento del Sistema").font(.largeTitle.weight(.bold))
                    Text("Monitor en tiempo real de CPU y Memoria RAM")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    monitor.optimizeRAM()
                } label: {
                    Label("Optimizar RAM", systemImage: "memorychip")
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
            .padding(30)

            if let msg = monitor.optimizationStatusMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(msg)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                .padding(.bottom, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            HStack(spacing: 30) {
                // CPU Gauge
                VStack {
                    Text("CPU")
                        .font(.headline)
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                        Circle()
                            .trim(from: 0, to: CGFloat(monitor.cpuInfo.totalUsedPercent / 100))
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(Int(monitor.cpuInfo.totalUsedPercent))%")
                            .font(.title.bold())
                    }
                    .frame(width: 120, height: 120)
                    .padding()
                }

                // RAM Gauge
                VStack {
                    Text("Memoria RAM")
                        .font(.headline)
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                        Circle()
                            .trim(from: 0, to: CGFloat(monitor.memoryInfo.usedFraction))
                            .stroke(monitor.memoryInfo.pressureState == .critical ? Color.red : (monitor.memoryInfo.pressureState == .warning ? Color.orange : Color.green), style: StrokeStyle(lineWidth: 15, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack {
                            Text("\(Int(monitor.memoryInfo.usedFraction * 100))%")
                                .font(.title.bold())
                            Text(monitor.memoryInfo.pressureState.rawValue)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 120, height: 120)
                    .padding()
                }
            }
            .padding(.bottom, 16)

            // MARK: - Apple Intelligence Smart RAM Suggestion Banner
            if monitor.isHighMemoryPressure && !monitor.heavyProcesses.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.purple)
                            Text("SUGERENCIA DE APPLE INTELLIGENCE")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.purple)
                                .tracking(1)
                        }

                        Spacer()

                        Text("Presión \(monitor.memoryInfo.pressureState.rawValue)")
                            .font(.caption2.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                monitor.memoryInfo.pressureState == .critical ? Color.red.opacity(0.15) : Color.orange.opacity(0.15),
                                in: Capsule()
                            )
                            .foregroundStyle(monitor.memoryInfo.pressureState == .critical ? .red : .orange)
                    }

                    Text("Memoria sobrecargada: Cierra aplicaciones para liberar RAM")
                        .font(.headline.weight(.semibold))

                    let totalHeavyMemory = monitor.heavyProcesses.reduce(Int64(0)) { $0 + $1.memoryBytes }
                    Text("La memoria RAM está al \(Int(monitor.memoryInfo.usedFraction * 100))% de uso. Cerrar las aplicaciones de mayor consumo puede liberar hasta \(totalHeavyMemory.formatted(.byteCount(style: .memory))) inmediatamente.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Suggested heavy apps to close
                    VStack(spacing: 6) {
                        ForEach(monitor.heavyProcesses.prefix(4)) { process in
                            HStack(spacing: 10) {
                                if let path = process.iconPath, FileManager.default.fileExists(atPath: path) {
                                    Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                                        .resizable()
                                        .frame(width: 22, height: 22)
                                } else {
                                    Image(systemName: "app.fill")
                                        .foregroundStyle(.blue)
                                        .frame(width: 22, height: 22)
                                }

                                Text(process.name)
                                    .font(.subheadline.weight(.medium))

                                Spacer()

                                Text(process.memoryBytes.formatted(.byteCount(style: .memory)))
                                    .font(.caption.weight(.semibold).monospacedDigit())
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(Color.red.opacity(0.12), in: Capsule())
                                    .foregroundStyle(.red)

                                Button {
                                    _ = monitor.terminateProcess(item: process)
                                } label: {
                                    Text("Cerrar")
                                        .font(.caption.weight(.semibold))
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                        }
                    }

                    HStack {
                        Spacer()
                        Button {
                            _ = monitor.terminateProcesses(monitor.heavyProcesses)
                        } label: {
                            Label("Cerrar aplicaciones pesadas (\(monitor.heavyProcesses.count)) y purgar", systemImage: "xmark.app.fill")
                                .font(.caption.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                    }
                }
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.12), Color.orange.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            LinearGradient(colors: [Color.purple.opacity(0.4), Color.orange.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.5
                        )
                )
                .padding(.horizontal, 30)
                .padding(.bottom, 14)
            }

            Divider()

            List(monitor.topProcesses) { process in
                HStack(spacing: 12) {
                    if let path = process.iconPath, FileManager.default.fileExists(atPath: path) {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: path))
                            .resizable()
                            .frame(width: 26, height: 26)
                    } else {
                        Image(systemName: "app.fill")
                            .foregroundStyle(.blue)
                            .frame(width: 26, height: 26)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(process.name).font(.headline)
                            if monitor.heavyProcesses.contains(where: { $0.id == process.id }) {
                                Text("Alto consumo")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(Color.orange.opacity(0.15), in: Capsule())
                                    .foregroundStyle(.orange)
                            }
                        }
                        Text("PID: \(process.id)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(process.memoryBytes.formatted(.byteCount(style: .memory)))
                        .font(.subheadline.monospacedDigit())
                        .frame(width: 100, alignment: .trailing)

                    if process.isTerminatable {
                        Button {
                            _ = monitor.terminateProcess(item: process)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                        .help("Cerrar proceso")
                    }
                }
                .padding(.vertical, 4)
            }

            Spacer()
        }
        .onAppear {
            monitor.startMonitoring()
        }
        .onDisappear {
            monitor.stopMonitoring()
        }
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

import Foundation
import AppKit

// MARK: - Privacy Permission Types

