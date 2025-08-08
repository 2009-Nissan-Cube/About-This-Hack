import Foundation

class HCGPU {
    static let shared = HCGPU()
    private init() {}
    
    private lazy var gpuInfo: String = {
        ATHLogger.debug("Initializing GPU Info...", category: .hardware)
        guard let content = try? String(contentsOfFile: InitGlobVar.scrFilePath, encoding: .utf8) else {
            ATHLogger.error("Failed to read GPU info from \(InitGlobVar.scrFilePath)", category: .hardware)
            return ""
        }
        ATHLogger.debug("Successfully read \(InitGlobVar.scrFilePath) for GPU info.", category: .hardware)
        
        let lines = content.components(separatedBy: .newlines)
        var chipset = "", vram = "", metal = ""
        
        // Fallback: if standard parsing fails, grab first meaningful line under Graphics/Displays
        if let displaysIdx = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "Displays:" }),
           let gfxIdx = lines.firstIndex(where: { $0.contains("Graphics/Displays:") }) {
            let gpuBlock = lines[(gfxIdx+1)..<displaysIdx]
            let trimmed = gpuBlock.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            let meaningful = trimmed.filter { !$0.hasSuffix(":") }
            if let first = meaningful.first {
                // Clean up the chipset line by removing common prefixes
                let cleaned = first.replacingOccurrences(of: "Chipset Model:", with: "")
                                  .replacingOccurrences(of: "Chipset:", with: "")
                                  .trimmingCharacters(in: .whitespaces)
                ATHLogger.debug("Fallback GPU Info: \(cleaned)", category: .hardware)
                return cleaned
            }
        }
        for line in lines {
            if chipset.isEmpty, line.contains("Chipset"),
               let value = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) {
                chipset = value.replacingOccurrences(of: "Intel ", with: "")
                               .replacingOccurrences(of: "NVIDIA ", with: "")
            } else if vram.isEmpty, line.contains("VRAM"),
                      let value = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) {
                vram = value
            } else if metal.isEmpty, line.contains("Metal"),
                      let value = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) {
                metal = value.replacingOccurrences(of: "Metal", with: "")
            }
            
            if !chipset.isEmpty && !vram.isEmpty && !metal.isEmpty {
                break
            }
        }
        
        ATHLogger.debug("GPU Chipset: \(chipset), VRAM: \(vram), Metal: \(metal)", category: .hardware)
        
        return "\(chipset) \(vram) (Metal \(metal))"
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }()
    
    func getGPU() -> String {
        ATHLogger.debug("Getting GPU string...", category: .hardware)
        return gpuInfo
    }
    
    func getGPUInfo() -> String {
        ATHLogger.debug("Getting detailed GPU info string...", category: .hardware)
        guard let content = try? String(contentsOfFile: InitGlobVar.scrFilePath, encoding: .utf8) else {
            ATHLogger.error("Failed to read GPU details from \(InitGlobVar.scrFilePath)", category: .hardware)
            return "Graphics\n"
        }
        ATHLogger.debug("Successfully read \(InitGlobVar.scrFilePath) for detailed GPU info.", category: .hardware)
        
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
