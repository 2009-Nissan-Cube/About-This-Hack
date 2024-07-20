import Cocoa
import Foundation

class HCCPU {
    static let cpuInfo: (brand: String, details: String) = {
        let brand = run("sysctl -n machdep.cpu.brand_string").trimmingCharacters(in: .whitespacesAndNewlines)
        let details = getCPUDetails()
        return (brand, details)
    }()
    
    static func getCPU() -> String {
        return cpuInfo.brand
    }
    
    static func getCPUInfo() -> String {
        return cpuInfo.details
    }
    
    private static func getCPUDetails() -> String {
        guard let content = try? String(contentsOfFile: InitGlobVar.hwFilePath, encoding: .utf8) else {
            return "Unable to read CPU details"
        }
        
        let lines = content.components(separatedBy: .newlines)
        var processorSection = false
        var processorInfo: [String] = []
        
        for (index, line) in lines.enumerated() {
            if line.contains("Processor Name:") {
                processorSection = true
                processorInfo.append(line)
            } else if processorSection {
                if line.contains("Memory:") {
                    break
                }
                processorInfo.append(line)
            }
        }
        
        return processorInfo.joined(separator: "\n")
    }
}
