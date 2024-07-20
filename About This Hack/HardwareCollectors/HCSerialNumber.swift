import Foundation

class HCSerialNumber {
    static let hardwareInfo: (serialNumber: String, details: String) = {
        guard let content = try? String(contentsOfFile: InitGlobVar.hwFilePath, encoding: .utf8) else {
            return ("", "")
        }
        
        let lines = content.components(separatedBy: .newlines)
        
        let serialNumber = lines.first { $0.contains("Serial") }?
            .components(separatedBy: .whitespaces)
            .last ?? ""
        
        let relevantLines = lines.filter { line in
            ["System Firmware Version", "OS Loader Version", "SMC Version",
             "Apple ROM Info:", "Board-ID :", "Hardware UUID:", "Provisioning UDID:"]
                .contains { line.contains($0) }
        }
        
        let formattedDetails = relevantLines
            .map { "      " + $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")
        
        return (serialNumber, formattedDetails)
    }()
    
    static func getSerialNumber() -> String {
        return hardwareInfo.serialNumber
    }
    
    static func getHardWareInfo() -> String {
        return hardwareInfo.details
    }
}
