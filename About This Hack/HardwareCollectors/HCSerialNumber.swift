import Foundation

class HCSerialNumber {
    static let shared = HCSerialNumber()
    private init() {}
    
    private lazy var HardwareInfo: (serialNumber: String, details: String) = {
        ATHLogger.debug("Initializing Serial Number & Hardware Info...", category: .hardware)
        guard let content = try? String(contentsOfFile: InitGlobVar.hwFilePath, encoding: .utf8) else {
            ATHLogger.error("Failed to read hardware info from \(InitGlobVar.hwFilePath) for serial number.", category: .hardware)
            return ("", "")
        }
        ATHLogger.debug("Successfully read \(InitGlobVar.hwFilePath) for serial number and hardware info.", category: .hardware)
        
        let lines = content.components(separatedBy: .newlines)
        
        let serialNumber = lines.first { $0.contains("Serial") }?
            .components(separatedBy: .whitespaces)
            .last ?? ""
        ATHLogger.debug("Parsed Serial Number: \(serialNumber)", category: .hardware)
        
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
        ATHLogger.debug("Formatted Hardware Details: \n\(formattedDetails)", category: .hardware)
        
        return (serialNumber, formattedDetails)
    }()
    
    func getSerialNumber() -> String {
        ATHLogger.debug("Getting serial number string...", category: .hardware)
        return HardwareInfo.serialNumber
    }
    
    func getHardwareInfo() -> String {
        ATHLogger.debug("Getting hardware info details string...", category: .hardware)
        return HardwareInfo.details
    }
}
