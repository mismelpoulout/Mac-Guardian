import AppKit
import SwiftUI

struct CleanupView: View {
    private let cacheRoot = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Caches", isDirectory: true)

    @State private var model = FolderScanViewModel()
    @State private var pendingItem: ScannedFile?
    @State private var showTrashConfirmation = false
    @State private var alertTitleKey: String?
    @State private var alertMessage = ""
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 7) {
                Text("Cleanup Review").font(.largeTitle.weight(.semibold))
                Text("Review direct items in your user cache. Select an item to move it to Trash; close its app first. Nothing is permanently erased by Mac Guardian.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 760, alignment: .leading)
            }

            HStack(spacing: 12) {
                if model.isScanning {
                    ProgressView("Analyzing user caches…")
                    Text(model.filesScanned.formatted(.number.locale(locale)))
                        .monospacedDigit()
                    Button("Cancel Scan", role: .cancel) { model.cancelScan() }
                } else {
                    Button {
                        scanCaches()
                    } label: {
                        Label("Analyze User Caches", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            if let key = model.errorMessageKey {
                Label(LocalizedStringKey(key), systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }

            if let report = model.report {
                if report.skippedItems > 0 {
                    Label("Some cache items could not be read; the displayed size may be incomplete.", systemImage: "exclamationmark.triangle")
                        .font(.callout)
                        .foregroundStyle(.orange)
                }
                HStack(spacing: 22) {
                    summary("Total allocated", report.totalAllocatedBytes.formatted(.byteCount(style: .file).locale(locale)))
                    summary("Cache items", report.files.count.formatted(.number.locale(locale)))
                    if report.skippedItems > 0 {
                        summary("Items skipped", report.skippedItems.formatted(.number.locale(locale)))
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))

                if report.files.isEmpty {
                    ContentUnavailableView("No cache items found", systemImage: "checkmark.circle")
                } else {
                    List(report.files) { item in
                        HStack(spacing: 12) {
                            Image(systemName: item.url.hasDirectoryPath ? "folder" : "doc")
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.url.lastPathComponent).font(.headline)
                                Text(item.url.path)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            Spacer()
                            Text(item.allocatedBytes.formatted(.byteCount(style: .file).locale(locale)))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                            Button(role: .destructive) {
                                pendingItem = item
                                showTrashConfirmation = true
                            } label: {
                                Label("Move to Trash", systemImage: "trash")
                            }
                            .disabled(model.isScanning)
                        }
                        .padding(.vertical, 3)
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                }
            } else if !model.isScanning {
                ContentUnavailableView(
                    "Analyze your user caches",
                    systemImage: "sparkles",
                    description: Text("Mac Guardian lists cache items and their allocated size before you choose whether to move any item to Trash.")
                )
            }
            Spacer(minLength: 0)
        }
        .padding(30)
        .confirmationDialog("Move selected cache item to Trash?", isPresented: $showTrashConfirmation, titleVisibility: .visible) {
            Button("Move to Trash", role: .destructive) { movePendingItemToTrash() }
            Button("Cancel", role: .cancel) { pendingItem = nil }
        } message: {
            if pendingItem != nil {
                Text("The selected cache item will be moved to Trash. Close its app first; you can restore it from Trash.")
            }
        }
        .alert(LocalizedStringKey(alertTitleKey ?? ""), isPresented: Binding(
            get: { alertTitleKey != nil },
            set: { if !$0 { alertTitleKey = nil } }
        )) {
            Button("OK", role: .cancel) {
                let didMoveItem = alertTitleKey == "Moved to Trash"
                alertTitleKey = nil
                if didMoveItem { scanCaches() }
            }
        } message: {
            Text(alertMessage)
        }
        .task { scanCaches() }
    }

    private func summary(_ title: LocalizedStringKey, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline.monospacedDigit())
        }
    }

    private func scanCaches() {
        model.selectFolder(cacheRoot)
        model.startScan(mode: .folderUsage)
    }

    private func movePendingItemToTrash() {
        guard let pendingItem else { return }
        do {
            try TrashService.moveCacheItemToTrash(pendingItem.url, cacheRoot: cacheRoot)
            alertTitleKey = "Moved to Trash"
            alertMessage = String(localized: "The item was moved to Trash. The cache list will update after you dismiss this message.", locale: locale)
            self.pendingItem = nil
        } catch {
            alertTitleKey = "Could not move item to Trash"
            switch error as? TrashServiceError {
            case .cacheItemOutsideSupportedFolder:
                alertMessage = String(localized: "Only direct items in your user cache can be moved.", locale: locale)
            case .symbolicLinkNotSupported:
                alertMessage = String(localized: "Mac Guardian cannot move symbolic links to Trash.", locale: locale)
            default:
                alertMessage = String(localized: "macOS could not move this item. Check permissions and try again.", locale: locale)
            }
            self.pendingItem = nil
        }
    }
}
