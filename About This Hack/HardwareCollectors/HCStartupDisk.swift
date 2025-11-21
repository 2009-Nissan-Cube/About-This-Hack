import Foundation

class HCStartupDisk {
    static let shared = HCStartupDisk()
    private init() {}
    
    private lazy var startupDisk: String = {
        ATHLogger.debug(NSLocalizedString("log.startup.init", comment: "Initializing Startup Disk Info"), category: .hardware)
        guard let content = HardwareCollector.shared.getCachedFileContent(InitGlobVar.bootvolnameFilePath) else {
            ATHLogger.error(NSLocalizedString("log.startup.failed_read_cache", comment: "Failed to read startup disk info from HardwareCollector cache"), category: .hardware)
            return ""
        }
        ATHLogger.debug(String(format: NSLocalizedString("log.startup.read_cache", comment: "Successfully read from cache"), InitGlobVar.bootvolnameFilePath), category: .hardware)
        let diskName = content.components(separatedBy: "\n")
            .first { $0.contains("Volume Name") }?
            .components(separatedBy: ":")
            .last?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        ATHLogger.debug(String(format: NSLocalizedString("log.startup.parsed_name", comment: "Parsed Startup Disk Name"), diskName), category: .hardware)
        return diskName
    }()
    
    func getStartupDisk() -> String {
        ATHLogger.debug(NSLocalizedString("log.startup.getting_name", comment: "Getting startup disk name string"), category: .hardware)
        return startupDisk
    }

    func getStartupDiskInfo() -> String {
        ATHLogger.debug(NSLocalizedString("log.startup.getting_detailed", comment: "Getting detailed startup disk info string"), category: .hardware)
        guard let content = HardwareCollector.shared.getCachedFileContent(InitGlobVar.storagedataFilePath) else {
            ATHLogger.error(NSLocalizedString("log.startup.failed_read_detailed_cache", comment: "Failed to read detailed startup disk info from HardwareCollector cache"), category: .hardware)
            return ""
        }
        ATHLogger.debug(String(format: NSLocalizedString("log.startup.read_storage_cache", comment: "Successfully read storage from cache"), InitGlobVar.storagedataFilePath), category: .hardware)

        return content.components(separatedBy: .newlines)
            .drop { !$0.contains(startupDisk) && !$0.contains("Mount Point: /") }
            .prefix { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
