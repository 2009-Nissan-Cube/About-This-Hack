import Foundation

class HCGPU {
     
    static func getGPU() -> String {
        var gpuInfoFormatted: String = ""
        var gpuArray:[String] = []
        var chipFound:Bool = false
        var vramFound:Bool = false
        var metaFound:Bool = false
        
        gpuArray = run("egrep \"Chipset|VRAM|Metal\" " + initGlobVar.scrFilePath + " | grep -A2 \"Chipset\" | sed 's/^. *//'").components(separatedBy: "\n")
        if gpuArray != [""] {
            for gpuIndex in 0..<gpuArray.count {
                if gpuArray[gpuIndex].contains("Chipset") && !chipFound {
                    gpuInfoFormatted = String(gpuArray[gpuIndex].split(separator: ":")[1].replacingOccurrences(of: "Intel ", with: "").replacingOccurrences(of: "NVIDIA ", with: "").trimmingCharacters(in: .whitespacesAndNewlines))
                    chipFound = true
                }
                if gpuArray[gpuIndex].contains("VRAM") && !vramFound {
                    gpuInfoFormatted += " " + String(gpuArray[gpuIndex].split(separator: ":")[1].trimmingCharacters(in: .whitespacesAndNewlines))
                    vramFound = true
                }
                if gpuArray[gpuIndex].contains("Metal") && !metaFound {
                    gpuInfoFormatted += " (Metal " + String(gpuArray[gpuIndex].split(separator: ":")[1]).replacingOccurrences(of: "Metal", with: "").trimmingCharacters(in: .whitespacesAndNewlines) + ")"
                    metaFound = true
                }
            }
        }
        print("\(gpuInfoFormatted)")
        return "\(gpuInfoFormatted)"
    }
    
    static func getGPUInfo() -> String {
        return "Graphics\n" + run("egrep -v \"Graphics/Displays:|^      Displays:|^        [A-Za-z0-9]|^          [A-Za-z0-9]\" \(initGlobVar.scrFilePath)")
    }

}
