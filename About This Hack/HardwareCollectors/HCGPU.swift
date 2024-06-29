import Foundation

class HCGPU {
    static let gpuInfo: String = {
        guard let content = try? String(contentsOfFile: initGlobVar.scrFilePath, encoding: .utf8) else {
            return ""
        }
        
        let lines = content.components(separatedBy: .newlines)
        var chipset = "", vram = "", metal = ""
        
        for line in lines {
            if line.contains("Chipset") && chipset.isEmpty {
                chipset = line.components(separatedBy: ":").last?
                    .trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "Intel ", with: "")
                    .replacingOccurrences(of: "NVIDIA ", with: "") ?? ""
            } else if line.contains("VRAM") && vram.isEmpty {
                vram = line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? ""
            } else if line.contains("Metal") && metal.isEmpty {
                metal = line.components(separatedBy: ":").last?
                    .trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "Metal", with: "") ?? ""
            }
            
            if !chipset.isEmpty && !vram.isEmpty && !metal.isEmpty {
                break
            }
        }
        chipset = chipset.trimmingCharacters(in: .whitespaces)
        vram = vram.trimmingCharacters(in: .whitespaces)
        metal = metal.trimmingCharacters(in: .whitespaces)
        
        return "\(chipset) \(vram)(Metal \(metal))".trimmingCharacters(in: .whitespaces)
    }()
    
    static func getGPU() -> String {
        return gpuInfo
    }
    
    static func getGPUInfo() -> String {
        guard let content = try? String(contentsOfFile: initGlobVar.scrFilePath, encoding: .utf8) else {
            return "Graphics\n"
        }
        
        let relevantLines = content.components(separatedBy: .newlines)
            .filter { line in
                !line.contains("Graphics/Displays:") &&
                !line.hasPrefix("      Displays:") &&
                !line.hasPrefix("        ") &&
                !line.hasPrefix("          ")
            }
        
        return "Graphics\n" + relevantLines.joined(separator: "\n")
    }
}
