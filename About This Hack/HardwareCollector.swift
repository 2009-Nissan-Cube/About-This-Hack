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
    static var devicelocation: String = ""
    static var deviceprotocol: String = ""
    
    static var qhasBuiltInDisplay: Bool = (macType == .LAPTOP)
    
    static var macType: macType = .LAPTOP
    
    private static let queue = DispatchQueue(label: "com.hardwarecollector.queue", attributes: .concurrent)
    
    static func getAllData() {
        if (dataHasBeenSet) { return }
        
        let group = DispatchGroup()
        
        queue.async(group: group) {
            numberOfDisplays = getNumDisplays()
            print("Number of Displays: \(numberOfDisplays)")
        }
        
        queue.async(group: group) {
            qhasBuiltInDisplay = hasBuiltInDisplay()
            print("Has built-in display: \(qhasBuiltInDisplay)")
        }
        
        queue.async(group: group) {
            storageType = getStorageType()
            print("Storage Type: \(storageType)")
        }
        
        queue.async(group: group) {
            let storageInfo = getStorageData()
            storageData = storageInfo[0]
            storagePercent = Double(storageInfo[1])!
            print("Storage Data: \(storageData)")
            print("Storage Percent: \(storagePercent)")
        }
        
        queue.async(group: group) {
            displayRes = getDisplayRes()
        }
        
        queue.async(group: group) {
            displayNames = getDisplayNames()
        }
        
        group.wait()
        
        dataHasBeenSet = true
    }
    
    static func getDisplayRes() -> [String] {
        let numDispl = NSScreen.screens.count
        
        if numDispl == 1 {
            guard let content = try? String(contentsOfFile: initGlobVar.scrXmlFilePath, encoding: .utf8) else {
                return []
            }
            
            return content.components(separatedBy: "_spdisplays_resolution")
                .dropFirst()
                .compactMap { section -> String? in
                    let lines = section.components(separatedBy: .newlines)
                    return lines.first { $0.contains("<string>") }?
                        .trimmingCharacters(in: .whitespaces)
                        .replacingOccurrences(of: "<string>", with: "")
                        .replacingOccurrences(of: "</string>", with: "")
                }
        }
        else if numDispl > 1 {
            guard let content = try? String(contentsOfFile: initGlobVar.scrFilePath, encoding: .utf8) else {
                return []
            }
            
            return content.components(separatedBy: .newlines)
                .filter { $0.contains("Resolution") }
                .map { line -> String in
                    let startIndex = line.index(line.startIndex, offsetBy: 22)
                    return String(line[startIndex...]).trimmingCharacters(in: .whitespaces)
                }
        }
        
        return []
    }

    static func getDisplayNames() -> [String] {
        let numDispl = NSScreen.screens.count
        
        // Read and parse scrFilePath
        let scrFileContent = try? String(contentsOfFile: initGlobVar.scrFilePath, encoding: .utf8)
        let secondPart = scrFileContent?
            .components(separatedBy: .newlines)
            .filter { $0.hasPrefix("        ") }
            .compactMap { $0.dropFirst(8).split(separator: ":").first?.trimmingCharacters(in: .whitespaces) }
            ?? []
        
        print("secondPart = \(secondPart)")
        
        if numDispl == 1 {
            if qhasBuiltInDisplay {
                let firstPart = scrFileContent?
                    .components(separatedBy: .newlines)
                    .first { $0.contains("Display Type") }?
                    .dropFirst(24)
                    .trimmingCharacters(in: .whitespaces) ?? ""
                
                print("Display Type with 1 Display is Built In : \(firstPart)")
                
                let scrXmlFileContent = try? String(contentsOfFile: initGlobVar.scrXmlFilePath, encoding: .utf8)
                var displayName = scrXmlFileContent?
                    .components(separatedBy: "</data>")
                    .compactMap { part -> String? in
                        let lines = part.components(separatedBy: .newlines)
                        guard lines.contains(where: { $0.contains("_name") }) else { return nil }
                        return lines.first { !$0.contains("<") && !$0.isEmpty }?.trimmingCharacters(in: .whitespaces)
                    }
                    .first ?? ""
                
                if displayName.isEmpty {
                    displayName = scrXmlFileContent?
                        .components(separatedBy: "_spdisplays_display-product-id")
                        .first?
                        .components(separatedBy: .newlines)
                        .reversed()
                        .first { !$0.contains("<") && !$0.isEmpty }?
                        .trimmingCharacters(in: .whitespaces) ?? ""
                }
                
                print("Display Name with 1 Display is Built In : \(displayName)")
                return [firstPart + " " + displayName]
            } else {
                return secondPart
            }
        } else if numDispl == 2 || numDispl == 3 {
            print("2 or 3 displays found")
            let firstPart = scrFileContent?
                .components(separatedBy: .newlines)
                .filter { $0.contains("Display Type") }
                .map { $0.dropFirst(24).trimmingCharacters(in: .whitespaces) }
                ?? []
            
            print("firstPart = \(firstPart)")
            
            var toSend: [String] = []
            if qhasBuiltInDisplay {
                toSend.append(firstPart[0] + " " + secondPart[0])
                let loopCount = min(max(firstPart.count, secondPart.count) - 1, numDispl - 1)
                for i in 1..<loopCount {
                    if i < firstPart.count {
                        toSend.append(firstPart[i] + " " + secondPart[i])
                    } else if i < secondPart.count {
                        toSend.append(secondPart[i])
                    }
                }
                print("toSend = \"\(toSend)\"")
                return toSend
            } else {
                if !firstPart.isEmpty {
                    print([String](firstPart.dropFirst()))
                    return [String](firstPart.dropFirst())
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
