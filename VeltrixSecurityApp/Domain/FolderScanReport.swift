import Foundation

enum FolderScanMode: Sendable {
    case folderUsage
    case largeFiles(minimumBytes: Int64)
}

struct ScannedFile: Identifiable, Sendable {
    let id: String
    let url: URL
    let allocatedBytes: Int64
    let modifiedAt: Date?
}

struct FolderScanReport: Sendable {
    let rootURL: URL
    let files: [ScannedFile]
    let totalAllocatedBytes: Int64
    let filesScanned: Int
    let skippedItems: Int
    let resultsTruncated: Bool
}
