import DiskArbitration
import Foundation
import IOKit

/// Startup volume details. Device facts are cached; capacity is re-read after `invalidate()`.
final class HCStartupDisk {
    static let shared = HCStartupDisk()
    private init() {}

    private struct Capacity {
        let volumeName: String
        let totalBytes: Int64
        let availableBytes: Int64
    }

    private let volumeURL = URL(fileURLWithPath: "/", isDirectory: true)
    private let lock = NSLock()
    private var cachedCapacity: Capacity?
    private lazy var device: (isInternal: Bool, protocolName: String, isSolidState: Bool) = readDevice()

    private var capacity: Capacity {
        lock.lock()
        defer { lock.unlock() }
        if let cachedCapacity { return cachedCapacity }

        let values = try? volumeURL.resourceValues(forKeys: [
            .volumeNameKey, .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey, .volumeAvailableCapacityKey
        ])
        let important = values?.volumeAvailableCapacityForImportantUsage ?? 0
        let computed = Capacity(
            volumeName: values?.volumeName?.nilIfEmpty ?? "/",
            totalBytes: Int64(values?.volumeTotalCapacity ?? 0),
            availableBytes: important > 0 ? important : Int64(values?.volumeAvailableCapacity ?? 0)
        )
        cachedCapacity = computed
        return computed
    }

    private var deviceInfo: (isInternal: Bool, protocolName: String, isSolidState: Bool) {
        lock.lock()
        defer { lock.unlock() }
        return device
    }

    func invalidate() {
        lock.lock()
        cachedCapacity = nil
        lock.unlock()
    }

    var isSolidState: Bool { deviceInfo.isSolidState }
    var deviceLocation: String { deviceInfo.isInternal ? "Internal" : "External" }
    var deviceProtocol: String { deviceInfo.protocolName }
    var totalGB: Double { Double(capacity.totalBytes) / 1e9 }
    var availableGB: Double { Double(capacity.availableBytes) / 1e9 }
    var percentUsed: Double { totalGB > 0 ? 1 - availableGB / totalGB : 0 }

    func getStartupDisk() -> String {
        capacity.volumeName
    }

    func getStartupDiskInfo() -> String {
        let available = String(format: "%.2f GB %@ - %.2f%%", availableGB, NSLocalizedString("storage.available", comment: "Available storage label"), (1 - percentUsed) * 100)
        return "\(getStartupDisk()) (\(deviceLocation) \(deviceProtocol))\n\(String(format: "%.2f", totalGB)) GB (\(available))"
    }

    private func readDevice() -> (isInternal: Bool, protocolName: String, isSolidState: Bool) {
        guard let session = DASessionCreate(kCFAllocatorDefault),
              let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, volumeURL as CFURL),
              let description = DADiskCopyDescription(disk) as? [String: Any] else {
            return (true, "Unknown", false)
        }

        let media = DADiskCopyIOMedia(disk)
        defer { if media != 0 { IOObjectRelease(media) } }
        let options = IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)
        let characteristics = IORegistryEntrySearchCFProperty(media, kIOServicePlane, "Device Characteristics" as CFString, kCFAllocatorDefault, options) as? [String: Any]
        let mediumType = characteristics?["Medium Type"] as? String

        return (
            description[kDADiskDescriptionDeviceInternalKey as String] as? Bool ?? true,
            (description[kDADiskDescriptionDeviceProtocolKey as String] as? String)?.nilIfEmpty ?? "Unknown",
            mediumType?.caseInsensitiveCompare("Solid State") == .orderedSame
        )
    }
}
