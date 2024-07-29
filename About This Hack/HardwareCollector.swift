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
        guard let content = try? String(contentsOfFile: InitGlobVar.scrFilePath, encoding: .utf8) else { return [] }
        return content.components(separatedBy: .newlines)
            .filter { $0.contains("Resolution") }
            .map { String($0.dropFirst(22)).trimmingCharacters(in: .whitespaces) }
    }

    private func getDisplayNames() -> [String] {
        let displayNames = run("cat \(InitGlobVar.scrFilePath) | awk -F ' {8}|:' '/^ {8}[^ :]+/ {print $2}'").components(separatedBy: "\n").filter { !$0.isEmpty }
        return displayNames
    }

    
    private func checkForBuiltInDisplay() -> Bool {
        guard let content = try? String(contentsOfFile: InitGlobVar.scrFilePath, encoding: .utf8) else { return false }
        return content.lowercased().contains("connection type: internal") || content.lowercased().contains("display type: built-in")
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
