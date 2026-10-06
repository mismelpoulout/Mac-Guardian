import AppKit
import Foundation

enum TrashServiceError: Error, Equatable {
    case appIsRunning
    case cacheItemOutsideSupportedFolder
    case appOutsideSupportedFolder
    case symbolicLinkNotSupported
}

enum TrashService {
    static func canMoveAppToTrash(_ appURL: URL) -> Bool {
        guard appURL.pathExtension.caseInsensitiveCompare("app") == .orderedSame else { return false }
        let path = appURL.standardizedFileURL.path
        let roots = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true)
        ]
        return roots.contains { isImmediateChild(appURL, of: $0) }
            && !path.hasPrefix("/System/")
    }

    static func moveCacheItemToTrash(_ itemURL: URL, cacheRoot: URL) throws {
        guard isEligibleCacheItem(itemURL, cacheRoot: cacheRoot) else {
            throw TrashServiceError.cacheItemOutsideSupportedFolder
        }
        try rejectSymbolicLink(itemURL)
        try FileManager.default.trashItem(at: itemURL, resultingItemURL: nil)
    }

    static func isEligibleCacheItem(_ itemURL: URL, cacheRoot: URL) -> Bool {
        isImmediateChild(itemURL, of: cacheRoot)
    }

    static func moveAppToTrash(_ appURL: URL) throws {
        guard canMoveAppToTrash(appURL) else {
            throw TrashServiceError.appOutsideSupportedFolder
        }
        try rejectSymbolicLink(appURL)
        if let bundleIdentifier = Bundle(url: appURL)?.bundleIdentifier,
           NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).contains(where: { !$0.isTerminated }) {
            throw TrashServiceError.appIsRunning
        }
        try FileManager.default.trashItem(at: appURL, resultingItemURL: nil)
    }

    private static func rejectSymbolicLink(_ url: URL) throws {
        let values = try url.resourceValues(forKeys: [.isSymbolicLinkKey])
        guard values.isSymbolicLink != true else {
            throw TrashServiceError.symbolicLinkNotSupported
        }
    }

    private static func isImmediateChild(_ itemURL: URL, of rootURL: URL) -> Bool {
        let item = itemURL.standardizedFileURL
        let root = rootURL.standardizedFileURL
        return item.deletingLastPathComponent() == root && item != root
    }
}
