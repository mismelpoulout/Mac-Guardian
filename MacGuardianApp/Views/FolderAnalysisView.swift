import AppKit
import SwiftUI

struct FolderAnalysisView: View {
    let mode: FolderScanMode
    var title: LocalizedStringKey? = nil
    var explanation: LocalizedStringKey? = nil
    var actionTitle: LocalizedStringKey = "Analyze Folder"
    var initialFolder: URL? = nil
    var autoStartInitialFolder = false
    @State private var model = FolderScanViewModel()
    @State private var searchText = ""
    @State private var didApplyInitialFolder = false
    @Environment(\.locale) private var locale

    private var isLargeFilesMode: Bool {
        if case .largeFiles = mode { return true }
        return false
    }

    private var visibleFiles: [ScannedFile] {
        guard let report = model.report else { return [] }
        guard !searchText.isEmpty else { return report.files }
        return report.files.filter { $0.url.lastPathComponent.localizedStandardContains(searchText) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                controls

                if let key = model.errorMessageKey {
                    Label(LocalizedStringKey(key), systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
                if model.wasCancelled {
                    Label("Scan cancelled. No files were changed.", systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
                }
                if model.isScanning {
                    VStack(alignment: .leading, spacing: 10) {
                        ProgressView()
                        Label("Files examined", systemImage: "doc")
                            .foregroundStyle(.secondary)
                        Text(model.filesScanned.formatted(.number.locale(locale)))
                            .font(.title2.monospacedDigit())
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
                }
                if let report = model.report {
                    reportSummary(report)
                    if !report.files.isEmpty {
                        TextField("Filter files", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                        LazyVStack(spacing: 8) {
                            ForEach(visibleFiles) { file in
                                fileRow(file)
                            }
                        }
                    } else {
                        ContentUnavailableView(
                            "No matching files found",
                            systemImage: "doc.questionmark",
                            description: Text(isLargeFilesMode ? "No files met the large-file size threshold." : "This folder contains no readable files.")
                        )
                    }
                } else if !model.isScanning {
                    ContentUnavailableView(
                        "Choose a folder to begin",
                        systemImage: "folder.badge.questionmark",
                        description: Text("Mac Guardian reads the selected folder and does not change its contents.")
                    )
                    .frame(maxWidth: .infinity, minHeight: 220)
                }
            }
            .padding(30)
                .frame(maxWidth: 1000, alignment: .leading)
        }
        .task {
            guard !didApplyInitialFolder, let initialFolder else { return }
            didApplyInitialFolder = true
            model.selectFolder(initialFolder)
            if autoStartInitialFolder {
                model.startScan(mode: mode)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title ?? (isLargeFilesMode ? "Large Files" : "Storage"))
                .font(.largeTitle.weight(.semibold))
            Text(explanation ?? (isLargeFilesMode
                 ? "Find large files in a folder you choose. Results are sorted by allocated size."
                 : "Explore folder sizes without loading the full file tree into memory."))
                .foregroundStyle(.secondary)
        }
    }

    private var controls: some View {
        HStack {
            Button(action: chooseFolder) {
                Label(model.selectedFolder == nil ? "Choose Folder" : "Change Folder", systemImage: "folder")
            }
            .disabled(model.isScanning)

            if let selectedFolder = model.selectedFolder {
                Text(selectedFolder.path)
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            Spacer()
            if model.isScanning {
                Button("Cancel Scan", role: .cancel) { model.cancelScan() }
            } else {
                Button {
                    model.startScan(mode: mode)
                } label: {
                    Label(actionTitle, systemImage: "magnifyingglass")
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.selectedFolder == nil)
            }
        }
    }

    private func reportSummary(_ report: FolderScanReport) -> some View {
        HStack(spacing: 20) {
            summaryValue("Total allocated", value: formatBytes(report.totalAllocatedBytes))
            summaryValue("Files scanned", value: report.filesScanned.formatted(.number.locale(locale)))
            if report.skippedItems > 0 {
                summaryValue("Items skipped", value: report.skippedItems.formatted(.number.locale(locale)))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .bottomLeading) {
            if report.skippedItems > 0 {
                Text("Some items could not be read; their sizes are excluded.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 4)
            }
        }
    }

    private func summaryValue(_ title: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline.monospacedDigit())
        }
    }

    private func fileRow(_ file: ScannedFile) -> some View {
        HStack(spacing: 14) {
            Image(systemName: file.url.hasDirectoryPath ? "folder" : "doc")
                .font(.title3)
                .foregroundStyle(.orange)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(file.url.lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)
                Text(file.url.path)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 8)
            Text(formatBytes(file.allocatedBytes))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
            Button {
                NSWorkspace.shared.activateFileViewerSelecting([file.url])
            } label: {
                Label("Show in Finder", systemImage: "arrow.up.forward.app")
            }
            .labelStyle(.iconOnly)
            .help("Show in Finder")
        }
        .padding(14)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
    }

    private func formatBytes(_ bytes: Int64) -> String {
        bytes.formatted(.byteCount(style: .file).locale(locale))
    }

    @MainActor
    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = String(localized: "Choose Folder", locale: locale)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        searchText = ""
        model.selectFolder(url)
    }
}
