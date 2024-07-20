import Foundation

class HCRAM {
    static let memoryInfo: (total: Int, type: String, speed: String) = {
        let memSize = Int(ProcessInfo.processInfo.physicalMemory / 1_073_741_824) // Convert to GB and cast to Int
        let sysMemContent = (try? String(contentsOfFile: InitGlobVar.sysmemFilePath, encoding: .utf8)) ?? ""
        let lines = sysMemContent.components(separatedBy: .newlines)
        
        let type = lines.first { $0.contains("Type") }?.components(separatedBy: " ").last ?? ""
        let speed = lines.first { $0.contains("Speed") && $0.contains("MHz") }?
            .components(separatedBy: " ")
            .dropFirst()
            .prefix(2)
            .joined(separator: " ") ?? ""
        
        return (memSize, type, speed)
    }()
    
    static func getRam() -> String {
        var result = "\(memoryInfo.total) GB"
        if !memoryInfo.speed.isEmpty { result += " \(memoryInfo.speed)" }
        if memoryInfo.type.contains("D") { result += " \(memoryInfo.type)" }
        return result
    }
    
    static func getMemDesc() -> String {
        guard let content = try? String(contentsOfFile: InitGlobVar.sysmemFilePath, encoding: .utf8) else {
            return ""
        }
        
        let relevantLines = content.components(separatedBy: .newlines)
            .filter { line in
                ["ECC:", "BANK", "Size:", "Type:", "Speed:", "Manufacturer:", "Part Number:"]
                    .contains { line.contains($0) }
            }
        
        return relevantLines.joined(separator: "\n")
    }

    static func getMemDescArray() -> String {
        guard let content = try? String(contentsOfFile: InitGlobVar.sysmemFilePath, encoding: .utf8) else {
            return ""
        }
        
        let relevantLines = content.components(separatedBy: .newlines)
            .filter { line in
                ["BANK", "Size:", "Type:", "Speed:", "Manufacturer:", "Part Number:"]
                    .contains { line.contains($0) }
            }
            .map { $0.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ":", with: ": ") }
        
        let banks = relevantLines.split(whereSeparator: { $0.starts(with: "BANK") })
        
        return banks.map { "BANK " + $0.joined(separator: " ") }
            .joined(separator: "\n")
    }
}
