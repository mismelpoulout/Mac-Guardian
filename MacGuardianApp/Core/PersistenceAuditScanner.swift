import Foundation

struct PersistenceAuditScanner: Sendable {
    func scan() async -> PersistenceAuditReport {
        await Task.detached(priority: .utility) {
            let home = FileManager.default.homeDirectoryForCurrentUser
            let roots = [
                home.appendingPathComponent("Library/LaunchAgents", isDirectory: true),
                URL(fileURLWithPath: "/Library/LaunchAgents", isDirectory: true),
                URL(fileURLWithPath: "/Library/LaunchDaemons", isDirectory: true)
            ]
            var definitions: [PersistenceDefinition] = []
            var skippedItems = 0

            for root in roots where FileManager.default.fileExists(atPath: root.path) {
                let files: [URL]
                do {
                    files = try FileManager.default.contentsOfDirectory(
                        at: root,
                        includingPropertiesForKeys: [.isRegularFileKey],
                        options: [.skipsHiddenFiles]
                    )
                } catch {
                    skippedItems += 1
                    continue
                }
                for file in files where file.pathExtension.caseInsensitiveCompare("plist") == .orderedSame {
                    do {
                        let data = try Data(contentsOf: file)
                        guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
                            skippedItems += 1
                            continue
                        }
                        let label = plist["Label"] as? String ?? file.deletingPathExtension().lastPathComponent
                        let program = (plist["Program"] as? String)
                            ?? (plist["ProgramArguments"] as? [String])?.first
                            ?? "—"
                        definitions.append(PersistenceDefinition(
                            id: file.standardizedFileURL.path,
                            label: label,
                            program: program,
                            location: file
                        ))
                    } catch {
                        skippedItems += 1
                    }
                }
            }
            return PersistenceAuditReport(
                definitions: definitions.sorted { $0.label.localizedStandardCompare($1.label) == .orderedAscending },
                skippedItems: skippedItems
            )
        }.value
    }
}
