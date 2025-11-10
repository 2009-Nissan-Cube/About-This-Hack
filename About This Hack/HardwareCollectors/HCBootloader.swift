import Foundation

class HCBootloader {
    static let shared = HCBootloader()
    private init() {}
    
    private lazy var bootloaderInfo: String = {
        // Prioritize Apple Silicon check
        if run("sysctl -n machdep.cpu.brand_string").contains("Apple") {
            return "Apple iBoot"
        }

        // Cache nvram result to avoid multiple calls
        let nvramOutput = run("nvram \(InitGlobVar.nvramOpencoreVersion) 2>/dev/null")

        if !nvramOutput.isEmpty {
            let parts = nvramOutput.components(separatedBy: "\t")
            guard parts.count >= 2 else { return "Apple UEFI" }

            let versionPart = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let components = versionPart.split(separator: "-", maxSplits: 1)

            if components.count >= 2 {
                let buildType = String(components[0])
                let version = String(components[1])

                // Clean up version string
                let cleanVersion = version
                    .replacingOccurrences(of: " ", with: ".")
                    .trimmingCharacters(in: CharacterSet(charactersIn: "."))

                // Format build type
                let formattedBuildType: String
                switch buildType {
                case "REL": formattedBuildType = "(Release)"
                case "DEB": formattedBuildType = "(Debug)"
                default: formattedBuildType = buildType.isEmpty ? "" : "(\(buildType))"
                }

                return "OpenCore \(cleanVersion) \(formattedBuildType)".trimmingCharacters(in: .whitespaces)
            }
        }

        // Check for Clover using cached file content
        if let hwContent = HardwareCollector.shared.getCachedFileContent(InitGlobVar.hwFilePath) {
            let cloverLine = hwContent.components(separatedBy: .newlines)
                .first { $0.contains("Clover") }

            if let line = cloverLine,
               let colonIndex = line.firstIndex(of: ":") {
                let version = String(line[line.index(after: colonIndex)...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !version.isEmpty {
                    return "Clover \(version)"
                }
            }
        }

        // Fallback
        return "Apple UEFI"
    }()
    
    private lazy var bootargsInfo: String = {
        var bootargs = run("nvram -x boot-args 2>/dev/null | grep -A1 \"<key>boot-args</key>\" | tail -1 | awk -F \"<string>\" '{print $NF}' | awk -F \"<\\/string>\" '{print $1}'  | tr -d '\n'")
        
        if bootargs.isEmpty {
            bootargs = run("\(InitGlobVar.bdmesgExecID) 2>/dev/null | grep ' boot-args=' | tail -1 | awk -F ' boot-args=' '{print $NF}' | tr -d '\n'")
        }
        
        return bootargs.isEmpty ? "Empty/Unknown" : bootargs
    }()
    
    func getBootloader() -> String {
        return bootloaderInfo.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
    
    func getBootargs() -> String {
        return bootargsInfo
    }
}
