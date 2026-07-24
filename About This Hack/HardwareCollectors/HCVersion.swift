import Foundation
import IOKit

class HCVersion {
    static let shared = HCVersion()
    private init() {}

    private let stateLock = NSLock()
    private var _osNumber: String = ""
    private var _osVersion: MacOSVersion = .unknown
    private var _osName: String = ""
    private var _osBuildNumber: String = ""
    private var _osPrefix: String = "macOS"
    private var _dataHasBeenSet: Bool = false

    var osNumber: String {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _osNumber
    }

    var osVersion: MacOSVersion {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _osVersion
    }

    var osName: String {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _osName
    }

    var osBuildNumber: String {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _osBuildNumber
    }

    var osPrefix: String {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _osPrefix
    }

    var dataHasBeenSet: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _dataHasBeenSet
    }
    
    func getVersion() {
        stateLock.lock()
        if _dataHasBeenSet {
            stateLock.unlock()
            return
        }
        stateLock.unlock()

        ATHLogger.info(NSLocalizedString("log.version.init", comment: "Initializing OS Version Info"), category: .system)

        let prefix = "macOS"
        ATHLogger.debug(String(format: NSLocalizedString("log.version.prefix_set", comment: "OS Prefix set"), prefix), category: .system)
        let number = getOSNumber()
        ATHLogger.debug(String(format: NSLocalizedString("log.version.number", comment: "OS Number"), number), category: .system)
        let build = getOSBuild()
        ATHLogger.debug(String(format: NSLocalizedString("log.version.build", comment: "OS Build Number"), build), category: .system)
        let version = resolveOSVersion(osNumber: number)
        ATHLogger.debug(NSLocalizedString("log.version.enum_set", comment: "Internal OS Version enum set"), category: .system)
        let name = macOSVersionToString(version)
        ATHLogger.debug(String(format: NSLocalizedString("log.version.name", comment: "OS Name"), name), category: .system)

        stateLock.lock()
        if !_dataHasBeenSet {
            _osPrefix = prefix
            _osNumber = number
            _osBuildNumber = build
            _osVersion = version
            _osName = name
            _dataHasBeenSet = true
        }
        stateLock.unlock()

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
    
    private func resolveOSVersion(osNumber: String) -> MacOSVersion {
        ATHLogger.debug(String(format: NSLocalizedString("log.version.setting_enum", comment: "Setting internal OS Version enum"), osNumber), category: .system)

        let version: MacOSVersion
        switch osNumber.prefix(2) {
        case "26": version = .tahoe
        case "15": version = .sequoia
        case "14": version = .sonoma
        case "13": version = .ventura
        case "12": version = .monterey
        case "11": version = .bigSur
        case "10": version = osNumber.prefix(5) == "10.16" ? .bigSur : .unknown
        default: version = .unknown
        }
        ATHLogger.debug(String(format: NSLocalizedString("log.version.internal_set", comment: "Internal OS Version set"), "\(version)"), category: .system)
        return version
    }

    private func macOSVersionToString(_ version: MacOSVersion) -> String {
        switch version {
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
