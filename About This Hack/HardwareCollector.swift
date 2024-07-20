//
//  HardwareCollector.swift
//  HardwareCollector
//

import Foundation
import AppKit

class HardwareCollector {
    static let shared = HardwareCollector()
    private init() {}
    
    var numberOfDisplays = NSScreen.screens.count
    var dataHasBeenSet = false
    var displayRes: [String] = []
    var displayNames: [String] = []
    var storageType = false
    var storageData = ""
    var storagePercent = 0.0
    var deviceLocation = ""
    var deviceProtocol = ""
    var hasBuiltInDisplay = false
    var macType: MacType = .laptop
    
    func getAllData() {
        guard !dataHasBeenSet else { return }
        
        hasBuiltInDisplay = checkForBuiltInDisplay()
        displayRes = getDisplayRes()
        (storageType, storageData, storagePercent) = getStorageInfo()
        displayNames = getDisplayNames()
        
        dataHasBeenSet = true
    }
    
    private func getDisplayRes() -> [String] {
        let filePath = numberOfDisplays == 1 ? InitGlobVar.scrXmlFilePath : InitGlobVar.scrFilePath
        guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else { return [] }
        
        if numberOfDisplays == 1 {
            return content.components(separatedBy: "_spdisplays_resolution")
                .dropFirst()
                .compactMap { $0.components(separatedBy: .newlines)
                    .first { $0.contains("<string>") }?
                    .trimmingCharacters(in: .whitespaces)
                    .replacingOccurrences(of: "<string>", with: "")
                    .replacingOccurrences(of: "</string>", with: "")
                }
        } else {
            return content.components(separatedBy: .newlines)
                .filter { $0.contains("Resolution") }
                .map { String($0.dropFirst(22)).trimmingCharacters(in: .whitespaces) }
        }
    }

    private func getDisplayNames() -> [String] {
        let firstPart = run("grep \"Display Type\" \(InitGlobVar.scrFilePath) | cut -c 25-").components(separatedBy: "\n").filter { !$0.isEmpty }
        let secondPart = run("system_profiler SPDisplaysDataType | awk -F ' {8}|:' '/^ {8}[^ :]+/ {print $2}'").components(separatedBy: "\n").filter { !$0.isEmpty }
        
        if numberOfDisplays == 1 {
            return hasBuiltInDisplay ? ["\(firstPart[0]) \(getBuiltInDisplayName())"] : secondPart
        } else {
            return combineDisplayNames(firstPart, secondPart)
        }
    }
    
    private func getBuiltInDisplayName() -> String {
        run("grep -A2 \"</data>\" \(InitGlobVar.scrXmlFilePath) | awk -F'>|<' '/_name/{getline; print $3}' | tr -d '\n'")
    }
    
    private func combineDisplayNames(_ firstPart: [String], _ secondPart: [String]) -> [String] {
        var combined: [String] = []
        if hasBuiltInDisplay && !firstPart.isEmpty && !secondPart.isEmpty {
            combined.append("\(firstPart[0]) \(secondPart[0])")
        }
        for i in 1..<max(firstPart.count, secondPart.count) {
            if i < firstPart.count && i < secondPart.count {
                combined.append("\(firstPart[i]) \(secondPart[i])")
            } else if i < firstPart.count {
                combined.append(firstPart[i])
            } else if i < secondPart.count {
                combined.append(secondPart[i])
            }
        }
        return combined.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    private func checkForBuiltInDisplay() -> Bool {
        guard let content = try? String(contentsOfFile: InitGlobVar.scrFilePath, encoding: .utf8) else { return false }
        return content.components(separatedBy: .newlines)
            .filter { $0.contains("Display Type:") }
            .contains { $0.lowercased().contains("built-in") }
    }

    private func getStorageInfo() -> (Bool, String, Double) {
        guard let content = try? String(contentsOfFile: InitGlobVar.bootvolnameFilePath, encoding: .utf8) else {
            return (false, "Error reading file", 0)
        }
        
        let lines = content.components(separatedBy: .newlines)
        deviceProtocol = lines.first { $0.contains("Protocol:") }?.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " fabric$", with: "", options: [.regularExpression, .caseInsensitive]) ?? "Unknown"
        deviceLocation = lines.first { $0.contains("Device Location:") }?.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "Unknown"
        
        let isSSd = content.contains("Solid State: Yes")
        let (sizeGB, availableGB) = parseStorageSize(lines)
        let percent = availableGB / sizeGB
        let percentFree = String(format: "%.2f", percent * 100)
        
        let storageInfo = """
        \(HCStartupDisk.shared.getStartupDisk()) (\(deviceLocation) \(deviceProtocol))
        \(String(format: "%.2f", sizeGB)) GB (\(String(format: "%.2f", availableGB)) GB Available - \(percentFree)%)
        """
        
        return (isSSd, storageInfo, 1 - percent)
    }
    
    private func parseStorageSize(_ lines: [String]) -> (Double, Double) {
        let sizeLine = lines.first { $0.contains("Total Space:") }?.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "0 B"
        let availableLine = lines.first { $0.contains("Free Space:") }?.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "0 B"
        
        let (size, sizeUnit) = parseSize(sizeLine)
        let (available, availableUnit) = parseSize(availableLine)
        
        return (convertToGB(size, unit: sizeUnit), convertToGB(available, unit: availableUnit))
    }
    
    private func parseSize(_ sizeString: String) -> (Double, String) {
        let components = sizeString.components(separatedBy: .whitespaces)
        guard components.count >= 2, let size = Double(components[0]) else { return (0, "B") }
        return (size, components[1])
    }
    
    private func convertToGB(_ size: Double, unit: String) -> Double {
        switch unit.uppercased() {
        case "B": return size / 1_000_000_000
        case "KB": return size / 1_000_000
        case "MB": return size / 1_000
        case "GB": return size
        case "TB": return size * 1_000
        default: return size
        }
    }
}
