import Foundation

class HCGPU {
    static let shared = HCGPU()
    private init() {}
    
    private lazy var gpuInfo: String = {
        guard let content = try? String(contentsOfFile: InitGlobVar.scrFilePath, encoding: .utf8) else {
            return ""
        }
        
        let lines = content.components(separatedBy: .newlines)
        var chipset = "", vram = "", metal = ""
        
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
        
        return "\(chipset) \(vram) (Metal \(metal))"
            .trimmingCharacters(in: .whitespaces)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }()
    
    func getGPU() -> String {
        return gpuInfo
    }
    
    func getGPUInfo() -> String {
        guard let content = try? String(contentsOfFile: InitGlobVar.scrFilePath, encoding: .utf8) else {
            return "Graphics\n"
        }
        
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
