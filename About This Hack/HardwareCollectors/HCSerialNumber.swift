import Foundation
import IOKit

final class HCSerialNumber {
    static let shared = HCSerialNumber()

    private let serialNumber: String

    private init() {
        let platform = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPlatformExpertDevice"))
        defer { if platform != 0 { IOObjectRelease(platform) } }
        serialNumber = registryString(platform, kIOPlatformSerialNumberKey) ?? ""
    }

    func getSerialNumber() -> String {
        serialNumber
    }

    /// Firmware and identifier lines from `system_profiler`, empty until it has loaded.
    func getHardwareInfo() -> String {
        let relevantKeys = [
            "System Firmware Version", "OS Loader Version", "SMC Version",
            "Apple ROM Info:", "Board-ID :", "Hardware UUID:", "Provisioning UDID:"
        ]

        return (HardwareCollector.shared.hardwareData ?? "")
            .components(separatedBy: .newlines)
            .filter { line in relevantKeys.contains { line.contains($0) } }
            .map(\.collapsingWhitespace)
            .joined(separator: "\n")
    }
}
