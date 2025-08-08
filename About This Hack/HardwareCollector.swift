//
//  HardwareCollector.swift
//  HardwareCollector
//

import Foundation
import AppKit

class HardwareCollector {
    static let shared = HardwareCollector()
    private init() {}
    
    // File content cache
    private var fileContentCache: [String: String] = [:]
    private let cacheLock = NSLock()
    
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
    
    func getCachedFileContent(_ path: String) -> String? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        
        if let cached = fileContentCache[path] {
            return cached
        }
        
        guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            return nil
        }
        
        fileContentCache[path] = content
        return content
    }
    
    func getAllData() {
        guard !dataHasBeenSet else { return }
        
        // Use a serial queue to ensure everything loads in order
        let serialQueue = DispatchQueue(label: "com.aboutthishack.datacollection", qos: .userInitiated)
        
        serialQueue.sync {
            // Prefetch commonly used files first
            let commonFiles = [
                InitGlobVar.hwFilePath,
                InitGlobVar.scrFilePath,
                InitGlobVar.bootvolnameFilePath,
                InitGlobVar.storagedataFilePath,
                InitGlobVar.sysmemFilePath
            ]
            
            for path in commonFiles {
                _ = getCachedFileContent(path)
            }
            
            // Initialize all hardware collectors in a specific order to avoid race conditions
            HCVersion.shared.getVersion()
            HCMacModel.shared.getMacModel()
            _ = HCCPU.shared.getCPU()
            _ = HCRAM.shared.getRam()
            _ = HCStartupDisk.shared.getStartupDisk()
            _ = HCDisplay.shared.getDisp()
            _ = HCGPU.shared.getGPU()
            
            // Initialize display and storage info
            hasBuiltInDisplay = checkForBuiltInDisplay()
            displayRes = getDisplayRes()
            displayNames = getDisplayNames()
            (storageType, storageData, storagePercent) = getStorageInfo()
        }
        
        dataHasBeenSet = true
    }
    
    private func getDisplayRes() -> [String] {
        guard let content = getCachedFileContent(InitGlobVar.scrFilePath) else { return [] }
        return content.components(separatedBy: .newlines)
            .filter { $0.contains("Resolution") }
            .map { String($0.dropFirst(22)).trimmingCharacters(in: .whitespaces) }
    }

    private func getDisplayNames() -> [String] {
        guard let content = getCachedFileContent(InitGlobVar.scrFilePath) else { return [] }
        
        var displayNames: [String] = []
        var inDisplaysSection = false
        
        let lines = content.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed == "Displays:" {
                inDisplaysSection = true
                continue
            }
            
            if inDisplaysSection && trimmed.hasSuffix(":") {
                // This is a display name (e.g., "G27Q:")
                let name = String(trimmed.dropLast())
                displayNames.append(name)
            }
        }
        
        return displayNames
    }
    
    private func checkForBuiltInDisplay() -> Bool {
        guard let content = getCachedFileContent(InitGlobVar.scrFilePath) else { return false }
        return content.lowercased().contains("connection type: internal") || content.lowercased().contains("display type: built-in")
    }

    private func getStorageInfo() -> (Bool, String, Double) {
        guard let content = getCachedFileContent(InitGlobVar.bootvolnameFilePath) else {
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
