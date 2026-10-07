import Foundation

final class HCCPU {
    static let shared = HCCPU()
    static let isAppleSilicon = getSysctlIntByKey("hw.optional.arm64") == 1

    /// Display name, e.g. "Apple M4 Pro (14-Core)" or "3.6 GHz 8-Core Intel Core i9-9900K".
    private let name: String

    private init() {
        let brand = getSysctlValueByKey(inputKey: "machdep.cpu.brand_string")?.collapsingWhitespace.nilIfEmpty ?? "Unknown CPU"
        let packages = max(getSysctlIntByKey("hw.packages") ?? 1, 1)
        let cores = (getSysctlIntByKey("hw.physicalcpu") ?? 0) / packages
        name = Self.displayName(brand: brand, coresPerPackage: cores, packages: packages)
        ATHLogger.debug(String(format: NSLocalizedString("log.cpu.brand", comment: "CPU Brand"), name), category: .hardware)
    }

    static func displayName(brand: String, coresPerPackage cores: Int, packages: Int) -> String {
        var model = brand
        for noise in ["(R)", "(TM)", "(tm)", " CPU", " Processor"] {
            model = model.replacingOccurrences(of: noise, with: "")
        }

        // "Intel Core i9-9900K @ 3.60GHz" -> "3.6 GHz" + "Intel Core i9-9900K"
        var frequency = ""
        if let at = model.range(of: "@") {
            let raw = model[at.upperBound...].trimmingCharacters(in: .whitespaces)
            let number = raw.prefix { $0.isNumber || $0 == "." }
            if let value = Double(number) {
                let unit = raw.dropFirst(number.count).trimmingCharacters(in: .whitespaces)
                frequency = String(format: "%g %@", value, unit.isEmpty ? "GHz" : unit)
            }
            model = String(model[..<at.lowerBound])
        }
        model = model.collapsingWhitespace

        let hasCoreCount = model.range(of: "-Core", options: .caseInsensitive) != nil
        let coreLabel = cores > 0 && !hasCoreCount ? "\(cores)-Core" : ""
        let packagePrefix = packages > 1 ? "\(packages) x " : ""

        if model.hasPrefix("Apple") {
            return coreLabel.isEmpty ? packagePrefix + model : "\(packagePrefix)\(model) (\(coreLabel))"
        }
        return packagePrefix + [frequency, coreLabel, model].filter { !$0.isEmpty }.joined(separator: " ")
    }

    func getCPU() -> String {
        name
    }

    /// Processor lines from `system_profiler`, empty until the report has loaded.
    func getCPUInfo() -> String {
        // Intel reports "Processor Name:"; Apple silicon reports "Chip:".
        (HardwareCollector.shared.hardwareData ?? "")
            .components(separatedBy: .newlines)
            .drop { !$0.contains("Processor Name:") && !$0.contains("Chip:") }
            .prefix { !$0.contains("Memory:") }
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")
    }
}
