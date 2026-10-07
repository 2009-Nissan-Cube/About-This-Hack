//
//  HardwareCollector.swift
//  HardwareCollector
//

import Foundation

/// Loads the slow `system_profiler` reports once, in the background.
/// Everything on first paint comes from native APIs; these reports only
/// enrich tooltips, the memory type, and the Clover/GPU fallbacks.
final class HardwareCollector {
    static let shared = HardwareCollector()
    private init() {}

    /// Posted on the main thread once the profiler reports are loaded.
    static let dataDidLoadNotification = Notification.Name("HardwareCollectorDataDidLoad")

    private let lock = NSLock()
    private var reports: [String: String] = [:]
    private var started = false

    /// `system_profiler SPHardwareDataType` output without its section header.
    var hardwareData: String? { report("SPHardwareDataType") }

    /// `system_profiler SPMemoryDataType` output without its section header.
    var memoryData: String? { report("SPMemoryDataType") }

    /// `system_profiler SPDisplaysDataType` output; only loaded when Metal reports no GPU.
    var displaysData: String? { report("SPDisplaysDataType") }

    /// Contents of the OpenCore Legacy Patcher plist, if present.
    let oclpData: String? = try? String(contentsOfFile: InitGlobVar.oclpXmlFilePath, encoding: .utf8)

    func loadInBackground() {
        lock.lock()
        defer { lock.unlock() }
        guard !started else { return }
        started = true

        // The first free-space query costs ~15 ms; keep it off the main thread.
        DispatchQueue.global(qos: .userInitiated).async {
            _ = HCStartupDisk.shared.getStartupDisk()
        }
        DispatchQueue.global(qos: .userInitiated).async { [self] in
            var types = ["SPHardwareDataType", "SPMemoryDataType"]
            if HCGPU.shared.needsProfilerFallback {
                types.append("SPDisplaysDataType")
            }

            DispatchQueue.concurrentPerform(iterations: types.count) { index in
                let output = Self.profile(types[index])
                lock.lock()
                reports[types[index]] = output
                lock.unlock()
            }

            ATHLogger.info(NSLocalizedString("log.data.files_created", comment: "Data files created successfully"), category: .system)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Self.dataDidLoadNotification, object: nil)
            }
        }
    }

    private func report(_ type: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return reports[type]?.nilIfEmpty
    }

    private static func profile(_ type: String) -> String {
        let result = executeProcess(executableURL: URL(fileURLWithPath: "/usr/sbin/system_profiler"), arguments: [type])
        guard result.succeeded else {
            ATHLogger.warning("\(type) failed with status \(result.terminationStatus): \(result.combinedOutput)", category: .hardware)
            return ""
        }

        // Drop unindented section headers such as "Hardware:" and "Memory:".
        return result.stdout
            .components(separatedBy: .newlines)
            .filter { !($0.hasSuffix(":") && !$0.hasPrefix(" ")) }
            .joined(separator: "\n")
    }
}
