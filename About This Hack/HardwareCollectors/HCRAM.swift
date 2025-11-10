import Foundation

class HCRAM {
    static let shared = HCRAM()
    private init() {}

    // Shared parsed memory lines for efficiency
    private lazy var parsedMemoryLines: [String] = {
        ATHLogger.debug("Parsing memory file lines...", category: .hardware)
        guard let content = HardwareCollector.shared.getCachedFileContent(InitGlobVar.sysmemFilePath) else {
            ATHLogger.error("No RAM data available from HardwareCollector", category: .hardware)
            return []
        }
        return content.components(separatedBy: .newlines)
    }()

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

        // Use shared parsed lines instead of re-parsing
        return parsedMemoryLines
            .filter { line in
                ["ECC:", "BANK", "Size:", "Type:", "Speed:", "Manufacturer:", "Part Number:"]
                    .contains { line.contains($0) }
            }
            .joined(separator: "\n")
    }

    func getMemDescArray() -> String {
        ATHLogger.debug("Getting RAM description array string...", category: .hardware)

        // Use shared parsed lines instead of re-parsing
        let relevantLines = parsedMemoryLines
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
        ATHLogger.debug("Parsing memory details from shared lines...", category: .hardware)

        // Use shared parsed lines instead of re-parsing
        let type = parsedMemoryLines.first { $0.contains("Type") }?.components(separatedBy: ": ").last ?? ""
        let speed = parsedMemoryLines.first { $0.contains("Speed") && $0.contains("MHz") }?.components(separatedBy: ": ").last ?? ""

        return (type, speed)
    }
}
