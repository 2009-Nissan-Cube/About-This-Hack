import Foundation
import IOKit

class HCVersion {
    static let shared = HCVersion()
    private init() {}
    
    var osNumber: String = ""
    var osVersion: MacOSVersion = .unknown
    var osName: String = ""
    var osBuildNumber: String = ""
    var osPrefix: String = "macOS"
    var dataHasBeenSet: Bool = false
    
    func getVersion() {
        guard !dataHasBeenSet else { return }
        ATHLogger.info(NSLocalizedString("log.version.init", comment: "Initializing OS Version Info"), category: .system)
        
        osPrefix = "macOS"
        ATHLogger.debug(String(format: NSLocalizedString("log.version.prefix_set", comment: "OS Prefix set"), osPrefix), category: .system)
        osNumber = getOSNumber()
        ATHLogger.debug(String(format: NSLocalizedString("log.version.number", comment: "OS Number"), osNumber), category: .system)
        osBuildNumber = getOSBuild()
        ATHLogger.debug(String(format: NSLocalizedString("log.version.build", comment: "OS Build Number"), osBuildNumber), category: .system)
        setOSVersion(osNumber: osNumber)
        ATHLogger.debug(NSLocalizedString("log.version.enum_set", comment: "Internal OS Version enum set"), category: .system)
        osName = macOSVersionToString()
        ATHLogger.debug(String(format: NSLocalizedString("log.version.name", comment: "OS Name"), osName), category: .system)
        dataHasBeenSet = true
        ATHLogger.info(NSLocalizedString("log.version.complete", comment: "OS Version Info collection complete"), category: .system)
    }

    private func getOSNumber() -> String {
        ATHLogger.debug(NSLocalizedString("log.version.getting_number", comment: "Getting OS Number"), category: .system)
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let versionString: String
        if osVersion.patchVersion == 0 {
            versionString = "\(osVersion.majorVersion).\(osVersion.minorVersion)"
        } else {
            versionString = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        }
        ATHLogger.debug(String(format: NSLocalizedString("log.version.determined_number", comment: "Determined OS Number"), versionString), category: .system)
        return versionString
    }
  
    private func getOSBuild() -> String {
        ATHLogger.debug(NSLocalizedString("log.version.getting_build", comment: "Getting OS Build Number"), category: .system)

        let buildString: String
        if let systemVersion = NSDictionary(contentsOfFile: "/System/Library/CoreServices/SystemVersion.plist") as? [String: Any],
           let productBuildVersion = systemVersion["ProductBuildVersion"] as? String,
           !productBuildVersion.isEmpty {
            buildString = productBuildVersion
        } else {
            buildString = getSysctlValueByKey(inputKey: "kern.osversion")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown"
        }

        ATHLogger.debug(String(format: NSLocalizedString("log.version.determined_build", comment: "Determined OS Build Number"), buildString), category: .system)
        return buildString
    }
    
    private func setOSVersion(osNumber: String) {
        ATHLogger.debug(String(format: NSLocalizedString("log.version.setting_enum", comment: "Setting internal OS Version enum"), osNumber), category: .system)

        switch osNumber.prefix(2) {
        case "26": osVersion = .tahoe
        case "15": osVersion = .sequoia
        case "14": osVersion = .sonoma
        case "13": osVersion = .ventura
        case "12": osVersion = .monterey
        case "11": osVersion = .bigSur
        case "10": osVersion = osNumber.prefix(5) == "10.16" ? .bigSur : .unknown
        default: osVersion = .unknown
        }
        ATHLogger.debug(String(format: NSLocalizedString("log.version.internal_set", comment: "Internal OS Version set"), "\(osVersion)"), category: .system)
    }

    private func macOSVersionToString() -> String {
        switch osVersion {
        case .bigSur: return "Big Sur"
        case .monterey: return "Monterey"
        case .ventura: return "Ventura"
        case .sonoma: return "Sonoma"
        case .sequoia: return "Sequoia"
        case .tahoe: return "Tahoe"
        case .unknown: return ""
        }
    }

    func getOSBuildInfo() -> String {
        let kernelVersion = getKernelVersion()
        let sipInfo = getSIPInfo()
        let oclpInfo = getOCLPInfo()
        
        return [kernelVersion, sipInfo, oclpInfo]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    private func getKernelVersion() -> String {
        getSysctlValueByKey(inputKey: "kern.version")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    
    private func getSIPInfo() -> String {
        let csrConfig = csrActiveConfig()
        let sipStatus = (csrConfig == 0) ? "Enabled" : "Disabled"
        
        var sipValue = ""

        if sipStatus == "Enabled" {
            sipValue = "System Integrity Protection: \(sipStatus) (0x00000000)"
        }
        else {
            sipValue = "System Integrity Protection: \(sipStatus) (0x\(String(format:"%08x", csrConfig)))"
        }
        return sipValue
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

    func getOSImageName() -> String {
        switch osVersion {
        case .bigSur: return "Big Sur"
        case .monterey: return "Monterey"
        case .ventura: return "Ventura"
        case .sonoma: return "Sonoma"
        case .sequoia: return "Sequoia"
        case .tahoe: return "Tahoe"
        case .unknown: return "Unknown"
        }
    }

    private func getOCLPInfo() -> String {
        guard let xmlString = HardwareCollector.shared.oclpData else {
            return ""
        }

        let version = xmlString.captureGroup(for: "<key>OpenCore Legacy Patcher</key>\\s*<string>([^<]+)</string>") ?? ""
        let commit = xmlString.captureGroup(for: "<key>Commit URL</key>\\s*<string>[^/]+/([^<]+)</string>")?.split(separator: "/").last?.prefix(7) ?? ""
        let date = xmlString.captureGroup(for: "<key>Time Patched</key>\\s*<string>([^<]+)</string>")?.replacingOccurrences(of: "@", with: "") ?? ""

        if !version.isEmpty {
            return "OCLP \(version) (\(commit)) (\(date))"
        }

        return ""
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
}

enum MacOSVersion {
    case bigSur, monterey, ventura, sonoma, sequoia, tahoe, unknown
}
