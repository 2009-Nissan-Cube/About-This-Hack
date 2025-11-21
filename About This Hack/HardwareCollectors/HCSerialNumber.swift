import Foundation

class HCSerialNumber {
    static let shared = HCSerialNumber()
    private init() {}
    
    private lazy var HardwareInfo: (serialNumber: String, details: String) = {
        ATHLogger.debug(NSLocalizedString("log.serial.init", comment: "Initializing Serial Number & Hardware Info"), category: .hardware)
        
        // Use cached data from HardwareCollector
        guard let content = HardwareCollector.shared.getCachedFileContent(InitGlobVar.hwFilePath) else {
            ATHLogger.error(NSLocalizedString("log.serial.no_hardware_info", comment: "No hardware info available from HardwareCollector for serial number"), category: .hardware)
            return ("", "")
        }
        
        ATHLogger.debug(NSLocalizedString("log.serial.retrieved", comment: "Successfully retrieved hardware info"), category: .hardware)
        
        let lines = content.components(separatedBy: .newlines)
        
        let serialNumber = lines.first { $0.contains("Serial") }?
            .components(separatedBy: .whitespaces)
            .last ?? ""
        ATHLogger.debug(String(format: NSLocalizedString("log.serial.parsed", comment: "Parsed Serial Number"), serialNumber), category: .hardware)
        
        let relevantKeys = [
            "System Firmware Version", "OS Loader Version", "SMC Version",
            "Apple ROM Info:", "Board-ID :", "Hardware UUID:", "Provisioning UDID:"
        ]
        
        let formattedDetails = lines
            .filter { line in relevantKeys.contains { line.contains($0) } }
            .map { "      " + $0.trimmingCharacters(in: .whitespaces) }
            .map { line in
                line.components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
            }
            .joined(separator: "\n")
        ATHLogger.debug(String(format: NSLocalizedString("log.serial.formatted_details", comment: "Formatted Hardware Details"), formattedDetails), category: .hardware)
        
        return (serialNumber, formattedDetails)
    }()
    
    func getSerialNumber() -> String {
        ATHLogger.debug(NSLocalizedString("log.serial.getting_string", comment: "Getting serial number string"), category: .hardware)
        return HardwareInfo.serialNumber
    }
    
    func getHardwareInfo() -> String {
        ATHLogger.debug(NSLocalizedString("log.serial.getting_details", comment: "Getting hardware info details string"), category: .hardware)
        return HardwareInfo.details
    }
}
