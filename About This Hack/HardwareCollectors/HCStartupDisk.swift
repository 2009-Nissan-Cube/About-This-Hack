import Foundation

class HCStartupDisk {
    static let shared = HCStartupDisk()
    private init() {}
    
    private lazy var startupDisk: String = {
        guard let content = try? String(contentsOfFile: InitGlobVar.bootvolnameFilePath, encoding: .utf8) else {
            return ""
        }
        return content.components(separatedBy: "\n")
            .first { $0.contains("Volume Name") }?
            .components(separatedBy: ":")
            .last?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }()
    
    func getStartupDisk() -> String {
        return startupDisk
    }

    func getStartupDiskInfo() -> String {
        guard let content = try? String(contentsOfFile: InitGlobVar.storagedataFilePath, encoding: .utf8) else {
            return ""
        }
        
        return content.components(separatedBy: .newlines)
            .drop { !$0.contains(startupDisk) && !$0.contains("Mount Point: /") }
            .prefix { !$0.isEmpty }
            .joined(separator: "\n")
    }
}
