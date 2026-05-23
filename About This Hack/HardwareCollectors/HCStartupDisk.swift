import Foundation
import DiskArbitration
import IOKit

private struct StartupDiskSnapshot {
    let volumeName: String
    let totalBytes: Int64
    let availableBytes: Int64
    let isSolidState: Bool
    let deviceLocation: String
    let deviceProtocol: String

    var percentFree: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(availableBytes) / Double(totalBytes)
    }

    var percentUsed: Double {
        1 - percentFree
    }
}

private struct DiskArbitrationDeviceInfo {
    let isInternal: Bool
    let protocolName: String
    let isSolidState: Bool
}

class HCStartupDisk {
    static let shared = HCStartupDisk()
    private init() {}

    private let lock = NSLock()
    private var _snapshot: StartupDiskSnapshot?

    private var snapshot: StartupDiskSnapshot {
        lock.lock()
        defer { lock.unlock() }

        if let cached = _snapshot {
            return cached
        }

        let computed = computeSnapshot()
        _snapshot = computed
        return computed
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        _snapshot = nil
    }
    
    func getStartupDisk() -> String {
        ATHLogger.debug(NSLocalizedString("log.startup.getting_name", comment: "Getting startup disk name string"), category: .hardware)
        return snapshot.volumeName
    }

    func getStorageSummary() -> (isSolidState: Bool, description: String, percentUsed: Double, deviceLocation: String, deviceProtocol: String) {
        let info = snapshot
        let sizeGB = bytesToGB(info.totalBytes)
        let availableGB = bytesToGB(info.availableBytes)
        let percentFreeText = String(format: "%.2f", info.percentFree * 100)

        let storageInfo = """
        \(info.volumeName) (\(info.deviceLocation) \(info.deviceProtocol))
        \(String(format: "%.2f", sizeGB)) GB (\(String(format: "%.2f", availableGB)) GB \(NSLocalizedString("storage.available", comment: "Available storage label")) - \(percentFreeText)%)
        """

        return (info.isSolidState, storageInfo, info.percentUsed, info.deviceLocation, info.deviceProtocol)
    }

    func getStartupDiskInfo() -> String {
        ATHLogger.debug(NSLocalizedString("log.startup.getting_detailed", comment: "Getting detailed startup disk info string"), category: .hardware)
        return getStorageSummary().description
    }

    private func computeSnapshot() -> StartupDiskSnapshot {
        ATHLogger.debug(NSLocalizedString("log.startup.init", comment: "Initializing Startup Disk Info"), category: .hardware)

        let volumeURL = URL(fileURLWithPath: "/", isDirectory: true)
        let resourceValues = try? volumeURL.resourceValues(forKeys: [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,
            .volumeAvailableCapacityKey
        ])

        let volumeName = resourceValues?.volumeName ?? FileManager.default.displayName(atPath: volumeURL.path)
        let totalCapacity = resourceValues?.volumeTotalCapacity ?? 0
        let availableCapacity = resourceValues?.volumeAvailableCapacity ?? 0
        let totalBytes = Int64(totalCapacity)
        let availableBytes = Int64(availableCapacity)
        let deviceInfo = getDeviceInfo(for: volumeURL)

        ATHLogger.debug(String(format: NSLocalizedString("log.startup.parsed_name", comment: "Parsed Startup Disk Name"), volumeName), category: .hardware)

        return StartupDiskSnapshot(
            volumeName: volumeName.isEmpty ? "/" : volumeName,
            totalBytes: totalBytes,
            availableBytes: availableBytes,
            isSolidState: deviceInfo?.isSolidState ?? false,
            deviceLocation: (deviceInfo?.isInternal ?? true) ? "Internal" : "External",
            deviceProtocol: normalizeProtocol(deviceInfo?.protocolName)
        )
    }

    private func getDeviceInfo(for volumeURL: URL) -> DiskArbitrationDeviceInfo? {
        guard let session = DASessionCreate(kCFAllocatorDefault),
              let disk = DADiskCreateFromVolumePath(kCFAllocatorDefault, session, volumeURL as CFURL),
              let description = DADiskCopyDescription(disk) as NSDictionary? else {
            return nil
        }

        let isInternal = description[kDADiskDescriptionDeviceInternalKey as String] as? Bool ?? true
        let protocolName = description[kDADiskDescriptionDeviceProtocolKey as String] as? String ?? "Unknown"
        let ioMedia = DADiskCopyIOMedia(disk)
        defer {
            if ioMedia != 0 {
                IOObjectRelease(ioMedia)
            }
        }

        let isSolidState = ioMedia != 0 ? mediaIsSolidState(ioMedia) : false
        return DiskArbitrationDeviceInfo(isInternal: isInternal, protocolName: protocolName, isSolidState: isSolidState)
    }

    private func mediaIsSolidState(_ media: io_service_t) -> Bool {
        if let deviceCharacteristics = copyDeviceCharacteristics(from: media),
           let mediumType = deviceCharacteristics["Medium Type"] as? String {
            return mediumType.caseInsensitiveCompare("Solid State") == .orderedSame
        }

        if let directFlag = copyProperty(named: "Solid State", from: media) as? Bool {
            return directFlag
        }

        return false
    }

    private func copyDeviceCharacteristics(from media: io_service_t) -> [String: Any]? {
        if let directCharacteristics = copyProperty(named: "Device Characteristics", from: media) as? [String: Any] {
            return directCharacteristics
        }

        var current = media
        var shouldReleaseCurrent = false

        while true {
            var parent: io_registry_entry_t = 0
            let status = IORegistryEntryGetParentEntry(current, kIOServicePlane, &parent)
            guard status == KERN_SUCCESS, parent != 0 else {
                break
            }

            if let parentCharacteristics = copyProperty(named: "Device Characteristics", from: parent) as? [String: Any] {
                if shouldReleaseCurrent {
                    IOObjectRelease(current)
                }
                IOObjectRelease(parent)
                return parentCharacteristics
            }

            if shouldReleaseCurrent {
                IOObjectRelease(current)
            }
            current = parent
            shouldReleaseCurrent = true
        }

        if shouldReleaseCurrent {
            IOObjectRelease(current)
        }

        return nil
    }

    private func copyProperty(named propertyName: String, from service: io_service_t) -> Any? {
        IORegistryEntryCreateCFProperty(service, propertyName as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
    }

    private func normalizeProtocol(_ protocolName: String?) -> String {
        guard let protocolName, !protocolName.isEmpty else {
            return "Unknown"
        }

        return protocolName.replacingOccurrences(of: " fabric$", with: "", options: [.regularExpression, .caseInsensitive])
    }

    private func bytesToGB(_ bytes: Int64) -> Double {
        Double(bytes) / 1_000_000_000
    }
}
