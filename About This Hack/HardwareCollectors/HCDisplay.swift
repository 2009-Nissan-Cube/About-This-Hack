import Foundation

class HCDisplay {
    static let shared = HCDisplay()
    private init() {}

    private var _displayInfo: (mainDisplay: String, allDisplays: String)?
    private let displayLock = NSLock()

    private var displayInfo: (mainDisplay: String, allDisplays: String) {
        displayLock.lock()
        defer { displayLock.unlock() }

        if let cached = _displayInfo {
            return cached
        }

        let computed = computeDisplayInfo()
        _displayInfo = computed
        return computed
    }

    func reset() {
        displayLock.lock()
        defer { displayLock.unlock() }
        _displayInfo = nil
        ATHLogger.debug("Display info reset", category: .hardware)
    }

    private func computeDisplayInfo() -> (mainDisplay: String, allDisplays: String) {
        ATHLogger.debug("Initializing Display Info...", category: .hardware)
        
        // Use cached data from HardwareCollector instead of file I/O
        guard let content = HardwareCollector.shared.getCachedFileContent(InitGlobVar.scrFilePath) else {
            ATHLogger.error("No display data available from HardwareCollector", category: .hardware)
            return ("Unknown Display", "No display information available")
        }
        
        ATHLogger.debug("Successfully retrieved display info from HardwareCollector.", category: .hardware)
        
        let lines = content.components(separatedBy: .newlines)

        ATHLogger.debug("Parsing display data from \(lines.count) lines", category: .hardware)

        // Log first 15 lines for debugging
        for (index, line) in lines.prefix(15).enumerated() {
            ATHLogger.debug("Line \(index): '\(line.trimmingCharacters(in: .whitespaces))'", category: .hardware)
        }

        // Find the Displays: subsection anywhere in the output
        guard let displaysIndex = lines.firstIndex(where: { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return trimmed == "Displays:"
        }) else {
            ATHLogger.error("Displays section not found in cached data (searched for 'Displays:')", category: .hardware)
            return ("Unknown Display", "No display information available")
        }

        ATHLogger.debug("Found 'Displays:' at line \(displaysIndex)", category: .hardware)

        // Collect display lines - they are indented after "Displays:"
        // Continue until we hit an empty line or end of file
        var displayLines: [String] = []
        var i = displaysIndex + 1
        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Stop at empty lines or when indentation decreases to root level
            if trimmed.isEmpty || (!line.hasPrefix("        ") && !line.hasPrefix("\t")) {
                break
            }

            displayLines.append(line)
            i += 1
        }

        let mainDisplay = self.getMainDisplayInfo(from: displayLines)
        ATHLogger.debug("Main Display Info: \(mainDisplay)", category: .hardware)
        // For a full list, include the same block
        let allDisplays = self.getAllDisplaysInfo(from: displayLines)
        ATHLogger.debug("All Displays Info: \(allDisplays)", category: .hardware)

        return (mainDisplay, allDisplays)
    }
    
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
        var foundFirstDisplay = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Display names are indented and end with ":"
            if trimmed.hasSuffix(":") && !foundFirstDisplay {
                displayName = String(trimmed.dropLast())
                foundFirstDisplay = true
                ATHLogger.debug("Found display name: \(displayName)", category: .hardware)
            } else if foundFirstDisplay && trimmed.contains("Resolution:") {
                resolution = trimmed.components(separatedBy: "Resolution:").last?
                    .components(separatedBy: "(").first?
                    .trimmingCharacters(in: .whitespaces) ?? resolution
                ATHLogger.debug("Found resolution for first display: \(resolution)", category: .hardware)
                break  // We have the first display's info
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
