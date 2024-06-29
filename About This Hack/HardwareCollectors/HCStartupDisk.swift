import Cocoa
import Foundation

class HCStartupDisk {
    static let startupDisk: String = {
        guard let content = try? String(contentsOfFile: initGlobVar.bootvolnameFilePath, encoding: .utf8) else {
            return ""
        }
        return content.components(separatedBy: "\n")
            .first { $0.contains("Volume Name") }?
            .components(separatedBy: ":")
            .last?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }()
    
    static func getStartupDisk() -> String {
        return startupDisk
    }

    static func getStartupDiskInfo() -> String {
        guard let content = try? String(contentsOfFile: initGlobVar.storagedataFilePath, encoding: .utf8) else {
            return ""
        }
        
        let lines = content.components(separatedBy: .newlines)
        let startIndex = lines.firstIndex { $0.contains(startupDisk) || $0.contains("Mount Point: /") } ?? 0
        let endIndex = lines[startIndex...].firstIndex(where: { $0.isEmpty }) ?? lines.count
        
        return lines[startIndex..<endIndex].joined(separator: "\n")
    }
}
