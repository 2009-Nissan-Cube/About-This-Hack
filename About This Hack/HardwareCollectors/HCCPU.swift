import Foundation

class HCCPU {
    static let shared = HCCPU()
    private init() {}
    
    private lazy var cpuInfo: (brand: String, details: String, packageCount: Int) = {
        ATHLogger.debug(NSLocalizedString("log.cpu.init", comment: "Initializing CPU Info"), category: .hardware)
        let brand = getSysctlValueByKey(inputKey: "machdep.cpu.brand_string")?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Unknown CPU"
        ATHLogger.debug(String(format: NSLocalizedString("log.cpu.brand", comment: "CPU Brand"), brand), category: .hardware)
        let details = getCPUDetails()
        ATHLogger.debug(String(format: NSLocalizedString("log.cpu.details", comment: "CPU Details"), details), category: .hardware)
        let packageCount = getCPUPackageCount()
        ATHLogger.debug(String(format: NSLocalizedString("log.cpu.core_count", comment: "CPU Core Count"), packageCount), category: .hardware)
        return (brand, details, packageCount)
    }()
    
    func getCPU() -> String {
        ATHLogger.debug(NSLocalizedString("log.cpu.getting_info", comment: "Getting CPU info"), category: .hardware)
        // packageCount is socket count. Only show Nx when there are multiple packages.
        let packageCount = cpuInfo.packageCount
        let modifiedBrand = cpuInfo.brand.replacingOccurrences(of: "(R)", with: "").replacingOccurrences(of: "(TM)", with: "")

        if packageCount > 1 {
            return "\(packageCount)x \(modifiedBrand)"
        } else {
            return modifiedBrand
        }
    }
    
    func getCPUInfo() -> String {
        ATHLogger.debug(NSLocalizedString("log.cpu.getting_details", comment: "Getting CPU details string"), category: .hardware)
        return cpuInfo.details
    }

    /// Physical package/socket count used for multi-CPU display (e.g. dual-socket Mac Pro).
    /// Returns 1 when package count cannot be determined, so callers never invent an Nx label
    /// from core/thread counts.
    func getCPUPackageCount() -> Int {
        ATHLogger.debug(NSLocalizedString("log.cpu.getting_core_count", comment: "Getting CPU core count"), category: .hardware)
        var count: UInt32 = 0
        var size = MemoryLayout<UInt32>.size
        let result = sysctlbyname("hw.packages", &count, &size, nil, 0)

        if result == 0, count > 0 {
            ATHLogger.debug(String(format: NSLocalizedString("log.cpu.core_count_packages", comment: "CPU Core count hw.packages"), Int(count)), category: .hardware)
            return Int(count)
        }

        ATHLogger.warning(String(format: NSLocalizedString("log.cpu.failed_packages", comment: "Failed to get physical CPU count via hw.packages"), String(cString: strerror(errno))), category: .hardware)
        // Do not fall back to physical/logical core counts: those would incorrectly produce
        // labels like "14x Apple M4 Pro" on single-package machines.
        return 1
    }

    /// Kept for callers that previously asked for "core count"; this is package/socket count.
    func getCPUCoreCount() -> Int {
        getCPUPackageCount()
    }
    
    private func getCPUDetails() -> String {
        ATHLogger.debug(NSLocalizedString("log.cpu.fetching_details", comment: "Fetching CPU details from hwFilePath"), category: .hardware)
        guard let content = HardwareCollector.shared.hardwareData else {
            ATHLogger.error(NSLocalizedString("log.cpu.failed_read_details", comment: "Unable to read CPU details"), category: .hardware)
            return "Unable to read CPU details"
        }
        
        // Intel reports "Processor Name:"; Apple Silicon reports "Chip:".
        return content.components(separatedBy: .newlines)
            .drop { line in
                !line.contains("Processor Name:") && !line.contains("Chip:")
            }
            .prefix { !$0.contains("Memory:") }
            .joined(separator: "\n")
    }
}
