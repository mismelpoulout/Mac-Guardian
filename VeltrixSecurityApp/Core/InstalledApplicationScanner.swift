import Foundation

struct InstalledApplicationScanner: Sendable {
    func scan() async -> [InstalledApplication] {
        await Task.detached(priority: .utility) {
            let fileManager = FileManager.default
            let roots = fileManager.urls(for: .applicationDirectory, in: [.systemDomainMask, .localDomainMask, .userDomainMask])
            var applications: [InstalledApplication] = []

            for root in roots {
                guard let urls = try? fileManager.contentsOfDirectory(
                    at: root,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                ) else { continue }

                for url in urls where url.pathExtension.caseInsensitiveCompare("app") == .orderedSame {
                    guard let bundle = Bundle(url: url) else { continue }
                    let info = bundle.localizedInfoDictionary ?? bundle.infoDictionary ?? [:]
                    let identifier = bundle.bundleIdentifier ?? ""
                    applications.append(InstalledApplication(
                        id: url.standardizedFileURL.path,
                        name: (info["CFBundleDisplayName"] as? String)
                            ?? (info["CFBundleName"] as? String)
                            ?? url.deletingPathExtension().lastPathComponent,
                        bundleIdentifier: identifier,
                        version: (info["CFBundleShortVersionString"] as? String)
                            ?? (info["CFBundleVersion"] as? String)
                            ?? "—",
                        location: url
                    ))
                }
            }
            return applications.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        }.value
    }
}
