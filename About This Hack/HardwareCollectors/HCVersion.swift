import Foundation

enum MacOSVersion {
    case bigSur, monterey, ventura, sonoma, sequoia, tahoe, goldenGate, unknown
}

final class HCVersion {
    static let shared = HCVersion()

    let osPrefix = "macOS"
    let osNumber: String
    let osBuildNumber: String
    let osVersion: MacOSVersion

    private init() {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        osNumber = version.patchVersion == 0
            ? "\(version.majorVersion).\(version.minorVersion)"
            : "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        osBuildNumber = getSysctlValueByKey(inputKey: "kern.osversion")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown"

        switch version.majorVersion {
        case 27: osVersion = .goldenGate
        case 26: osVersion = .tahoe
        case 15: osVersion = .sequoia
        case 14: osVersion = .sonoma
        case 13: osVersion = .ventura
        case 12: osVersion = .monterey
        case 11: osVersion = .bigSur
        case 10 where version.minorVersion >= 16: osVersion = .bigSur
        default: osVersion = .unknown
        }
    }

    /// Marketing name, or an empty string for unknown releases.
    var osName: String {
        osVersion == .unknown ? "" : getOSImageName()
    }

    /// Asset name of the release artwork.
    func getOSImageName() -> String {
        switch osVersion {
        case .bigSur: return "Big Sur"
        case .monterey: return "Monterey"
        case .ventura: return "Ventura"
        case .sonoma: return "Sonoma"
        case .sequoia: return "Sequoia"
        case .tahoe: return "Tahoe"
        case .goldenGate: return "Golden Gate"
        case .unknown: return "Unknown"
        }
    }

    func getOSBuildInfo() -> String {
        [getSysctlValueByKey(inputKey: "kern.version")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
         getSIPInfo(),
         getOCLPInfo()]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    private func getSIPInfo() -> String {
        let config = csrActiveConfig()
        let status = config == 0 ? "Enabled" : "Disabled"
        return "System Integrity Protection: \(status) (0x\(String(format: "%08x", config)))"
    }

    private func csrActiveConfig() -> UInt32 {
        typealias CSRGetActiveConfig = @convention(c) (UnsafeMutablePointer<UInt32>) -> Int32
        guard let symbol = dlsym(RTLD_DEFAULT, "csr_get_active_config") else {
            return 0
        }

        var config: UInt32 = 0
        let status = unsafeBitCast(symbol, to: CSRGetActiveConfig.self)(&config)
        return status == 0 ? config : 0
    }

    private func getOCLPInfo() -> String {
        guard let xmlString = HardwareCollector.shared.oclpData,
              let version = xmlString.captureGroup(for: "<key>OpenCore Legacy Patcher</key>\\s*<string>([^<]+)</string>") else {
            return ""
        }

        let commit = xmlString.captureGroup(for: "<key>Commit URL</key>\\s*<string>[^/]+/([^<]+)</string>")?.split(separator: "/").last?.prefix(7) ?? ""
        let date = xmlString.captureGroup(for: "<key>Time Patched</key>\\s*<string>([^<]+)</string>")?.replacingOccurrences(of: "@", with: "") ?? ""
        return "OCLP \(version) (\(commit)) (\(date))"
    }
}

extension String {
    func captureGroup(for pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: self, range: NSRange(startIndex..., in: self)),
              let range = Range(match.range(at: 1), in: self) else {
            return nil
        }
        return String(self[range])
    }

    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }

    /// Collapses runs of whitespace into single spaces.
    var collapsingWhitespace: String {
        split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
