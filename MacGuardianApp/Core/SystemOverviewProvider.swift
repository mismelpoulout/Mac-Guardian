import Foundation

struct SystemOverviewProvider {
    func load() throws -> SystemOverview {
        let volumeURL = URL(fileURLWithPath: "/")
        let values: URLResourceValues
        do {
            values = try volumeURL.resourceValues(forKeys: [
                .volumeNameKey,
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey
            ])
        } catch {
            GuardianLogger.storage.error("Unable to read root volume capacity: \(error.localizedDescription, privacy: .public)")
            throw MacGuardianError.scanFailed("Unable to read storage volume information.")
        }

        return SystemOverview(
            volumeName: values.volumeName ?? "Startup Volume",
            capacityBytes: values.volumeTotalCapacity.map { Int64($0) },
            availableBytes: values.volumeAvailableCapacityForImportantUsage.map { Int64($0) },
            physicalMemoryBytes: ProcessInfo.processInfo.physicalMemory,
            uptime: ProcessInfo.processInfo.systemUptime
        )
    }
}
