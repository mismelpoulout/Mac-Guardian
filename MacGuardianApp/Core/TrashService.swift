import Foundation

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
        guard isImmediateChild(itemURL, of: cacheRoot) else {
            throw CocoaError(.fileWriteNoPermission, userInfo: [NSLocalizedDescriptionKey: "Only direct children of the current user's cache folder can be moved."])
        }
        try rejectSymbolicLink(itemURL)
        try FileManager.default.trashItem(at: itemURL, resultingItemURL: nil)
    }

    static func moveAppToTrash(_ appURL: URL) throws {
        guard canMoveAppToTrash(appURL) else {
            throw CocoaError(.fileWriteNoPermission, userInfo: [NSLocalizedDescriptionKey: "This application is protected or outside the supported Applications folders."])
        }
        try rejectSymbolicLink(appURL)
        try FileManager.default.trashItem(at: appURL, resultingItemURL: nil)
    }

    private static func rejectSymbolicLink(_ url: URL) throws {
        let values = try url.resourceValues(forKeys: [.isSymbolicLinkKey])
        guard values.isSymbolicLink != true else {
            throw CocoaError(.fileWriteNoPermission, userInfo: [NSLocalizedDescriptionKey: "Symbolic links cannot be moved by this action."])
        }
    }

    private static func isImmediateChild(_ itemURL: URL, of rootURL: URL) -> Bool {
        let item = itemURL.standardizedFileURL
        let root = rootURL.standardizedFileURL
        return item.deletingLastPathComponent() == root && item != root
    }
}
