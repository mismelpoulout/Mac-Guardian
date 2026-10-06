import Foundation

struct FolderScanner: Sendable {
    private static let resultLimit = 300
    private static let progressInterval = 250
    private static let resourceKeys: Set<URLResourceKey> = [
        .isDirectoryKey,
        .isRegularFileKey,
        .isSymbolicLinkKey,
        .fileAllocatedSizeKey,
        .fileSizeKey,
        .contentModificationDateKey
    ]

    func scan(
        rootURL: URL,
        mode: FolderScanMode,
        progress: @escaping @Sendable (Int) -> Void
    ) async throws -> FolderScanReport {
        let worker = Task.detached(priority: .utility) {
            try Self.performScan(rootURL: rootURL, mode: mode, progress: progress)
        }

        return try await withTaskCancellationHandler {
            try await worker.value
        } onCancel: {
            worker.cancel()
        }
    }

    private static func performScan(
        rootURL: URL,
        mode: FolderScanMode,
        progress: @Sendable (Int) -> Void
    ) throws -> FolderScanReport {
        let root = rootURL.standardizedFileURL
        let resolvedRootPath = root.resolvingSymlinksInPath().path
        let resolvedRootPrefix = resolvedRootPath.hasSuffix("/") ? resolvedRootPath : resolvedRootPath + "/"
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw MacGuardianError.invalidPath
        }

        var skippedItems = 0
        var filesScanned = 0
        var lastReportedFileCount = 0
        var totalBytes: Int64 = 0
        var largeFilesFound = 0
        var folderTotals: [String: (url: URL, bytes: Int64)] = [:]
        var largestFiles: [ScannedFile] = []
        let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: Array(resourceKeys),
            options: [],
            errorHandler: { _, _ in
                skippedItems += 1
                return true
            }
        )

        guard let enumerator else {
            throw MacGuardianError.scanFailed("Unable to enumerate the selected folder.")
        }

        while let itemURL = enumerator.nextObject() as? URL {
            try Task.checkCancellation()
            do {
                let values = try itemURL.resourceValues(forKeys: resourceKeys)
                if values.isSymbolicLink == true {
                    enumerator.skipDescendants()
                    skippedItems += 1
                    continue
                }
                guard values.isRegularFile == true else { continue }

                let bytes = Int64(max(values.fileAllocatedSize ?? values.fileSize ?? 0, 0))
                totalBytes += bytes
                filesScanned += 1

                switch mode {
                case .folderUsage:
                    let resolvedItemPath = itemURL.resolvingSymlinksInPath().path
                    guard resolvedItemPath.hasPrefix(resolvedRootPrefix) else {
                        skippedItems += 1
                        continue
                    }
                    let relativePath = resolvedItemPath.dropFirst(resolvedRootPrefix.count)
                    let firstComponent = relativePath.split(separator: "/", maxSplits: 1).first.map(String.init) ?? itemURL.lastPathComponent
                    var total = folderTotals[firstComponent] ?? (root.appendingPathComponent(firstComponent), 0)
                    total.bytes += bytes
                    folderTotals[firstComponent] = total
                case .largeFiles(let minimumBytes):
                    if bytes >= minimumBytes {
                        largeFilesFound += 1
                        largestFiles.append(ScannedFile(
                            id: itemURL.path,
                            url: itemURL,
                            allocatedBytes: bytes,
                            modifiedAt: values.contentModificationDate
                        ))
                        if largestFiles.count > resultLimit * 2 {
                            largestFiles.sort { $0.allocatedBytes > $1.allocatedBytes }
                            largestFiles = Array(largestFiles.prefix(resultLimit))
                        }
                    }
                }

                if filesScanned.isMultiple(of: progressInterval) {
                    progress(filesScanned)
                    lastReportedFileCount = filesScanned
                }
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                skippedItems += 1
            }
        }

        try Task.checkCancellation()
        if filesScanned != lastReportedFileCount {
            progress(filesScanned)
        }
        let files: [ScannedFile]
        switch mode {
        case .folderUsage:
            files = folderTotals.map { name, value in
                ScannedFile(id: name, url: value.url, allocatedBytes: value.bytes, modifiedAt: nil)
            }.sorted { $0.allocatedBytes > $1.allocatedBytes }
        case .largeFiles:
            files = Array(largestFiles.sorted { $0.allocatedBytes > $1.allocatedBytes }.prefix(resultLimit))
        }

        return FolderScanReport(
            rootURL: root,
            files: files,
            totalAllocatedBytes: totalBytes,
            filesScanned: filesScanned,
            skippedItems: skippedItems,
            resultsTruncated: largeFilesFound > resultLimit
        )
    }
}
