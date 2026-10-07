import Foundation

final class HCBootloader {
    static let shared = HCBootloader()

    /// Bootloader known from native sources; nil means "check the profiler report for Clover".
    private let nativeBootloader: String?

    private init() {
        if HCCPU.isAppleSilicon {
            nativeBootloader = "Apple iBoot"
        } else {
            nativeBootloader = registryString(path: "IODeviceTree:/options", InitGlobVar.nvramOpencoreVersion)
                .flatMap(Self.parseOpenCoreVersion)
        }
    }

    func getBootloader() -> String {
        if let nativeBootloader {
            return nativeBootloader
        }
        if let line = (HardwareCollector.shared.hardwareData ?? "")
            .components(separatedBy: .newlines)
            .first(where: { $0.localizedCaseInsensitiveContains("Clover") }) {
            let version = (line.split(separator: ":", maxSplits: 1).last.map(String.init) ?? "")
                .replacingOccurrences(of: "Clover", with: "", options: .caseInsensitive)
                .collapsingWhitespace
            return version.isEmpty ? "Clover" : "Clover \(version)"
        }
        return "Apple UEFI"
    }

    /// "REL-100-2024-04-01" -> "OpenCore 1.0.0 (Release)"
    static func parseOpenCoreVersion(_ rawValue: String) -> String? {
        let components = rawValue.split(separator: "-", maxSplits: 2)
        guard components.count >= 2 else {
            return nil
        }

        let buildType = String(components[0])
        var version = String(components[1])
        if version.count == 3, version.allSatisfy(\.isNumber) {
            version = version.map(String.init).joined(separator: ".")
        }

        switch buildType {
        case "REL": return "OpenCore \(version) (Release)"
        case "DEB": return "OpenCore \(version) (Debug)"
        case "": return "OpenCore \(version)"
        default: return "OpenCore \(version) (\(buildType))"
        }
    }
}
