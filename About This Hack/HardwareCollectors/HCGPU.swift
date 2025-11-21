import Foundation

class HCGPU {
    static let shared = HCGPU()
    private init() {}

    private var _gpuInfo: String?
    private let gpuLock = NSLock()

    private var gpuInfo: String {
        gpuLock.lock()
        defer { gpuLock.unlock() }

        if let cached = _gpuInfo {
            return cached
        }

        let computed = computeGPUInfo()
        _gpuInfo = computed
        return computed
    }

    func reset() {
        gpuLock.lock()
        defer { gpuLock.unlock() }
        _gpuInfo = nil
        ATHLogger.debug(NSLocalizedString("log.gpu.reset", comment: "GPU info reset"), category: .hardware)
    }

    private func computeGPUInfo() -> String {
        ATHLogger.debug(NSLocalizedString("log.gpu.init", comment: "Initializing GPU Info"), category: .hardware)
        
        // Use cached data from HardwareCollector instead of file I/O
        guard let content = HardwareCollector.shared.getCachedFileContent(InitGlobVar.scrFilePath) else {
            ATHLogger.error(NSLocalizedString("log.gpu.no_data", comment: "No GPU data available from HardwareCollector"), category: .hardware)
            return ""
        }
        
        ATHLogger.debug(NSLocalizedString("log.gpu.retrieved", comment: "Successfully retrieved GPU info"), category: .hardware)
        
        let lines = content.components(separatedBy: .newlines)
        var chipset = "", vram = "", metal = ""

        ATHLogger.debug(String(format: NSLocalizedString("log.gpu.parsing_data", comment: "Parsing GPU data"), lines.count), category: .hardware)

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Log first 15 lines for debugging
            if index < 15 {
                ATHLogger.debug(String(format: NSLocalizedString("log.gpu.line", comment: "GPU line"), index, trimmed), category: .hardware)
            }

            if chipset.isEmpty, trimmed.hasPrefix("Chipset Model:") {
                let value = trimmed.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                if !value.isEmpty {
                    chipset = value.replacingOccurrences(of: "Intel ", with: "")
                                   .replacingOccurrences(of: "NVIDIA ", with: "")
                                   .replacingOccurrences(of: "AMD ", with: "")
                    ATHLogger.debug(String(format: NSLocalizedString("log.gpu.found_chipset", comment: "Found Chipset"), index, chipset), category: .hardware)
                }
            } else if vram.isEmpty, trimmed.hasPrefix("VRAM") {
                let value = trimmed.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                if !value.isEmpty {
                    vram = value
                    ATHLogger.debug(String(format: NSLocalizedString("log.gpu.found_vram", comment: "Found VRAM"), index, vram), category: .hardware)
                }
            } else if metal.isEmpty, trimmed.hasPrefix("Metal Support:") {
                let value = trimmed.components(separatedBy: ":").dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                if !value.isEmpty {
                    metal = value
                    ATHLogger.debug(String(format: NSLocalizedString("log.gpu.found_metal", comment: "Found Metal"), index, metal), category: .hardware)
                }
            }

            // Stop when we hit the Displays section
            if trimmed == "Displays:" {
                ATHLogger.debug(String(format: NSLocalizedString("log.gpu.stopping_parse", comment: "Stopping GPU parse"), index), category: .hardware)
                break
            }
        }

        ATHLogger.debug(String(format: NSLocalizedString("log.gpu.final_info", comment: "Final GPU info"), chipset, vram, metal), category: .hardware)

        // Build result based on what we found
        var result = chipset
        if !vram.isEmpty {
            result += " \(vram)"
        }
        if !metal.isEmpty {
            result += " (\(metal))"
        }

        return result.trimmingCharacters(in: .whitespaces)
    }
    
    func getGPU() -> String {
        ATHLogger.debug(NSLocalizedString("log.gpu.getting_string", comment: "Getting GPU string"), category: .hardware)
        return gpuInfo
    }
    
    func getGPUInfo() -> String {
        ATHLogger.debug(NSLocalizedString("log.gpu.getting_detailed_info", comment: "Getting detailed GPU info string"), category: .hardware)
        
        // Use cached data from HardwareCollector
        guard let content = HardwareCollector.shared.getCachedFileContent(InitGlobVar.scrFilePath) else {
            ATHLogger.error(NSLocalizedString("log.gpu.no_details", comment: "No GPU details available from HardwareCollector"), category: .hardware)
            return "Graphics\n"
        }
        
        ATHLogger.debug(NSLocalizedString("log.gpu.retrieved_detailed", comment: "Successfully retrieved detailed GPU info"), category: .hardware)
        
        let filteredLines = content.components(separatedBy: .newlines)
            .filter { !$0.contains("Graphics/Displays:") &&
                      !$0.hasPrefix("      Displays:") &&
                      !$0.hasPrefix("        ") &&
                      !$0.hasPrefix("          ") }
            .map { line in
                line.trimmingCharacters(in: .whitespaces)
                    .components(separatedBy: .whitespaces)
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
            }
        
        return "Graphics\n" + filteredLines.joined(separator: "\n")
    }
}
