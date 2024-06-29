//
//  HardwareCollector.swift
//  HardwareCollector
//

import Foundation
import AppKit

let name = "\(HCStartupDisk.getStartupDisk())"

class HardwareCollector {
    static var numberOfDisplays: Int = 1
    static var dataHasBeenSet: Bool = false
    static var displayRes: [String] = []
    static var displayNames: [String] = []
    static var storageType: Bool = false
    static var storageData: String = ""
    static var storagePercent: Double = 0.0
    static var devicelocation:String = ""
    static var deviceprotocol:String = ""
    static var qhasBuiltInDisplay: Bool = false
    
    static var macType: macType = .LAPTOP
    
    static func getAllData() {
        if (dataHasBeenSet) {return}
        numberOfDisplays = getNumDisplays()
        print("Number of Displays: \(numberOfDisplays)")
        qhasBuiltInDisplay = hasBuiltInDisplay()
        print("Has built-in display: \(qhasBuiltInDisplay)")
        storageType = getStorageType()
        print("Storage Type: \(storageType)")
        storageData = getStorageData()[0]
        print("Storage Data: \(storageData)")
        storagePercent = Double(getStorageData()[1])!
        print("Storage Percent: \(storagePercent)")
        displayRes = getDisplayRes()
        displayNames = getDisplayNames()
        
        dataHasBeenSet = true
    }
    
    static func getDisplayRes() -> [String] {
        let numDispl = NSScreen.screens.count
        
        if numDispl == 1 {
            guard let content = try? String(contentsOfFile: initGlobVar.scrXmlFilePath, encoding: .utf8) else {
                return []
            }
            
            let resolutions = content.components(separatedBy: "_spdisplays_resolution")
                .dropFirst()
                .compactMap { section -> String? in
                    let lines = section.components(separatedBy: .newlines)
                    return lines.first { $0.contains("<string>") }?
                        .trimmingCharacters(in: .whitespaces)
                        .replacingOccurrences(of: "<string>", with: "")
                        .replacingOccurrences(of: "</string>", with: "")
                }
            
            return resolutions
        }
        else if numDispl > 1 {
            guard let content = try? String(contentsOfFile: initGlobVar.scrFilePath, encoding: .utf8) else {
                return []
            }
            
            let resolutions = content.components(separatedBy: .newlines)
                .filter { $0.contains("Resolution") }
                .map { line -> String in
                    let startIndex = line.index(line.startIndex, offsetBy: 22)
                    return String(line[startIndex...]).trimmingCharacters(in: .whitespaces)
                }
            
            return resolutions
        }
        
        return []
    }

    static func getDisplayNames() -> [String] {
        let numDispl = getNumDisplays()
        
        // Filter out blank entries
        let firstPart = run("grep \"Display Type\" " + initGlobVar.scrFilePath + " | cut -c 25-")
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let secondPart = run("system_profiler SPDisplaysDataType | awk -F ' {8}|:' '/^ {8}[^ :]+/ {print $2}'")
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        print("firstPart: \(firstPart)")
        print("secondPart: \(secondPart)")
        
        if numDispl == 1 {
            if qhasBuiltInDisplay {
                let firstPart = firstPart[0]
                print("Display Type with 1 Display is Built In : \(firstPart)")
                
                var displayName = run("grep -A2 \"</data>\" " + initGlobVar.scrXmlFilePath + " | awk -F'>|<' '/_name/{getline; print $3}' | tr -d '\n'")
                
                print("Display Name with 1 Display is Built In: \(displayName)")
                return [firstPart + " " + displayName].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            } else {
                return secondPart
            }
        } else if numDispl >= 2 {
            print("2 or more displays found")
            
            print("firstPart = \(firstPart)")
            
            var toSend: [String] = []
            
            if qhasBuiltInDisplay {
                if !firstPart.isEmpty && !secondPart.isEmpty {
                    toSend.append(firstPart[0] + " " + secondPart[0])
                }
                
                let loopCount = min(firstPart.count, secondPart.count)
                
                for i in 1..<loopCount {
                    if i < firstPart.count && i < secondPart.count {
                        toSend.append(firstPart[i] + " " + secondPart[i])
                    } else if i < firstPart.count {
                        toSend.append(firstPart[i])
                    } else if i < secondPart.count {
                        toSend.append(secondPart[i])
                    }
                }
                
                print("toSend = \"\(toSend)\"")
                return toSend.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            } else {
                if !firstPart.isEmpty {
                    print(firstPart)
                    return firstPart
                } else {
                    print(secondPart)
                    return secondPart
                }
            }
        }
        
        return []
    }
    
    static func getNumDisplays() -> Int {
        return NSScreen.screens.count
    }

    static func hasBuiltInDisplay() -> Bool {
        let scrFileContent = try? String(contentsOfFile: initGlobVar.scrFilePath, encoding: .utf8)
        
        guard let content = scrFileContent else {
            print("Error reading system_profiler output file")
            return false
        }
        
        let displayLines = content.components(separatedBy: .newlines)
            .filter { $0.contains("Display Type:") }
        
        return displayLines.contains { $0.lowercased().contains("built-in") }
    }

    static func getStorageType() -> Bool {
        print("Startup Disk Name: " + name)
        guard let content = try? String(contentsOfFile: initGlobVar.bootvolnameFilePath, encoding: .utf8) else {
            return false
        }
        return content.contains("Solid State: Yes")
    }

    static func getStorageData() -> [String] {
        guard let content = try? String(contentsOfFile: initGlobVar.bootvolnameFilePath, encoding: .utf8) else {
            return ["Error reading file", "0"]
        }
        
        let lines = content.components(separatedBy: .newlines)
        
        deviceprotocol = lines.first(where: { $0.contains("Protocol:") })?.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "Unknown"
        deviceprotocol = deviceprotocol.replacingOccurrences(of: " fabric$", with: "", options: [.regularExpression, .caseInsensitive])
        devicelocation = lines.first(where: { $0.contains("Device Location:") })?.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "Unknown"
        
        let sizeLine = lines.first(where: { $0.contains("Total Space:") })?.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "0 B"
        let availableLine = lines.first(where: { $0.contains("Free Space:") })?.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? "0 B"
        
        let (size, sizeUnit) = parseSize(sizeLine)
        let (available, availableUnit) = parseSize(availableLine)
        
        let sizeGB = convertToGB(size, unit: sizeUnit)
        let availableGB = convertToGB(available, unit: availableUnit)
        
        let percent = availableGB / sizeGB
        let percentFree = String(format: "%.2f", percent * 100)
        
        print("Storage Info:")
        print("Size: \(String(format: "%.2f", sizeGB)) GB")
        print("Available: \(String(format: "%.2f", availableGB)) GB")
        print("Free: \(percentFree)%")

        return ["""
        \(name) (\(devicelocation) \(deviceprotocol))
        \(String(format: "%.2f", sizeGB)) GB (\(String(format: "%.2f", availableGB)) GB Available - \(percentFree)%)
        """, String(1 - percent)]
    }

    private static func parseSize(_ sizeString: String) -> (Double, String) {
        let components = sizeString.components(separatedBy: .whitespaces)
        guard components.count >= 2,
              let size = Double(components[0]) else {
            return (0, "B")
        }
        return (size, components[1])
    }

    private static func convertToGB(_ size: Double, unit: String) -> Double {
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
