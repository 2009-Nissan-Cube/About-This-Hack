import Foundation

class HCDisplay {
    static let shared = HCDisplay()
    private init() {}
    
    private lazy var displayInfo: (mainDisplay: String, allDisplays: String) = {
        guard let content = try? String(contentsOfFile: InitGlobVar.scrFilePath, encoding: .utf8) else {
            return ("Unknown Display", "No display information available")
        }
        
        let lines = content.components(separatedBy: .newlines)
                           .map { self.cleanLine($0) }
                           .drop { !$0.hasPrefix("Displays") }
                           .dropFirst() // Drop the "Displays" line
                           .prefix { !$0.isEmpty && !$0.hasPrefix("Memory") }
        
        let mainDisplay = self.getMainDisplayInfo(from: Array(lines))
        let allDisplays = self.getAllDisplaysInfo(from: Array(lines))
        
        return (mainDisplay, allDisplays)
    }()
    
    func getDisp() -> String {
        return displayInfo.mainDisplay
    }
    
    func getDispInfo() -> String {
        return displayInfo.allDisplays
    }
    
    private func cleanLine(_ line: String) -> String {
        line.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "\\([^)]*\\)", with: "", options: .regularExpression)
            .replacingOccurrences(of: ":", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    private func getMainDisplayInfo(from lines: [String]) -> String {
        let displayName = lines.first { !$0.isEmpty && $0.first?.isLetter == true } ?? "Unknown Display"
        let resolution = lines.first { $0.contains("Resolution") }?
                              .components(separatedBy: "Resolution").last?
                              .trimmingCharacters(in: .whitespaces) ?? "Unknown Resolution"
        return "\(displayName) (\(resolution))"
    }
    
    private func getAllDisplaysInfo(from lines: [String]) -> String {
        lines.reduce(into: "") { result, line in
            if !line.isEmpty && line.first?.isLetter == true {
                if !result.isEmpty {
                    result += "\n"
                }
                result += "\n\(line)"
            } else if !result.isEmpty && !line.isEmpty {
                result += "\n  \(line)"
            }
        }.trimmingCharacters(in: .newlines)
    }
}
