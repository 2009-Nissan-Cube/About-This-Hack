import Foundation
import Metal

private struct GPUSnapshot {
    let name: String
    let memoryDescription: String
    let metalDescription: String
    let isLowPower: Bool
    let isRemovable: Bool
}

class HCGPU {
    static let shared = HCGPU()
    private init() {}

    private var _gpuInfo: [GPUSnapshot]?
    private let gpuLock = NSLock()

    private var gpuInfo: [GPUSnapshot] {
        gpuLock.lock()
        defer { gpuLock.unlock() }

        if let cached = _gpuInfo {
            return cached
        }

        let computed = computeGPUInfo()
        _gpuInfo = computed
        return computed
    }

    private func computeGPUInfo() -> [GPUSnapshot] {
        ATHLogger.debug(NSLocalizedString("log.gpu.init", comment: "Initializing GPU Info"), category: .hardware)

        let metalDevices = MTLCopyAllDevices().map { device in
            GPUSnapshot(
                name: normalizeGPUName(device.name),
                memoryDescription: formatMemory(device.recommendedMaxWorkingSetSize),
                metalDescription: "Metal Supported",
                isLowPower: device.isLowPower,
                isRemovable: device.isRemovable
            )
        }

        if !metalDevices.isEmpty {
            ATHLogger.debug(String(format: NSLocalizedString("log.gpu.parsing_data", comment: "Parsing GPU data"), metalDevices.count), category: .hardware)
            return metalDevices
        }

        // Some Hackintosh setups expose GPUs via system_profiler but not Metal.
        let profilerDevices = parseSystemProfilerGPUs()
        if profilerDevices.isEmpty {
            ATHLogger.error(NSLocalizedString("log.gpu.no_data", comment: "No GPU data available from HardwareCollector"), category: .hardware)
        } else {
            ATHLogger.debug(String(format: NSLocalizedString("log.gpu.parsing_data", comment: "Parsing GPU data"), profilerDevices.count), category: .hardware)
        }
        return profilerDevices
    }

    private func parseSystemProfilerGPUs() -> [GPUSnapshot] {
        guard let content = HardwareCollector.shared.displaysData else {
            return []
        }

        var devices: [GPUSnapshot] = []
        var currentName = ""
        var currentMemory = ""
        var currentMetal = ""
        var currentBus = ""

        func flushCurrent() {
            let trimmedName = currentName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedName.isEmpty else {
                currentName = ""
                currentMemory = ""
                currentMetal = ""
                currentBus = ""
                return
            }

            devices.append(
                GPUSnapshot(
                    name: normalizeGPUName(trimmedName),
                    memoryDescription: currentMemory,
                    metalDescription: currentMetal.isEmpty ? "Unknown" : currentMetal,
                    isLowPower: false,
                    isRemovable: currentBus.localizedCaseInsensitiveContains("PCIe") ||
                        currentBus.localizedCaseInsensitiveContains("External")
                )
            )

            currentName = ""
            currentMemory = ""
            currentMetal = ""
            currentBus = ""
        }

        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }

            if line.hasPrefix("Chipset Model:") {
                flushCurrent()
                currentName = line.replacingOccurrences(of: "Chipset Model:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("VRAM") {
                // e.g. "VRAM (Total): 8 GB" / "VRAM (Dynamic, Max): 1 GB"
                if let colon = line.firstIndex(of: ":") {
                    currentMemory = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
                }
            } else if line.hasPrefix("Metal Support:") || line.hasPrefix("Metal:") {
                if let colon = line.firstIndex(of: ":") {
                    currentMetal = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
                }
            } else if line.hasPrefix("Bus:") {
                if let colon = line.firstIndex(of: ":") {
                    currentBus = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
                }
            } else if line.hasPrefix("Displays:") {
                // Display section starts; keep current GPU and stop parsing nested display keys.
                continue
            }
        }
        flushCurrent()

        return devices
    }

    func getGPU() -> String {
        ATHLogger.debug(NSLocalizedString("log.gpu.getting_string", comment: "Getting GPU string"), category: .hardware)
        guard let primaryGPU = gpuInfo.first else {
            return "Unknown GPU"
        }

        var result = primaryGPU.name
        if !primaryGPU.memoryDescription.isEmpty {
            result += " \(primaryGPU.memoryDescription)"
        }
        if !primaryGPU.metalDescription.isEmpty {
            result += " (\(primaryGPU.metalDescription))"
        }
        return result.trimmingCharacters(in: .whitespaces)
    }

    func getGPUInfo() -> String {
        ATHLogger.debug(NSLocalizedString("log.gpu.getting_detailed_info", comment: "Getting detailed GPU info string"), category: .hardware)
        guard !gpuInfo.isEmpty else {
            return "Graphics\n"
        }

        var lines = ["Graphics"]
        for device in gpuInfo {
            lines.append(device.name)
            if !device.memoryDescription.isEmpty {
                lines.append("Memory: \(device.memoryDescription)")
            }
            lines.append("Metal: \(device.metalDescription)")
            lines.append("Low Power: \(device.isLowPower ? "Yes" : "No")")
            if device.isRemovable {
                lines.append("Removable: Yes")
            }
            lines.append("")
        }

        return lines.dropLast().joined(separator: "\n")
    }

    private func normalizeGPUName(_ name: String) -> String {
        name
            .replacingOccurrences(of: "Intel ", with: "")
            .replacingOccurrences(of: "NVIDIA ", with: "")
            .replacingOccurrences(of: "AMD ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func formatMemory(_ bytes: UInt64) -> String {
        guard bytes > 0 else {
            return ""
        }

        let gigabytes = Double(bytes) / 1_000_000_000
        if gigabytes >= 1 {
            return String(format: "%.1f GB", gigabytes)
        }

        let megabytes = Double(bytes) / 1_000_000
        return String(format: "%.0f MB", megabytes)
    }
}
