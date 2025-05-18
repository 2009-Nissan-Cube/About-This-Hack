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
        guard let content = try? String(contentsOfFile: InitGlobVar.sysmemFilePath, encoding: .utf8) else {
            ATHLogger.error("Failed to read RAM description from \(InitGlobVar.sysmemFilePath)", category: .hardware)
            return ""
        }
        ATHLogger.debug("Successfully read \(InitGlobVar.sysmemFilePath) for RAM description.", category: .hardware)
        
        return content.components(separatedBy: .newlines)
            .filter { line in
                ["ECC:", "BANK", "Size:", "Type:", "Speed:", "Manufacturer:", "Part Number:"]
                    .contains { line.contains($0) }
            }
            .joined(separator: "\n")
    }

    func getMemDescArray() -> String {
        ATHLogger.debug("Getting RAM description array string...", category: .hardware)
        guard let content = try? String(contentsOfFile: InitGlobVar.sysmemFilePath, encoding: .utf8) else {
            ATHLogger.error("Failed to read RAM description for array from \(InitGlobVar.sysmemFilePath)", category: .hardware)
            return ""
        }
        ATHLogger.debug("Successfully read \(InitGlobVar.sysmemFilePath) for RAM description array.", category: .hardware)
        
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
        ATHLogger.debug("Parsing memory details from \(InitGlobVar.sysmemFilePath)...", category: .hardware)
        guard let content = try? String(contentsOfFile: InitGlobVar.sysmemFilePath, encoding: .utf8) else {
            ATHLogger.error("Failed to read memory details for parsing from \(InitGlobVar.sysmemFilePath)", category: .hardware)
            return ("", "")
        }
        
        let lines = content.components(separatedBy: .newlines)
        let type = lines.first { $0.contains("Type") }?.components(separatedBy: ": ").last ?? ""
        let speed = lines.first { $0.contains("Speed") && $0.contains("MHz") }?.components(separatedBy: ": ").last ?? ""
        
        return (type, speed)
    }
}
