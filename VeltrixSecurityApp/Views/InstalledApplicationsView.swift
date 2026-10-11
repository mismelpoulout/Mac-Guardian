import AppKit
import SwiftUI

struct InstalledApplicationsView: View {
    @State private var applications: [InstalledApplication] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var selectedAppIDs: Set<String> = []
    @State private var pendingUninstall: InstalledApplication?
    @State private var showUninstallConfirmation = false
    @State private var showBatchUninstallConfirmation = false
    @State private var alertTitleKey: String?
    @State private var alertMessage = ""
    @Environment(\.locale) private var locale

    private var visibleApplications: [InstalledApplication] {
        guard !searchText.isEmpty else { return applications }
        return applications.filter {
            $0.name.localizedStandardContains(searchText)
                || $0.bundleIdentifier.localizedStandardContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Aplicaciones").font(.largeTitle.weight(.semibold))
                    Text("Aplicaciones instaladas en las carpetas /Applications y de tu usuario. Usa los checks para seleccionar y desinstalar múltiples apps en lote.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    Task { await refresh() }
                } label: {
                    Label("Actualizar lista", systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
            TextField("Buscar aplicaciones…", text: $searchText)
                .textFieldStyle(.roundedBorder)

            if isLoading {
                ProgressView("Leyendo aplicaciones…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if applications.isEmpty {
                ContentUnavailableView("No se encontraron aplicaciones", systemImage: "app.dashed")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if visibleApplications.isEmpty {
                ContentUnavailableView("Sin coincidencias", systemImage: "magnifyingglass")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                multiSelectionToolbar

                List(visibleApplications) { app in
                    HStack(spacing: 12) {
                        if TrashService.canMoveAppToTrash(app.location) {
                            Button {
                                toggleSelection(app.id)
                            } label: {
                                Image(systemName: selectedAppIDs.contains(app.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(selectedAppIDs.contains(app.id) ? Color.orange : Color.secondary.opacity(0.6))
                            }
                            .buttonStyle(.plain)
                            .help("Seleccionar para desinstalar")
                        } else {
                            Image(systemName: "lock.shield")
                                .foregroundStyle(.tertiary)
                                .help("Aplicación del sistema protegida")
                        }

                        Image(nsImage: NSWorkspace.shared.icon(forFile: app.location.path))
                            .resizable()
                            .frame(width: 36, height: 36)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(app.name).font(.headline)
                            Text(app.bundleIdentifier.isEmpty ? app.location.path : app.bundleIdentifier)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        Text(app.version)
                            .font(.callout.monospacedDigit())
                            .foregroundStyle(.secondary)

                        Button {
                            NSWorkspace.shared.open(app.location)
                        } label: {
                            Label("Abrir", systemImage: "play.fill")
                        }
                        .labelStyle(.iconOnly)
                        .help("Abrir aplicación")

                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([app.location])
                        } label: {
                            Label("Mostrar en Finder", systemImage: "arrow.up.forward.app")
                        }
                        .labelStyle(.iconOnly)
                        .help("Mostrar en Finder")

                        if TrashService.canMoveAppToTrash(app.location) {
                            Button(role: .destructive) {
                                pendingUninstall = app
                                showUninstallConfirmation = true
                            } label: {
                                Label("Mover a Papelera", systemImage: "trash")
                            }
                            .labelStyle(.iconOnly)
                            .help("Mover a la Papelera")
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }

            Label("Desinstalar mueve los paquetes .app seleccionados a la Papelera. Los archivos de soporte del sistema permanecen intactos.", systemImage: "info.circle")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(30)
        .task { await refresh() }
        .confirmationDialog("¿Mover esta aplicación a la Papelera?", isPresented: $showUninstallConfirmation, titleVisibility: .visible) {
            Button("Mover a la Papelera", role: .destructive) { movePendingAppToTrash() }
            Button("Cancelar", role: .cancel) { pendingUninstall = nil }
        } message: {
            if pendingUninstall != nil {
                Text("El paquete de la aplicación se moverá a la Papelera de tu Mac.")
            }
        }
        .confirmationDialog("¿Mover las \(selectedAppIDs.count) aplicaciones seleccionadas a la Papelera?", isPresented: $showBatchUninstallConfirmation, titleVisibility: .visible) {
            Button("Mover seleccionadas a la Papelera", role: .destructive) { moveSelectedAppsToTrash() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Se moverán \(selectedAppIDs.count) paquetes de aplicación a la Papelera de tu Mac.")
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

    // MARK: - Toolbar

    private var eligibleApps: [InstalledApplication] {
        visibleApplications.filter { TrashService.canMoveAppToTrash($0.location) }
    }

    private var multiSelectionToolbar: some View {
        HStack(spacing: 14) {
            Button {
                if selectedAppIDs.count == eligibleApps.count {
                    selectedAppIDs.removeAll()
                } else {
                    selectedAppIDs = Set(eligibleApps.map(\.id))
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selectedAppIDs.count == eligibleApps.count && !eligibleApps.isEmpty ? "checkmark.circle.fill" : (selectedAppIDs.isEmpty ? "circle" : "minus.circle.fill"))
                        .foregroundStyle(selectedAppIDs.isEmpty ? .secondary : Color.orange)
                    Text(selectedAppIDs.count == eligibleApps.count && !eligibleApps.isEmpty ? "Deseleccionar todas" : "Seleccionar todas")
                }
            }
            .buttonStyle(.bordered)

            if !selectedAppIDs.isEmpty {
                Text("\(selectedAppIDs.count) seleccionada(s)")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.12), in: Capsule())

                Spacer()

                Button(role: .destructive) {
                    showBatchUninstallConfirmation = true
                } label: {
                    Label("Desinstalar seleccionadas", systemImage: "trash.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            } else {
                Spacer()
                Text("Marca las casillas para desinstalar múltiples apps en lote")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }

    private func toggleSelection(_ id: String) {
        if selectedAppIDs.contains(id) {
            selectedAppIDs.remove(id)
        } else {
            selectedAppIDs.insert(id)
        }
    }

    @MainActor
    private func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        selectedAppIDs.removeAll()
        applications = await InstalledApplicationScanner().scan()
        isLoading = false
    }

    private func movePendingAppToTrash() {
        guard let pendingUninstall else { return }
        do {
            try TrashService.moveAppToTrash(pendingUninstall.location)
            alertTitleKey = "Aplicación movida a la Papelera"
            alertMessage = "El paquete de la aplicación fue movido a la Papelera."
            applications.removeAll { $0.id == pendingUninstall.id }
            selectedAppIDs.remove(pendingUninstall.id)
            self.pendingUninstall = nil
        } catch {
            handleError(error)
            self.pendingUninstall = nil
        }
    }

    private func moveSelectedAppsToTrash() {
        let appsToMove = applications.filter { selectedAppIDs.contains($0.id) }
        var moved = 0
        var failed = 0

        for app in appsToMove {
            do {
                try TrashService.moveAppToTrash(app.location)
                applications.removeAll { $0.id == app.id }
                moved += 1
            } catch {
                failed += 1
            }
        }

        selectedAppIDs.removeAll()
        alertTitleKey = "Desinstalación en lote"
        if failed == 0 {
            alertMessage = "Se movieron \(moved) aplicaciones a la Papelera."
        } else {
            alertMessage = "Se movieron \(moved) aplicaciones a la Papelera. \(failed) no pudieron moverse (posiblemente estén en ejecución o protegidas)."
        }
    }

    private func handleError(_ error: Error) {
        switch error as? TrashServiceError {
        case .appIsRunning:
            alertTitleKey = "Cierra la aplicación primero"
            alertMessage = "Esta aplicación está abierta en este momento. Ciérrala e inténtalo de nuevo."
        case .appOutsideSupportedFolder:
            alertTitleKey = "No se puede mover la aplicación"
            alertMessage = "Solo las apps directamente dentro de /Applications o ~/Applications pueden moverse."
        case .symbolicLinkNotSupported:
            alertTitleKey = "No se puede mover la aplicación"
            alertMessage = "Veltrix Security no admite mover enlaces simbólicos a la Papelera."
        default:
            alertTitleKey = "No se pudo mover la aplicación"
            alertMessage = "macOS no pudo mover este ítem. Comprueba permisos y vuelve a intentar."
        }
    }
}
