import Foundation

class HCStartupDisk {
    static let shared = HCStartupDisk()
    private init() {}
    
    private lazy var startupDisk: String = {
        ATHLogger.debug("Initializing Startup Disk Info...", category: .hardware)
        guard let content = HardwareCollector.shared.getCachedFileContent(InitGlobVar.bootvolnameFilePath) else {
            ATHLogger.error("Failed to read startup disk info from HardwareCollector cache", category: .hardware)
            return ""
        }
        ATHLogger.debug("Successfully read \(InitGlobVar.bootvolnameFilePath) from cache.", category: .hardware)
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
        guard let content = HardwareCollector.shared.getCachedFileContent(InitGlobVar.storagedataFilePath) else {
            ATHLogger.error("Failed to read detailed startup disk info from HardwareCollector cache", category: .hardware)
            return ""
        }
        ATHLogger.debug("Successfully read \(InitGlobVar.storagedataFilePath) from cache.", category: .hardware)

        return content.components(separatedBy: .newlines)
            .drop { !$0.contains(startupDisk) && !$0.contains("Mount Point: /") }
            .prefix { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
