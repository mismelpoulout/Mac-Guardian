import AppKit
import SwiftUI

struct InstalledApplicationsView: View {
    @State private var applications: [InstalledApplication] = []
    @State private var isLoading = false
    @State private var searchText = ""

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
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
            Label("Application removal plans are not available yet. This inventory does not change apps.", systemImage: "info.circle")
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
        applications = await InstalledApplicationScanner().scan()
        isLoading = false
    }
}
