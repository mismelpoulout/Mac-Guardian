import Foundation

struct DeveloperStorageResult: Identifiable, Sendable {
    let id: String
    let nameKey: String
    let location: URL
    let allocatedBytes: Int64
    let filesScanned: Int
    let skippedItems: Int
}

@MainActor
@Observable
final class DeveloperStorageViewModel {
    private(set) var results: [DeveloperStorageResult] = []
    private(set) var isScanning = false
    private(set) var currentLocationKey: String?
    private(set) var filesScanned = 0
    private(set) var errorMessageKey: String?
    private(set) var wasCancelled = false
    private var scanTask: Task<Void, Never>?

    private let scanner = FolderScanner()

    func scan() {
        guard !isScanning else { return }
        isScanning = true
        results = []
        filesScanned = 0
        errorMessageKey = nil
        wasCancelled = false

        scanTask = Task { [weak self] in
            guard let self else { return }
            defer {
                self.isScanning = false
                self.currentLocationKey = nil
                self.scanTask = nil
            }

            do {
                for location in Self.knownLocations where FileManager.default.fileExists(atPath: location.url.path) {
                    try Task.checkCancellation()
                    self.currentLocationKey = location.nameKey
                    let completedFileCount = self.filesScanned
                    do {
                        let report = try await self.scanner.scan(rootURL: location.url, mode: .folderUsage) { [weak self] count in
                            Task { @MainActor [weak self] in
                                guard let self, self.currentLocationKey == location.nameKey else { return }
                                self.filesScanned = max(self.filesScanned, completedFileCount + count)
                            }
                        }
                        self.filesScanned = completedFileCount + report.filesScanned
                        self.results.append(DeveloperStorageResult(
                            id: location.url.path,
                            nameKey: location.nameKey,
                            location: location.url,
                            allocatedBytes: report.totalAllocatedBytes,
                            filesScanned: report.filesScanned,
                            skippedItems: report.skippedItems
                        ))
                    } catch is CancellationError {
                        throw CancellationError()
                    } catch {
                        self.errorMessageKey = "error.scanFailed"
                    }
                }
            } catch is CancellationError {
                self.wasCancelled = true
                return
            } catch {
                self.errorMessageKey = "error.scanFailed"
            }
        }
    }

    func cancel() {
        scanTask?.cancel()
    }

    private static var knownLocations: [(nameKey: String, url: URL)] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let library = home.appendingPathComponent("Library", isDirectory: true)
        return [
            ("Xcode Derived Data", library.appendingPathComponent("Developer/Xcode/DerivedData", isDirectory: true)),
            ("Xcode Archives", library.appendingPathComponent("Developer/Xcode/Archives", isDirectory: true)),
            ("Xcode Simulator Data", library.appendingPathComponent("Developer/CoreSimulator/Devices", isDirectory: true)),
            ("Homebrew Cache", library.appendingPathComponent("Caches/Homebrew", isDirectory: true)),
            ("npm Cache", home.appendingPathComponent(".npm", isDirectory: true)),
            ("pnpm Store", library.appendingPathComponent("pnpm/store", isDirectory: true)),
            ("Yarn Cache", library.appendingPathComponent("Caches/Yarn", isDirectory: true)),
            ("Swift Package Manager Cache", library.appendingPathComponent("Caches/org.swift.swiftpm", isDirectory: true)),
            ("Python Cache", home.appendingPathComponent(".cache/pip", isDirectory: true))
        ]
    }
}
