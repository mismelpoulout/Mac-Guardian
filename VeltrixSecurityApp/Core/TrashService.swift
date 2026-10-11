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

import UserNotifications

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate, Sendable {
    static let shared = NotificationManager()
    
    private override init() {
        super.init()
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notification authorization: \(error)")
            }
        }
    }
    
    func showNotification(title: String, subtitle: String, body: String = "") {
        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error showing notification: \(error)")
            }
        }
    }
    
    func playSuccessSound() {
        if let sound = NSSound(named: "Glass") {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}
