import Foundation

@MainActor
@Observable
final class FolderScanViewModel {
    private(set) var selectedFolder: URL?
    private(set) var report: FolderScanReport?
    private(set) var filesScanned = 0
    private(set) var isScanning = false
    private(set) var wasCancelled = false
    private(set) var errorMessageKey: String?

    private let scanner = FolderScanner()
    private var scanTask: Task<Void, Never>?

    func selectFolder(_ url: URL) {
        selectedFolder = url
        report = nil
        filesScanned = 0
        wasCancelled = false
        errorMessageKey = nil
    }

    func startScan(mode: FolderScanMode) {
        guard let selectedFolder, !isScanning else { return }
        isScanning = true
        report = nil
        filesScanned = 0
        wasCancelled = false
        errorMessageKey = nil

        scanTask = Task { [weak self] in
            guard let self else { return }
            let hasScopedAccess = selectedFolder.startAccessingSecurityScopedResource()
            defer {
                if hasScopedAccess {
                    selectedFolder.stopAccessingSecurityScopedResource()
                }
                self.isScanning = false
                self.scanTask = nil
            }

            do {
                self.report = try await self.scanner.scan(rootURL: selectedFolder, mode: mode) { [weak self] count in
                    Task { @MainActor [weak self] in self?.filesScanned = count }
                }
            } catch is CancellationError {
                self.wasCancelled = true
            } catch let error as MacGuardianError {
                self.errorMessageKey = error.userMessageKey
            } catch {
                self.errorMessageKey = "error.scanFailed"
            }
        }
    }

    func cancelScan() {
        scanTask?.cancel()
    }
}
