import Foundation

class HCRAM {
    static let shared = HCRAM()
    private init() {}
    
    private lazy var memoryInfo: (total: Int, type: String, speed: String) = {
        let memSize = Int(ProcessInfo.processInfo.physicalMemory / 1_073_741_824) // Convert to GB and cast to Int
        let (type, speed) = parseMemoryDetails()
        return (memSize, type, speed)
    }()
    
    func getRam() -> String {
        var result = "\(memoryInfo.total) GB"
        if !memoryInfo.speed.isEmpty { result += " \(memoryInfo.speed)" }
        if memoryInfo.type.contains("D") { result += " \(memoryInfo.type)" }
        return result
    }
    
    func getMemDesc() -> String {
        guard let content = try? String(contentsOfFile: InitGlobVar.sysmemFilePath, encoding: .utf8) else {
            return ""
        }
        
        return content.components(separatedBy: .newlines)
            .filter { line in
                ["ECC:", "BANK", "Size:", "Type:", "Speed:", "Manufacturer:", "Part Number:"]
                    .contains { line.contains($0) }
            }
            .joined(separator: "\n")
    }

    func getMemDescArray() -> String {
        guard let content = try? String(contentsOfFile: InitGlobVar.sysmemFilePath, encoding: .utf8) else {
            return ""
        }
        
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
        guard let content = try? String(contentsOfFile: InitGlobVar.sysmemFilePath, encoding: .utf8) else {
            return ("", "")
        }
        
        let lines = content.components(separatedBy: .newlines)
        let type = lines.first { $0.contains("Type") }?.components(separatedBy: " ").last ?? ""
        let speed = lines.first { $0.contains("Speed") && $0.contains("MHz") }?
            .components(separatedBy: " ")
            .dropFirst()
            .prefix(2)
            .joined(separator: " ") ?? ""
        
        return (type, speed)
    }
}
