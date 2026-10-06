import AppKit
import SwiftUI

struct InstalledApplicationsView: View {
    @State private var applications: [InstalledApplication] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var pendingUninstall: InstalledApplication?
    @State private var showUninstallConfirmation = false
    @State private var alertTitleKey: String?
    @State private var alertMessage = ""

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
                    Text("Applications").font(.largeTitle.weight(.semibold))
                    Text("Installed apps found in the Applications folders for this Mac and your account.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    Task { await refresh() }
                } label: {
                    Label("Refresh Applications", systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
            TextField("Search applications", text: $searchText)
                .textFieldStyle(.roundedBorder)

            if isLoading {
                ProgressView("Reading applications…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if applications.isEmpty {
                ContentUnavailableView("No applications found", systemImage: "app.dashed")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(visibleApplications) { app in
                    HStack(spacing: 12) {
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
                            Label("Open Application", systemImage: "play.fill")
                        }
                        .labelStyle(.iconOnly)
                        .help("Open Application")
                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([app.location])
                        } label: {
                            Label("Show in Finder", systemImage: "arrow.up.forward.app")
                        }
                        .labelStyle(.iconOnly)
                        .help("Show in Finder")
                        if TrashService.canMoveAppToTrash(app.location) {
                            Button(role: .destructive) {
                                pendingUninstall = app
                                showUninstallConfirmation = true
                            } label: {
                                Label("Move Application to Trash", systemImage: "trash")
                            }
                            .labelStyle(.iconOnly)
                            .help("Move Application to Trash")
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
            Label("Uninstall moves only the selected app bundle to Trash. Related support files are left untouched.", systemImage: "info.circle")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(30)
        .task { await refresh() }
        .confirmationDialog("Move this application to Trash?", isPresented: $showUninstallConfirmation, titleVisibility: .visible) {
            Button("Move Application to Trash", role: .destructive) { movePendingAppToTrash() }
            Button("Cancel", role: .cancel) { pendingUninstall = nil }
        } message: {
            if pendingUninstall != nil {
                Text("This app bundle will be moved to Trash. Its support files and documents will remain in place.")
            }
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

    @MainActor
    private func refresh() async {
        guard !isLoading else { return }
        isLoading = true
        applications = await InstalledApplicationScanner().scan()
        isLoading = false
    }

    private func movePendingAppToTrash() {
        guard let pendingUninstall else { return }
        do {
            try TrashService.moveAppToTrash(pendingUninstall.location)
            alertTitleKey = "Application moved to Trash"
            alertMessage = String(localized: "The app bundle was moved to Trash. Related support files were left untouched.")
            applications.removeAll { $0.id == pendingUninstall.id }
            self.pendingUninstall = nil
        } catch {
            alertTitleKey = "Could not move application to Trash"
            alertMessage = error.localizedDescription
            self.pendingUninstall = nil
        }
    }
}
