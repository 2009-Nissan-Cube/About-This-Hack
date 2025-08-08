import Foundation

class HCDisplay {
    static let shared = HCDisplay()
    private init() {}
    
    private lazy var displayInfo: (mainDisplay: String, allDisplays: String) = {
        ATHLogger.debug("Initializing Display Info...", category: .hardware)
        
        // Use cached data from HardwareCollector instead of file I/O
        guard let content = HardwareCollector.shared.getCachedFileContent(InitGlobVar.scrFilePath) else {
            ATHLogger.error("No display data available from HardwareCollector", category: .hardware)
            return ("Unknown Display", "No display information available")
        }
        
        ATHLogger.debug("Successfully retrieved display info from HardwareCollector.", category: .hardware)
        
        let lines = content.components(separatedBy: .newlines)
        // Find the Displays: subsection anywhere in the output
        guard let displaysIndex = lines.firstIndex(where: {
            $0.trimmingCharacters(in: .whitespaces) == "Displays:"
        }) else {
            ATHLogger.error("Displays section not found in cached data", category: .hardware)
            return ("Unknown Display", "No display information available")
        }
        // Collect all non-empty lines after "Displays:" for the main display block
        let displayLines = lines[(displaysIndex + 1)...]
            .prefix { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let mainDisplay = self.getMainDisplayInfo(from: Array(displayLines))
        ATHLogger.debug("Main Display Info: \(mainDisplay)", category: .hardware)
        // For a full list, include the same block
        let allDisplays = self.getAllDisplaysInfo(from: Array(displayLines))
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
