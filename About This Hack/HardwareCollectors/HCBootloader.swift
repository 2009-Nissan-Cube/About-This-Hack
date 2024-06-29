import Foundation

class HCBootloader {
    static let bootloaderInfo: (bootloader: String, bootargs: String) = {
        let nvramOutput = run("nvram -x")
        let bdmesgOutput = run(initGlobVar.bdmesgExecID)
        
        let bootloader = getBootloaderInfo(nvramOutput: nvramOutput, bdmesgOutput: bdmesgOutput)
        let bootargs = getBootargsInfo(nvramOutput: nvramOutput, bdmesgOutput: bdmesgOutput)
        
        return (bootloader, bootargs)
    }()
    
    static func getBootloader() -> String {
        return bootloaderInfo.bootloader
    }
    
    static func getBootargs() -> String {
        return bootloaderInfo.bootargs
    }
    
    private static func getBootloaderInfo(nvramOutput: String, bdmesgOutput: String) -> String {
        // Check for OpenCore
        if let opencoreVersion = nvramOutput.range(of: "\(initGlobVar.nvramOpencoreVersion)\\s+(.+)", options: .regularExpression) {
            let versionString = String(nvramOutput[opencoreVersion].split(separator: " ")[1])
            let components = versionString.split(separator: "-")
            if components.count >= 2 {
                let version = components[1].replacingOccurrences(of: " ", with: ".")
                let type = components[0].replacingOccurrences(of: "REL", with: "(Release)")
                    .replacingOccurrences(of: "N/A", with: "")
                    .replacingOccurrences(of: "DEB", with: "(Debug)")
                return "OpenCore \(version) \(type)"
            }
        }
        
        // Check for Clover
        if let cloverInfo = bdmesgOutput.range(of: "Starting Clover revision:\\s+(\\S+).*\\((\\w{7})\\)", options: .regularExpression) {
            let matches = bdmesgOutput[cloverInfo].split(separator: " ")
            if matches.count >= 4 {
                let revision = matches[3]
                let hash = String(matches[matches.count - 1].prefix(7))
                
                // Extract build info
                let buildInfo = extractCloverBuildInfo(from: bdmesgOutput)
                
                return "Clover r\(revision) (\(hash)) \(buildInfo)"
            }
        }
        
        // Check for Apple bootloader
        if run("sysctl -n machdep.cpu.brand_string").contains("Apple") {
            return "Apple iBoot"
        } else {
            return "Apple UEFI"
        }
    }
    
    private static func getBootargsInfo(nvramOutput: String, bdmesgOutput: String) -> String {
        if let bootArgs = nvramOutput.range(of: "<key>boot-args</key>\\s*<string>(.+?)</string>", options: .regularExpression) {
            return String(nvramOutput[bootArgs].split(separator: ">")[2].dropLast(9))
        }
        
        if let bootArgs = bdmesgOutput.range(of: "boot-args=(.+)", options: .regularExpression) {
            return String(bdmesgOutput[bootArgs].split(separator: "=")[1])
        }
        
        return "Empty/Unknown"
    }
    
    private static func extractCloverBuildInfo(from bdmesgOutput: String) -> String {
        var buildInfo = ""
        
        if let buildArgs = bdmesgOutput.range(of: "Build with: \\[Args:.*-b\\s+(\\w+)\\s+-t\\s+(\\w+)", options: .regularExpression) {
            let matches = bdmesgOutput[buildArgs].split(separator: " ")
            if matches.count >= 4 {
                let arg1 = matches[matches.count - 3].capitalized
                let arg2 = matches[matches.count - 1].capitalized
                buildInfo += "\(arg2)\(arg1) "
            }
        }
        
        if let buildId = bdmesgOutput.range(of: "Build id:.*-(\\d{14})", options: .regularExpression) {
            let dateString = String(bdmesgOutput[buildId].suffix(14))
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMddHHmmss"
            if let date = formatter.date(from: dateString) {
                formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
                buildInfo += formatter.string(from: date)
            }
        }
        
        return buildInfo.trimmingCharacters(in: .whitespaces)
    }
}
