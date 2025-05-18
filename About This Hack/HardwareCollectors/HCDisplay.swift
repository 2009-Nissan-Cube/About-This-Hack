import Foundation

class HCDisplay {
    static let shared = HCDisplay()
    private init() {}
    
    private lazy var displayInfo: (mainDisplay: String, allDisplays: String) = {
        ATHLogger.debug("Initializing Display Info...", category: .hardware)
        guard let content = try? String(contentsOfFile: InitGlobVar.scrFilePath, encoding: .utf8) else {
            ATHLogger.error("Failed to read display info from \(InitGlobVar.scrFilePath)", category: .hardware)
            return ("Unknown Display", "No display information available")
        }
        ATHLogger.debug("Successfully read \(InitGlobVar.scrFilePath) for display info.", category: .hardware)
        
        let lines = content.components(separatedBy: .newlines)
        
        // First find the Graphics/Displays section
        let displaySection = lines.drop { !$0.contains("Graphics/Displays:") }
                                .dropFirst() // Drop the Graphics/Displays line
        
        // Then find the Displays subsection
        let displaysSubsection = displaySection.drop { !$0.contains("Displays:") }
                                             .dropFirst() // Drop the Displays: line
                                             .prefix { !$0.isEmpty }
        
        let mainDisplay = self.getMainDisplayInfo(from: Array(displaysSubsection))
        ATHLogger.debug("Main Display Info: \(mainDisplay)", category: .hardware)
        let allDisplays = self.getAllDisplaysInfo(from: Array(displaySection))
        ATHLogger.debug("All Displays Info: \(allDisplays)", category: .hardware)
        
        return (mainDisplay, allDisplays)
    }()
    
    func getDisp() -> String {
        ATHLogger.debug("Getting main display string...", category: .hardware)
        return displayInfo.mainDisplay
    }
    
    func getDispInfo() -> String {
        ATHLogger.debug("Getting all displays info string...", category: .hardware)
        return displayInfo.allDisplays
    }
    
    private func cleanLine(_ line: String) -> String {
        line.trimmingCharacters(in: .whitespaces)
    }
    
    private func getMainDisplayInfo(from lines: [String]) -> String {
        ATHLogger.debug("Parsing main display info...", category: .hardware)
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
        
        ATHLogger.debug("Parsed Main Display Name: \(displayName), Resolution: \(resolution)", category: .hardware)
        return "\(displayName) (\(resolution))"
    }
    
    private func getAllDisplaysInfo(from lines: [String]) -> String {
        ATHLogger.debug("Parsing all displays info...", category: .hardware)
        var result = ""
        var currentSection = ""
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasSuffix(":") {
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
        
        ATHLogger.debug("Parsed All Displays Info: \(result)", category: .hardware)
        return result.trimmingCharacters(in: .newlines)
    }
}
