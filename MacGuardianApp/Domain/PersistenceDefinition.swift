import Foundation

struct PersistenceDefinition: Identifiable, Sendable {
    let id: String
    let label: String
    let program: String
    let location: URL
}
