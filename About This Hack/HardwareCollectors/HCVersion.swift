import Foundation
import IOKit

class HCVersion {
    static let shared = HCVersion()
    private init() {}
    
    var osNumber: String = "10.10.0"
    var osVersion: MacOSVersion = .macOS
    var osName: String = ""
    var osBuildNumber: String = "19G101"
    var osPrefix: String = "macOS"
    var dataHasBeenSet: Bool = false
    
    func getVersion() {
        guard !dataHasBeenSet else { return }
        
        osPrefix = "macOS"
        osNumber = getOSNumber()
        osBuildNumber = getOSBuild()
        setOSVersion(osNumber: osNumber)
        osName = macOSVersionToString()
        dataHasBeenSet = true
    }

    private func getOSNumber() -> String {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        if (osVersion.patchVersion == 0) {
            return "\(osVersion.majorVersion).\(osVersion.minorVersion)"
        } else {
            return "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        }
    }
  
    private func getOSBuild() -> String {
        var size = 0
        sysctlbyname("kern.osversion", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("kern.osversion", &machine, &size, nil, 0)
        let build = String(cString: machine)
        return " (\(build)) "
    }
    
    private func setOSVersion(osNumber: String) {
        let majorVersion = osNumber.prefix(2)
        let minorVersion = osNumber.prefix(5)
        
        switch majorVersion {
        case "15": osVersion = .sequoia
        case "14": osVersion = .sonoma
        case "13": osVersion = .ventura
        case "12": osVersion = .monterey
        case "11": osVersion = .bigSur
        case "10":
            switch minorVersion {
            case "10.16": osVersion = .bigSur
            case "10.15": osVersion = .catalina
            case "10.14": osVersion = .mojave
            case "10.13": osVersion = .highSierra
            case "10.12": osVersion = .sierra
            default: osVersion = .macOS
            }
        default: osVersion = .macOS
        }
    }

    private func macOSVersionToString() -> String {
        switch osVersion {
        case .sierra: return "Sierra"
        case .highSierra: return "High Sierra"
        case .mojave: return "Mojave"
        case .catalina: return "Catalina"
        case .bigSur: return "Big Sur"
        case .monterey: return "Monterey"
        case .ventura: return "Ventura"
        case .sonoma: return "Sonoma"
        case .sequoia: return "Sequoia"
        case .macOS: return ""
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
        var size = 0
        sysctlbyname("kern.version", nil, &size, nil, 0)
        var kernel = [CChar](repeating: 0, count: size)
        sysctlbyname("kern.version", &kernel, &size, nil, 0)
        return String(cString: kernel)
    }
    
     private func getSIPInfo() -> String {
        let csrConfig = csrActiveConfig()
        let sipStatus = (csrConfig == 0) ? "Enabled" : "Disabled"
        
        // If Enabled, Apple Silicon may display only "Enabled", hex value is missing
        // If Disabled, both platforms Intel and Silicon display "sipStatus + hex value"
        var sipValue = ""

        if sipStatus == "Enabled" {
            sipValue = "System Integrity Protection: \(sipStatus) (0x00000000)"
        }
        else {
            sipValue = "System Integrity Protection: \(sipStatus) (0x\(String(format:"%08x", csrConfig)))"
        }        
        return sipValue
        
//        return "System Integrity Protection: \(sipStatus) (0x\(String(format:"%08x", csrConfig)))"
    }
    
    private func csrActiveConfig() -> UInt32 {
        let config = ObjCSIP() // reference to Objective-C file
        var csrConfig = UInt32(config.sipValue()) // method of the Objective-C file (long >> UInt32)
        csrConfig = csrConfig.byteSwapped // big endian to litle endian e.g. 00000803 to 03080000
        //print("csrConfig \(csrConfig)") // testing
        return csrConfig
    }

//    private func csrActiveConfig() -> UInt32 {
//        var config: UInt32 = 0
//        var size = MemoryLayout<UInt32>.size
//        sysctlbyname("kern.bootargs", nil, &size, nil, 0)
//        var bootArgs = [CChar](repeating: 0, count: size)
//        sysctlbyname("kern.bootargs", &bootArgs, &size, nil, 0)
//        let bootArgsString = String(cString: bootArgs)
//        
//        if let configValue = bootArgsString.captureGroup(for: "csr-active-config=(0x[0-9a-fA-F]+)") {
//            config = UInt32(configValue.dropFirst(2), radix: 16) ?? 0
//        } else {
//            sysctlbyname("kern.csr_active_config", &config, &size, nil, 0)
//        }
//        
//        return config
//    }

    private func getOCLPInfo() -> String {
        guard let xmlString = try? String(contentsOfFile: InitGlobVar.oclpXmlFilePath, encoding: .utf8) else {
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
    case sierra, highSierra, mojave, catalina, bigSur, monterey, ventura, sonoma, sequoia, macOS
}
