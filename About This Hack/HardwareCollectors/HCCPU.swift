import Foundation

class HCCPU {
    static let shared = HCCPU()
    private init() {}
    
    private lazy var cpuInfo: (brand: String, details: String, coreCount: Int) = {
        ATHLogger.debug(NSLocalizedString("log.cpu.init", comment: "Initializing CPU Info"), category: .hardware)
        let brand = getSysctlValueByKey(inputKey: "machdep.cpu.brand_string")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown CPU"
        ATHLogger.debug(String(format: NSLocalizedString("log.cpu.brand", comment: "CPU Brand"), brand), category: .hardware)
        let details = getCPUDetails()
        ATHLogger.debug(String(format: NSLocalizedString("log.cpu.details", comment: "CPU Details"), details), category: .hardware)
        let coreCount = getCPUCoreCount()
        ATHLogger.debug(String(format: NSLocalizedString("log.cpu.core_count", comment: "CPU Core Count"), coreCount), category: .hardware)
        return (brand, details, coreCount)
    }()
    
    func getCPU() -> String {
        ATHLogger.debug(NSLocalizedString("log.cpu.getting_info", comment: "Getting CPU info"), category: .hardware)
        // Use cached core count from cpuInfo instead of calling getCPUCoreCount() again
        let cpuCoreCount = cpuInfo.coreCount
        let modifiedBrand = cpuInfo.brand.replacingOccurrences(of: "(R)", with: "").replacingOccurrences(of: "(TM)", with: "")

        if cpuCoreCount >= 2 {
            return "\(cpuCoreCount)x \(modifiedBrand)"
        } else {
            return modifiedBrand
        }
    }
    
    func getCPUInfo() -> String {
        ATHLogger.debug(NSLocalizedString("log.cpu.getting_details", comment: "Getting CPU details string"), category: .hardware)
        return cpuInfo.details
    }
    
    func getCPUCoreCount() -> Int {
        ATHLogger.debug(NSLocalizedString("log.cpu.getting_core_count", comment: "Getting CPU core count"), category: .hardware)
        var count: UInt32 = 0
        var size = MemoryLayout<UInt32>.size
        let result = sysctlbyname("hw.packages", &count, &size, nil, 0)
        
        if result == 0 {
             ATHLogger.debug(String(format: NSLocalizedString("log.cpu.core_count_packages", comment: "CPU Core count hw.packages"), Int(count)), category: .hardware)
             return Int(count)
        } else {
            ATHLogger.warning(String(format: NSLocalizedString("log.cpu.failed_packages", comment: "Failed to get physical CPU count via hw.packages"), String(cString: strerror(errno))), category: .hardware)
            // Fallback or alternative method can be added here if needed
            // For now, let's try hw.physicalcpu
            var physicalCPU: UInt32 = 0
            var sizePhysical = MemoryLayout<UInt32>.size
            if sysctlbyname("hw.physicalcpu", &physicalCPU, &sizePhysical, nil, 0) == 0 {
                ATHLogger.debug(String(format: NSLocalizedString("log.cpu.core_count_physical", comment: "CPU Core count hw.physicalcpu"), Int(physicalCPU)), category: .hardware)
                return Int(physicalCPU)
            } else {
                ATHLogger.warning(String(format: NSLocalizedString("log.cpu.failed_physical", comment: "Failed to get physical CPU count via hw.physicalcpu"), String(cString: strerror(errno))), category: .hardware)
            }
            // And hw.logicalcpu as another fallback
            var logicalCPU: UInt32 = 0
            var sizeLogical = MemoryLayout<UInt32>.size
            if sysctlbyname("hw.logicalcpu", &logicalCPU, &sizeLogical, nil, 0) == 0 {
                ATHLogger.debug(String(format: NSLocalizedString("log.cpu.core_count_logical", comment: "CPU Core count hw.logicalcpu"), Int(logicalCPU)), category: .hardware)
                return Int(logicalCPU)
            } else {
                ATHLogger.error(String(format: NSLocalizedString("log.cpu.failed_any_count", comment: "Failed to get any CPU count"), String(cString: strerror(errno))), category: .hardware)
            }
            return -1
        }
    }
    
    private func getCPUDetails() -> String {
        ATHLogger.debug(NSLocalizedString("log.cpu.fetching_details", comment: "Fetching CPU details from hwFilePath"), category: .hardware)
        guard let content = HardwareCollector.shared.getCachedFileContent(InitGlobVar.hwFilePath) else {
            ATHLogger.error(String(format: NSLocalizedString("log.cpu.failed_read_details", comment: "Unable to read CPU details from hwFilePath"), InitGlobVar.hwFilePath), category: .hardware)
            return "Unable to read CPU details"
        }
        
        return content.components(separatedBy: .newlines)
            .drop { !$0.contains("Processor Name:") }
            .prefix { !$0.contains("Memory:") }
            .joined(separator: "\n")
    }
}
