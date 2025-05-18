import Foundation

class HCStartupDisk {
    static let shared = HCStartupDisk()
    private init() {}
    
    private lazy var startupDisk: String = {
        ATHLogger.debug("Initializing Startup Disk Info...", category: .hardware)
        guard let content = try? String(contentsOfFile: InitGlobVar.bootvolnameFilePath, encoding: .utf8) else {
            ATHLogger.error("Failed to read startup disk info from \(InitGlobVar.bootvolnameFilePath)", category: .hardware)
            return ""
        }
        ATHLogger.debug("Successfully read \(InitGlobVar.bootvolnameFilePath) for startup disk name.", category: .hardware)
        let diskName = content.components(separatedBy: "\n")
            .first { $0.contains("Volume Name") }?
            .components(separatedBy: ":")
            .last?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        ATHLogger.debug("Parsed Startup Disk Name: \(diskName)", category: .hardware)
        return diskName
    }()
    
    func getStartupDisk() -> String {
        ATHLogger.debug("Getting startup disk name string...", category: .hardware)
        return startupDisk
    }

    func getStartupDiskInfo() -> String {
        ATHLogger.debug("Getting detailed startup disk info string...", category: .hardware)
        guard let content = try? String(contentsOfFile: InitGlobVar.storagedataFilePath, encoding: .utf8) else {
            ATHLogger.error("Failed to read detailed startup disk info from \(InitGlobVar.storagedataFilePath)", category: .hardware)
            return ""
        }
        ATHLogger.debug("Successfully read \(InitGlobVar.storagedataFilePath) for detailed startup disk info.", category: .hardware)
        
        return content.components(separatedBy: .newlines)
            .drop { !$0.contains(startupDisk) && !$0.contains("Mount Point: /") }
            .prefix { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
