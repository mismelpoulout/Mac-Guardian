import AppKit
import SwiftUI

struct DeveloperStorageView: View {
    @State private var model = DeveloperStorageViewModel()
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Developer Tools").font(.largeTitle.weight(.semibold))
                Text("Measure known Xcode and package-manager folders on this Mac. Nothing is removed.")
                    .foregroundStyle(.secondary)
            }

            HStack {
                if model.isScanning {
                    Button("Cancel Scan", role: .cancel) { model.cancel() }
                    ProgressView()
                    Text(LocalizedStringKey(model.currentLocationKey ?? "Scanning developer storage…"))
                        .foregroundStyle(.secondary)
                } else {
                    Button {
                        model.scan()
                    } label: {
                        Label(model.results.isEmpty ? "Scan Developer Storage" : "Scan Again", systemImage: "magnifyingglass")
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
                if model.filesScanned > 0 {
                    HStack(spacing: 8) {
                        Text("Files examined").foregroundStyle(.secondary)
                        Text(model.filesScanned.formatted(.number.locale(locale)))
                            .font(.callout.monospacedDigit())
                    }
                }
            }

            if let key = model.errorMessageKey {
                Label(LocalizedStringKey(key), systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
            if model.wasCancelled {
                Label("Scan cancelled; completed folders remain listed.", systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)
            }

            if !model.results.isEmpty {
                List(model.results) { result in
                    HStack(spacing: 12) {
                        Image(systemName: "hammer.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedStringKey(result.nameKey)).font(.headline)
                            Text(result.location.path)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        Text(result.allocatedBytes.formatted(.byteCount(style: .file).locale(locale)))
                            .font(.callout.monospacedDigit())
                        Button {
                            NSWorkspace.shared.activateFileViewerSelecting([result.location])
                        } label: {
                            Label("Show in Finder", systemImage: "arrow.up.forward.app")
                        }
                        .labelStyle(.iconOnly)
                        .help("Show in Finder")
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            } else if !model.isScanning {
                ContentUnavailableView(
                    "Developer Scan Ready",
                    systemImage: "hammer",
                    description: Text("Run a local scan to see which supported developer folders exist.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Label("Sizes are measured from files the current user can read. This is an inventory, not a cleanup recommendation.", systemImage: "info.circle")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(30)
    }
}
