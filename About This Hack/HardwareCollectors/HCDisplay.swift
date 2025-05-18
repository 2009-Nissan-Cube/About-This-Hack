import Foundation

class HCDisplay {
    static let shared = HCDisplay()
    private init() {}
    
    private lazy var displayInfo: (mainDisplay: String, allDisplays: String) = {
        guard let content = try? String(contentsOfFile: InitGlobVar.scrFilePath, encoding: .utf8) else {
            return ("Unknown Display", "No display information available")
        }
        
        let lines = content.components(separatedBy: .newlines)
        
        // First find the Graphics/Displays section
        let displaySection = lines.drop { !$0.contains("Graphics/Displays:") }
                                .dropFirst() // Drop the Graphics/Displays line
        
        // Then find the Displays subsection
        let displaysSubsection = displaySection.drop { !$0.contains("Displays:") }
                                             .dropFirst() // Drop the Displays: line
                                             .prefix { !$0.isEmpty }
        
        let mainDisplay = self.getMainDisplayInfo(from: Array(displaysSubsection))
        let allDisplays = self.getAllDisplaysInfo(from: Array(displaySection))
        
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
    }
    
    private func getMainDisplayInfo(from lines: [String]) -> String {
        var displayName = "Unknown Display"
        var resolution = "Unknown Resolution"
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasSuffix(":") {
                displayName = String(trimmed.dropLast())
            } else if trimmed.contains("Resolution:") {
                resolution = trimmed.components(separatedBy: "Resolution:").last?
                    .components(separatedBy: "(").first?
                    .trimmingCharacters(in: .whitespaces) ?? resolution
            }
        }
        
        return "\(displayName) (\(resolution))"
    }
    
    private func getAllDisplaysInfo(from lines: [String]) -> String {
        var result = ""
        var currentSection = ""
        var inDisplaysSection = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasSuffix(":") {
                if trimmed == "Displays:" {
                    inDisplaysSection = true
                }
                if !currentSection.isEmpty {
                    result += currentSection + "\n"
                }
                currentSection = "\n" + line
            } else if !trimmed.isEmpty {
                currentSection += "\n" + line
            }
        }
        
        if !currentSection.isEmpty {
            result += currentSection
        }
        
        return result.trimmingCharacters(in: .newlines)
    }
}
