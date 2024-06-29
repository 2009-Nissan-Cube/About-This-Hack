import Foundation

class HCDisplay {
    static let displayInfo: (mainDisplay: String, allDisplays: String) = {
        guard let content = try? String(contentsOfFile: initGlobVar.scrFilePath, encoding: .utf8) else {
            return ("Unknown Display", "No display information available")
        }
        
        let lines = content.components(separatedBy: .newlines)
                           .map { cleanLine($0) }
                           .drop { !$0.hasPrefix("Displays") }
                           .dropFirst() // Drop the "Displays" line
                           .prefix { !$0.isEmpty && !$0.hasPrefix("Memory") }
        
        let mainDisplay = getMainDisplayInfo(from: Array(lines))
        let allDisplays = getAllDisplaysInfo(from: Array(lines))
        
        return (mainDisplay, allDisplays)
    }()
    
    static func getDisp() -> String {
        return displayInfo.mainDisplay
    }
    
    static func getDispInfo() -> String {
        return displayInfo.allDisplays
    }
    
    private static func cleanLine(_ line: String) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        let withoutParentheses = trimmed.replacingOccurrences(of: "\\([^)]*\\)", with: "", options: .regularExpression)
        return withoutParentheses.replacingOccurrences(of: ":", with: "").trimmingCharacters(in: .whitespaces)
    }
    
    private static func getMainDisplayInfo(from lines: [String]) -> String {
        let displayName = lines.first { !$0.isEmpty && $0.first?.isLetter == true } ?? "Unknown Display"
        let resolution = lines.first { $0.contains("Resolution") }?
                              .components(separatedBy: "Resolution").last?
                              .trimmingCharacters(in: .whitespaces) ?? "Unknown Resolution"
        return "\(displayName) (\(resolution))"
    }
    
    private static func getAllDisplaysInfo(from lines: [String]) -> String {
        var formattedLines: [String] = []
        var isNewDisplay = false
        
        for line in lines {
            if !line.isEmpty && line.first?.isLetter == true {
                isNewDisplay = true
                formattedLines.append("\n" + line)
            } else if isNewDisplay && !line.isEmpty {
                formattedLines.append("  " + line)
            }
        }
        
        return formattedLines.joined(separator: "\n").trimmingCharacters(in: .newlines)
    }
}
