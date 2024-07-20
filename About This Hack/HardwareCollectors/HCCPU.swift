import Foundation

class HCCPU {
    static let shared = HCCPU()
    private init() {}
    
    private lazy var cpuInfo: (brand: String, details: String) = {
        let brand = run("sysctl -n machdep.cpu.brand_string").trimmingCharacters(in: .whitespacesAndNewlines)
        let details = getCPUDetails()
        return (brand, details)
    }()
    
    func getCPU() -> String {
        return cpuInfo.brand
    }
    
    func getCPUInfo() -> String {
        return cpuInfo.details
    }
    
    private func getCPUDetails() -> String {
        guard let content = try? String(contentsOfFile: InitGlobVar.hwFilePath, encoding: .utf8) else {
            return "Unable to read CPU details"
        }
        
        return content.components(separatedBy: .newlines)
            .drop { !$0.contains("Processor Name:") }
            .prefix { !$0.contains("Memory:") }
            .joined(separator: "\n")
    }
}
