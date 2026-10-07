import Foundation
import IOKit
import Metal

private struct GPUSnapshot {
    let name: String
    let vram: String
    let cores: Int?
    let metal: String
    let isLowPower: Bool
    let isRemovable: Bool

    /// e.g. "Apple M4 Pro (20-Core, Metal 4)" or "AMD Radeon Pro 5500M (8 GB, Metal 3)".
    var summary: String {
        let details = [vram, cores.map { "\($0)-Core" } ?? "", metal].filter { !$0.isEmpty }
        return details.isEmpty ? name : "\(name) (\(details.joined(separator: ", ")))"
    }
}

final class HCGPU {
    static let shared = HCGPU()
    private init() {}

    private let lock = NSLock()
    private var cachedMetalGPUs: [GPUSnapshot]?

    /// True when Metal sees no GPU and `system_profiler` is the only source.
    var needsProfilerFallback: Bool {
        metalGPUs.isEmpty
    }

    private var gpus: [GPUSnapshot] {
        let metal = metalGPUs
        return metal.isEmpty ? profilerGPUs() : metal
    }

    private var metalGPUs: [GPUSnapshot] {
        lock.lock()
        defer { lock.unlock() }
        if let cachedMetalGPUs {
            return cachedMetalGPUs
        }

        // High-performance internal GPUs first, then eGPUs, then integrated ones.
        // MTLCopyAllDevices does not force a GPU switch on dual-GPU MacBook Pros.
        let devices = MTLCopyAllDevices().sorted { rank($0) < rank($1) }
        let snapshots = devices.map { device in
            GPUSnapshot(
                name: device.name,
                vram: device.hasUnifiedMemory ? "" : dedicatedMemory(of: device),
                cores: registryInt("gpu-core-count", registryID: device.registryID),
                metal: metalVersion(of: device),
                isLowPower: device.isLowPower,
                isRemovable: device.isRemovable
            )
        }
        cachedMetalGPUs = snapshots
        return snapshots
    }

    private func rank(_ device: MTLDevice) -> Int {
        device.isLowPower ? 2 : (device.isRemovable ? 1 : 0)
    }

    private func metalVersion(of device: MTLDevice) -> String {
        if #available(macOS 26.0, *), device.supportsFamily(.metal4) {
            return "Metal 4"
        }
        if #available(macOS 13.0, *), device.supportsFamily(.metal3) {
            return "Metal 3"
        }
        return device.supportsFamily(.mac2) ? "Metal 2" : "Metal"
    }

    /// Exact VRAM from the GPU's registry entry, falling back to Metal's working-set estimate.
    private func dedicatedMemory(of device: MTLDevice) -> String {
        if let megabytes = registryInt("VRAM,totalMB", registryID: device.registryID), megabytes > 0 {
            return formatMegabytes(megabytes)
        }
        let bytes = device.recommendedMaxWorkingSetSize
        return bytes > 0 ? formatMegabytes(Int(bytes / 1_048_576)) : ""
    }

    private func registryInt(_ key: String, registryID: UInt64) -> Int? {
        guard let matching = IORegistryEntryIDMatching(registryID) else { return nil }
        let service = IOServiceGetMatchingService(kIOMainPortDefault, matching)
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }

        let options = IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)
        let value = IORegistryEntrySearchCFProperty(service, kIOServicePlane, key as CFString, kCFAllocatorDefault, options)
        if let number = value as? NSNumber {
            return number.intValue
        }
        if let data = value as? Data, data.count <= 8 {
            return data.reversed().reduce(0) { $0 << 8 | Int($1) }
        }
        return nil
    }

    private func formatMegabytes(_ megabytes: Int) -> String {
        megabytes >= 1024
            ? String(format: "%g GB", (Double(megabytes) / 1024 * 10).rounded() / 10)
            : "\(megabytes) MB"
    }

    /// Some Hackintosh setups expose GPUs via `system_profiler` but not Metal.
    private func profilerGPUs() -> [GPUSnapshot] {
        var devices: [GPUSnapshot] = []
        var fields: [String: String] = [:]

        func flush() {
            if let name = fields["Chipset Model"]?.nilIfEmpty {
                let bus = fields["Bus"] ?? ""
                devices.append(GPUSnapshot(
                    name: name,
                    vram: fields["VRAM"] ?? "",
                    cores: fields["Total Number of Cores"].flatMap { Int($0) },
                    metal: fields["Metal"] ?? "",
                    isLowPower: false,
                    isRemovable: bus.localizedCaseInsensitiveContains("PCIe") || bus.localizedCaseInsensitiveContains("External")
                ))
            }
            fields = [:]
        }

        for rawLine in (HardwareCollector.shared.displaysData ?? "").components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard let colon = line.firstIndex(of: ":") else { continue }
            var key = String(line[..<colon])
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)

            if key == "Chipset Model" {
                flush()
            } else if key.hasPrefix("VRAM") {
                key = "VRAM" // "VRAM (Total)" / "VRAM (Dynamic, Max)"
            } else if key.hasPrefix("Metal") {
                key = "Metal" // "Metal Support" / "Metal Family" / "Metal"
            }
            if fields[key] == nil {
                fields[key] = value
            }
        }
        flush()
        return devices
    }

    func getGPU() -> String {
        gpus.first?.summary ?? "Unknown GPU"
    }

    func getGPUInfo() -> String {
        let blocks = gpus.map { device -> String in
            var lines = [device.name]
            if !device.vram.isEmpty { lines.append("VRAM: \(device.vram)") }
            if let cores = device.cores { lines.append("Cores: \(cores)") }
            if !device.metal.isEmpty { lines.append("Metal: \(device.metal)") }
            if device.isLowPower { lines.append("Low Power: Yes") }
            if device.isRemovable { lines.append("Removable: Yes") }
            return lines.joined(separator: "\n")
        }
        return (["Graphics"] + blocks).joined(separator: "\n")
    }
}
