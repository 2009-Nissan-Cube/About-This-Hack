import Foundation

final class HCRAM {
    static let shared = HCRAM()
    private init() {}

    private let totalGB = Int(ProcessInfo.processInfo.physicalMemory / 1_073_741_824)

    /// e.g. "48 GB LPDDR5" or "16 GB 2667 MHz DDR4". Type and speed appear once
    /// `system_profiler` has loaded; empty slots and unknown values are skipped.
    func getRam() -> String {
        let report = HardwareCollector.shared.memoryData
        let speed = profilerValues("Speed", in: report).first { $0.contains("MHz") || $0.contains("MT/s") }
        let type = profilerValues("Type", in: report).first { Self.isKnown($0) }
        return ["\(totalGB) GB", speed, type].compactMap { $0 }.joined(separator: " ")
    }

    private static func isKnown(_ value: String) -> Bool {
        !["", "empty", "unknown", "-"].contains(value.lowercased())
    }
}
