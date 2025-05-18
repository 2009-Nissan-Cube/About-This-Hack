import Foundation

class HCCPU {
    static let shared = HCCPU()
    private init() {}
    
    private lazy var cpuInfo: (brand: String, details: String, coreCount: Int) = {
        let brand = getSysctlValueByKey(inputKey: "machdep.cpu.brand_string")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown CPU"
        let details = getCPUDetails()
        let coreCount = getCPUCoreCount()
        return (brand, details, coreCount)
    }()
    
    func getCPU() -> String {
        let cpuCoreCount = getCPUCoreCount()
        let modifiedBrand = cpuInfo.brand.replacingOccurrences(of: "(R)", with: "").replacingOccurrences(of: "(TM)", with: "")
        
        if cpuCoreCount >= 2 {
            return "\(cpuCoreCount)x \(modifiedBrand)"
        } else {
            return modifiedBrand
        }
    }
    
    func getCPUInfo() -> String {
        return cpuInfo.details
    }
    
    func getCPUCoreCount() -> Int {
        var count: UInt32 = 0
        var size = MemoryLayout<UInt32>.size
        let result = sysctlbyname("hw.packages", &count, &size, nil, 0)
        
        if result == 0 {
             return Int(count)
        } else {
            print("Failed to get physical CPU count")
            return -1
        }
    }
    
    private func getCPUDetails() -> String {
        guard let content = HardwareCollector.shared.getCachedFileContent(InitGlobVar.hwFilePath) else {
            return "Unable to read CPU details"
        }
        
        return content.components(separatedBy: .newlines)
            .drop { !$0.contains("Processor Name:") }
            .prefix { !$0.contains("Memory:") }
            .joined(separator: "\n")
    }
}
