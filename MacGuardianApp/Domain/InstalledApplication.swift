import Foundation

struct InstalledApplication: Identifiable, Sendable {
    let id: String
    let name: String
    let bundleIdentifier: String
    let version: String
    let location: URL
}
