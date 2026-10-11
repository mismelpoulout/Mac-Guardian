import Foundation

struct SystemOverview: Equatable {
    let volumeName: String
    let capacityBytes: Int64?
    let availableBytes: Int64?
    let physicalMemoryBytes: UInt64
    let uptime: TimeInterval

    var usedBytes: Int64? {
        guard let capacityBytes, let availableBytes else { return nil }
        return max(0, capacityBytes - availableBytes)
    }

    var storageUsageFraction: Double? {
        guard let usedBytes, let capacityBytes, capacityBytes > 0 else { return nil }
        return min(1, max(0, Double(usedBytes) / Double(capacityBytes)))
    }
}
