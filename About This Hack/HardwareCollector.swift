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
    
    static var qhasBuiltInDisplay: Bool = (macType == .LAPTOP)
    
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
        // secondPart data extracted in all cases (numDispl =1, 2 or 3)
//        let secondPart = run("grep \"        \" " + initGlobVar.scrFilePath + " | cut -c 9- | grep \"^[A-Za-z0-9]\" | cut -f 1 -d ':'").components(separatedBy: "\n")
        let secondPart = run("system_profiler SPDisplaysDataType | awk -F ' {8}|:' '/^ {8}[^ :]+/ {print $2}'").components(separatedBy: "\n")
        print("secondPart =  \(secondPart)")
        
        if numDispl == 1 {
            if (qhasBuiltInDisplay) {
                let firsPart: String = run("grep \"Display Type\" " + initGlobVar.scrFilePath + " | cut -c 25- | tr -d '\n'")
                print("Display Type with 1 Display is Built In : \(firsPart)")
                var displayName:String = run("grep -A2 \"</data>\" " + initGlobVar.scrXmlFilePath + " | awk -F'>|<' '/_name/{getline; print $3}' | tr -d '\n'")
                if displayName == "" {
                    displayName = run("grep -B2 \"_spdisplays_display-product-id\" " + initGlobVar.scrXmlFilePath + " | awk -F'>|<' '/_name/{getline; print $3}' | tr -d '\n'")
                }
                print("Display Name with 1 Display is Built In : \(displayName)")
                return [firsPart + " " + displayName]
            } else {
                return secondPart
            }
        } else if (numDispl == 2 || numDispl == 3) {
            print("2 or 3 displays found")
            let firsPart = run("grep \"Display Type\" " + initGlobVar.scrFilePath + " | cut -c 25-").components(separatedBy: "\n")
            print("firsPart =  " + "\(firsPart)")
            var toSend: [String] = []
            if(qhasBuiltInDisplay) {
                toSend.append(firsPart[0] + " " + secondPart[0])
                var loopCount = (secondPart.count-1)
                if (firsPart.count-1) > loopCount {
                    loopCount = (firsPart.count-1)
                }
                for i in stride(from: 1, to: loopCount, by: 1) {
                    if i <= (firsPart.count-1) {
                        toSend.append(firsPart[i] + " " + secondPart[i])
                    } else if i <= (secondPart.count-1){
                        toSend.append(secondPart[i])
                    }
                }
                print("toSend = \"\(toSend)\"")
                return toSend
            } else {
                if firsPart != [""] {
                    print([String](firsPart.dropFirst()))
                    return [String](firsPart.dropFirst())
                } else {
                    print([String](secondPart))
                    return [String](secondPart)
                }
            }
        }
        return []
    }

    static func getNumDisplays() -> Int {
        return NSScreen.screens.count
    }

    static func hasBuiltInDisplay() -> Bool {
        guard let content = try? String(contentsOfFile: initGlobVar.scrFilePath, encoding: .utf8) else {
            return false
        }
        return content.lowercased().contains("built-in")
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
