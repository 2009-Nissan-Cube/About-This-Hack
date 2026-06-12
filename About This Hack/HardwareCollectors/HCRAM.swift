import Foundation

class HCRAM {
    static let shared = HCRAM()
    private init() {}

    // Shared parsed memory lines for efficiency
    private lazy var parsedMemoryLines: [String] = {
        ATHLogger.debug(NSLocalizedString("log.ram.parsing_lines", comment: "Parsing memory file lines"), category: .hardware)
        guard let content = HardwareCollector.shared.memoryData else {
            ATHLogger.error(NSLocalizedString("log.ram.no_data", comment: "No RAM data available from HardwareCollector"), category: .hardware)
            return []
        }
        return content.components(separatedBy: .newlines)
    }()

    private lazy var memoryInfo: (total: Int, type: String, speed: String) = {
        ATHLogger.debug(NSLocalizedString("log.ram.init", comment: "Initializing RAM Info"), category: .hardware)
        let memSize = Int(ProcessInfo.processInfo.physicalMemory / 1_073_741_824) // Convert to GB and cast to Int
        ATHLogger.debug(String(format: NSLocalizedString("log.ram.size", comment: "RAM Total Size"), memSize), category: .hardware)
        let (type, speed) = parseMemoryDetails()
        ATHLogger.debug(String(format: NSLocalizedString("log.ram.type_speed", comment: "RAM Type and Speed"), type, speed), category: .hardware)
        return (memSize, type, speed)
    }()
    
    func getRam() -> String {
        ATHLogger.debug(NSLocalizedString("log.ram.getting_string", comment: "Getting RAM string"), category: .hardware)
        var result = "\(memoryInfo.total) GB"
        if !memoryInfo.speed.isEmpty { result += " \(memoryInfo.speed)" }
        if memoryInfo.type.contains("D") { result += " \(memoryInfo.type)" }
        return result
    }
    
    private func parseMemoryDetails() -> (type: String, speed: String) {
        ATHLogger.debug(NSLocalizedString("log.ram.parsing_details", comment: "Parsing memory details from shared lines"), category: .hardware)

        // Use shared parsed lines instead of re-parsing
        let type = parsedMemoryLines.first { $0.contains("Type") }?.components(separatedBy: ": ").last ?? ""
        let speed = parsedMemoryLines.first { $0.contains("Speed") && $0.contains("MHz") }?.components(separatedBy: ": ").last ?? ""

        return (type, speed)
    }
}
