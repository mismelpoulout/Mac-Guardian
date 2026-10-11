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
    
    /// Empties the user's Trash by asking Finder to do it.
    /// This works reliably without requiring Full Disk Access and respects all Trash volumes.
    @discardableResult
    static func emptyTrash() -> (deletedCount: Int, freedBytes: Int64) {
        let scriptSource = """
        tell application "Finder"
            set initialCount to count of items of trash
            if initialCount > 0 then
                try
                    empty trash
                end try
            end if
            set finalCount to count of items of trash
            return initialCount - finalCount
        end tell
        """
        
        var error: NSDictionary?
        if let script = NSAppleScript(source: scriptSource) {
            let result = script.executeAndReturnError(&error)
            
            if error != nil {
                return (0, 0)
            }
            
            let deletedCount = Int(result.int32Value)
            return (max(0, deletedCount), 0)
        }
        
        return (0, 0)
    }
}

