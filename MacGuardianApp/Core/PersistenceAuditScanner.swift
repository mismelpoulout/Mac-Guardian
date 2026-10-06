import Foundation

struct PersistenceAuditScanner: Sendable {
    func scan() async throws -> [PersistenceDefinition] {
        try await Task.detached(priority: .utility) {
            let home = FileManager.default.homeDirectoryForCurrentUser
            let roots = [
                home.appendingPathComponent("Library/LaunchAgents", isDirectory: true),
                URL(fileURLWithPath: "/Library/LaunchAgents", isDirectory: true),
                URL(fileURLWithPath: "/Library/LaunchDaemons", isDirectory: true)
            ]
            var definitions: [PersistenceDefinition] = []

            for root in roots where FileManager.default.fileExists(atPath: root.path) {
                let files = try FileManager.default.contentsOfDirectory(
                    at: root,
                    includingPropertiesForKeys: [.isRegularFileKey],
                    options: [.skipsHiddenFiles]
                )
                for file in files where file.pathExtension.caseInsensitiveCompare("plist") == .orderedSame {
                    let data = try Data(contentsOf: file)
                    let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
                    let label = plist?["Label"] as? String ?? file.deletingPathExtension().lastPathComponent
                    let program = (plist?["Program"] as? String)
                        ?? (plist?["ProgramArguments"] as? [String])?.first
                        ?? "—"
                    definitions.append(PersistenceDefinition(
                        id: file.standardizedFileURL.path,
                        label: label,
                        program: program,
                        location: file
                    ))
                }
            }
            return definitions.sorted { $0.label.localizedStandardCompare($1.label) == .orderedAscending }
        }.value
    }
}
