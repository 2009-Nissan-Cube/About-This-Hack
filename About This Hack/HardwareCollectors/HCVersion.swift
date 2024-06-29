import Foundation
import IOKit

class HCVersion {
    
    static var OSnum: String = "10.10.0"
    static var OSvers: macOSvers = macOSvers.macOS
    static var OSname: String = ""
    static var OSBuildNum: String = "19G101"
    static var osPrefix: String = "macOS"
    static var dataHasBeenSet: Bool = false
    
    static func getVersion() {
        if (dataHasBeenSet) {return}
        osPrefix = "macOS"
        OSnum = getOSnum()
        OSBuildNum = getOSbuild()
        print(OSnum)
        setOSvers(osNumber: OSnum)
        OSname = macOSversToString()
        print("OS Build Number: \(OSBuildNum)")
        dataHasBeenSet = true
    }

    static func getOSnum() -> String {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        return "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
    }
  
    static func getOSbuild() -> String {
        var size = 0
        sysctlbyname("kern.osversion", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("kern.osversion", &machine, &size, nil, 0)
        let build = String(cString: machine)
        return " (\(build)) "
    }
    
    static func setOSvers(osNumber: String) {
        switch osNumber.prefix(2) {
            case "15": OSvers = macOSvers.SEQUOIA
            case "14": OSvers = macOSvers.SONOMA
            case "13": OSvers = macOSvers.VENTURA
            case "12": OSvers = macOSvers.MONTEREY
            case "11": OSvers = macOSvers.BIG_SUR
            case "10":
                switch osNumber.prefix(5) {
                    case "10.16": OSvers = macOSvers.BIG_SUR
                    case "10.15": OSvers = macOSvers.CATALINA
                    case "10.14": OSvers = macOSvers.MOJAVE
                    case "10.13": OSvers = macOSvers.HIGH_SIERRA
                    case "10.12": OSvers = macOSvers.SIERRA
                    default: OSvers = macOSvers.macOS
                }
            default: OSvers = macOSvers.macOS
        }
    }

    static func macOSversToString() -> String {
        switch OSvers {
            case .SIERRA: return "Sierra"
            case .HIGH_SIERRA: return "High Sierra"
            case .MOJAVE: return "Mojave"
            case .CATALINA: return "Catalina"
            case .BIG_SUR: return "Big Sur"
            case .MONTEREY: return "Monterey"
            case .VENTURA: return "Ventura"
            case .SONOMA: return "Sonoma"
            case .SEQUOIA: return "Sequoia"
            case .macOS: return ""
        }
    }

    static func getOSBuildInfo() -> String {
        let kernelVersion = getKernelVersion()
        let sipInfo = getSIPInfo()
        let oclpInfo = getOCLPInfo()
        
        var result = kernelVersion
        if !sipInfo.isEmpty { result += sipInfo }
        if !oclpInfo.isEmpty { result += oclpInfo }
        
        print("OS Build Info: \(result)")
        return result
    }

    private static func getKernelVersion() -> String {
        var size = 0
        sysctlbyname("kern.version", nil, &size, nil, 0)
        var kernel = [CChar](repeating: 0, count: size)
        sysctlbyname("kern.version", &kernel, &size, nil, 0)
        return String(cString: kernel)
    }
    
    private static func getSIPInfo() -> String {
        let csrConfig = csrActiveConfig()
        let sipStatus = (csrConfig == 0) ? "Enabled" : "Disabled"
        return "System Integrity Protection: \(sipStatus) (0x\(String(format:"%08x", csrConfig)))\n"
    }

    private static func csrActiveConfig() -> UInt32 {
        var config: UInt32 = 0
        var size = MemoryLayout<UInt32>.size
        sysctlbyname("kern.bootargs", nil, &size, nil, 0)
        var bootArgs = [CChar](repeating: 0, count: size)
        sysctlbyname("kern.bootargs", &bootArgs, &size, nil, 0)
        let bootArgsString = String(cString: bootArgs)
        if bootArgsString.contains("csr-active-config") {
            if let range = bootArgsString.range(of: "csr-active-config=(0x[0-9a-fA-F]+)", options: .regularExpression) {
                let valueString = String(bootArgsString[range].dropFirst(19))
                config = UInt32(valueString, radix: 16) ?? 0
            }
        } else {
            sysctlbyname("kern.csr_active_config", &config, &size, nil, 0)
        }
        return config
    }

    private static func getOCLPInfo() -> String {
        guard FileManager.default.fileExists(atPath: initGlobVar.oclpXmlFilePath),
              let xmlData = FileManager.default.contents(atPath: initGlobVar.oclpXmlFilePath),
              let xmlString = String(data: xmlData, encoding: .utf8) else {
            return ""
        }
        
        var oclpInfo = ""
        
        if let versionRange = xmlString.range(of: "<key>OpenCore Legacy Patcher</key>\\s*<string>([^<]+)</string>", options: .regularExpression) {
            let startIndex = xmlString.index(versionRange.lowerBound, offsetBy: "<key>OpenCore Legacy Patcher</key><string>".count)
            let endIndex = xmlString.index(versionRange.upperBound, offsetBy: -"</string>".count)
            oclpInfo += "OCLP \(xmlString[startIndex..<endIndex])"
        }
        
        if let commitRange = xmlString.range(of: "<key>Commit URL</key>\\s*<string>[^/]+/([^<]+)</string>", options: .regularExpression) {
            let startIndex = xmlString.index(commitRange.lowerBound, offsetBy: "<key>Commit URL</key><string>".count)
            let endIndex = xmlString.index(commitRange.upperBound, offsetBy: -"</string>".count)
            let commit = String(xmlString[startIndex..<endIndex].split(separator: "/").last ?? "")
            oclpInfo += " (\(commit.prefix(7)))"
        }
        
        if let dateRange = xmlString.range(of: "<key>Time Patched</key>\\s*<string>([^<]+)</string>", options: .regularExpression) {
            let startIndex = xmlString.index(dateRange.lowerBound, offsetBy: "<key>Time Patched</key><string>".count)
            let endIndex = xmlString.index(dateRange.upperBound, offsetBy: -"</string>".count)
            let date = xmlString[startIndex..<endIndex].replacingOccurrences(of: "@", with: "")
            oclpInfo += " (\(date))"
        }
        
        return oclpInfo.isEmpty ? "" : oclpInfo + "\n"
    }
}

extension String {
    func captureGroup(at index: Int) -> String? {
        let range = NSRange(self.startIndex..., in: self)
        guard let regex = try? NSRegularExpression(pattern: self),
              let match = regex.firstMatch(in: self, options: [], range: range),
              let captureRange = Range(match.range(at: index), in: self) else {
            return nil
        }
        return String(self[captureRange])
    }
}

enum macOSvers {
    case SIERRA
    case HIGH_SIERRA
    case MOJAVE
    case CATALINA
    case BIG_SUR
    case MONTEREY
    case VENTURA
    case SONOMA
    case SEQUOIA
    case macOS
}


