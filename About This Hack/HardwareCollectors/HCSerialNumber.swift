import Foundation

class HCSerialNumber {
    static let shared = HCSerialNumber()
    private init() {}
    
    private lazy var HardwareInfo: (serialNumber: String, details: String) = {
        guard let content = try? String(contentsOfFile: InitGlobVar.hwFilePath, encoding: .utf8) else {
            return ("", "")
        }
        
        let lines = content.components(separatedBy: .newlines)
        
        let serialNumber = lines.first { $0.contains("Serial") }?
            .components(separatedBy: .whitespaces)
            .last ?? ""
        
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
        
        return (serialNumber, formattedDetails)
    }()
    
    func getSerialNumber() -> String {
        return HardwareInfo.serialNumber
    }
    
    func getHardwareInfo() -> String {
        return HardwareInfo.details
    }
}
