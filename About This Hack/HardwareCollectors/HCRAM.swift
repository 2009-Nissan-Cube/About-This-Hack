import Foundation

class HCRAM {
    static let shared = HCRAM()
    private init() {}
    
    private lazy var memoryInfo: (total: Int, type: String, speed: String) = {
        ATHLogger.debug("Initializing RAM Info...", category: .hardware)
        let memSize = Int(ProcessInfo.processInfo.physicalMemory / 1_073_741_824) // Convert to GB and cast to Int
        ATHLogger.debug("RAM Total Size (GB): \(memSize)", category: .hardware)
        let (type, speed) = parseMemoryDetails()
        ATHLogger.debug("RAM Type: \(type), Speed: \(speed)", category: .hardware)
        return (memSize, type, speed)
    }()
    
    func getRam() -> String {
        ATHLogger.debug("Getting RAM string...", category: .hardware)
        var result = "\(memoryInfo.total) GB"
        if !memoryInfo.speed.isEmpty { result += " \(memoryInfo.speed)" }
        if memoryInfo.type.contains("D") { result += " \(memoryInfo.type)" }
        return result
    }
    
    func getMemDesc() -> String {
        ATHLogger.debug("Getting RAM description string...", category: .hardware)
        
        // Use cached data from HardwareCollector
        guard let content = HardwareCollector.shared.getCachedFileContent(InitGlobVar.sysmemFilePath) else {
            ATHLogger.error("No RAM description available from HardwareCollector", category: .hardware)
            return ""
        }
        
        ATHLogger.debug("Successfully retrieved RAM description from HardwareCollector.", category: .hardware)
        
        return content.components(separatedBy: .newlines)
            .filter { line in
                ["ECC:", "BANK", "Size:", "Type:", "Speed:", "Manufacturer:", "Part Number:"]
                    .contains { line.contains($0) }
            }
            .joined(separator: "\n")
    }

    func getMemDescArray() -> String {
        ATHLogger.debug("Getting RAM description array string...", category: .hardware)
        
        // Use cached data from HardwareCollector
        guard let content = HardwareCollector.shared.getCachedFileContent(InitGlobVar.sysmemFilePath) else {
            ATHLogger.error("No RAM description available from HardwareCollector for array", category: .hardware)
            return ""
        }
        
        ATHLogger.debug("Successfully retrieved RAM description from HardwareCollector for array.", category: .hardware)
        
        let relevantLines = content.components(separatedBy: .newlines)
            .filter { line in
                ["BANK", "Size:", "Type:", "Speed:", "Manufacturer:", "Part Number:"]
                    .contains { line.contains($0) }
            }
            .map { $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ":", with: ": ") }
        
        return relevantLines
            .split(whereSeparator: { $0.starts(with: "BANK") })
            .map { "BANK " + $0.joined(separator: " ") }
            .joined(separator: "\n")
    }
    
    private func parseMemoryDetails() -> (type: String, speed: String) {
        ATHLogger.debug("Parsing memory details from HardwareCollector...", category: .hardware)
        
        // Use cached data from HardwareCollector
        guard let content = HardwareCollector.shared.getCachedFileContent(InitGlobVar.sysmemFilePath) else {
            ATHLogger.error("No memory details available from HardwareCollector for parsing", category: .hardware)
            return ("", "")
        }
        
        let lines = content.components(separatedBy: .newlines)
        let type = lines.first { $0.contains("Type") }?.components(separatedBy: ": ").last ?? ""
        let speed = lines.first { $0.contains("Speed") && $0.contains("MHz") }?.components(separatedBy: ": ").last ?? ""
        
        return (type, speed)
    }
}
