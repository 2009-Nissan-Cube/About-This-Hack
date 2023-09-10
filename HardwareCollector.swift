//
//  HardwareCollector.swift
//  HardwareCollector
//

import Foundation

class HardwareCollector {
    static var macInfo: String = "Hackintosh Extreme Plus"
    static var SMBios: String = ""
    static var GPUstring: String = "Radeon Pro 560 4GB"
    static var DisplayString: String = "Generic LCD"
    static var SerialNumberString: String = "XXXXXXXXXXX"
    static var BootloaderString: String = ""
    static var BootloaderInfo: String = ""
    static var numberOfDisplays: Int = 1
    static var dataHasBeenSet: Bool = false
    static var displayRes: [String] = []
    static var displayNames: [String] = []
    static var storageType: Bool = false
    static var storageData: String = ""
    static var storagePercent: Double = 0.0
    
    static var qhasBuiltInDisplay: Bool = (macType == .LAPTOP)

    static var macType: macType = .LAPTOP
    
    static func getAllData() {
        if (dataHasBeenSet) {return}
        let queue = DispatchQueue(label: "ga.0xCUBE.athqueue", attributes: .concurrent)

        queue.async {
            numberOfDisplays = getNumDisplays()
            print("Number of Displays: \(numberOfDisplays)")
            qhasBuiltInDisplay = hasBuiltInDisplay()
            print("Has built-in display: \(qhasBuiltInDisplay)")
            // getDisplayDiagonal() Having some issues, removing for now
        }
        queue.async {
            storageType = getStorageType()
            print("Storage Type: \(storageType)")
            storageData = getStorageData()[0]
            print("Storage Data: \(storageData)")
            storagePercent = Double(getStorageData()[1])!
            print("Storage Percent: \(storagePercent)")
        }
        
        // For some reason these don't work in groups, to be fixed
        displayRes = getDisplayRes()
        displayNames = getDisplayNames()
        
        dataHasBeenSet = true
    }
    
    static func getDisplayDiagonal() -> Float {
        
        return 13.3
    }
    
    static func getDisplayRes() -> [String] {
        let numDispl = getNumDisplays()
        if numDispl == 1 {
            return [run("""
echo "$(cat ~/.ath/scrXml.txt | grep -A2 _spdisplays_resolution | grep string | cut -c 15- | cut -f1 -d"<")"
""") ]
        }
        else if (numDispl == 2) {
            let tmp = run("cat ~/.ath/scr.txt | grep Resolution | cut -c 23-")
            let tmpParts = tmp.components(separatedBy: "\n")
            return tmpParts
        }
        else if (numDispl == 3) {
            let tmp = run("cat ~/.ath/scr.txt | grep Resolution | cut -c 23-")
            let tmpParts = tmp.components(separatedBy: "\n")
            return tmpParts
        }
        return []
    }
    
    static func getDisplayNames() -> [String] {
        let numDispl = getNumDisplays()
        if numDispl == 1 {
            if(qhasBuiltInDisplay) {
                return [run("""
echo "$(cat ~/.ath/scr.txt | grep "Display Type" | cut -c 25-)"
echo "$(cat ~/.ath/scrXml.txt | grep -A2 "</data>" | awk -F'>|<' '/_name/{getline; print $3}')" | tr -d '\n'
""")] }
            else {
                return [run("""
echo "$(cat ~/.ath/scr.txt | grep "        " | cut -c 9- | grep "^[A-Za-z]" | cut -f 1 -d ":")"
""")]
            }

        }
        else if (numDispl == 2 || numDispl == 3) {
            print("2 or 3 displays found")
            let tmp = run("""
echo "$(cat ~/.ath/scr.txt | grep "Display Type" | cut -c 25-)"
echo "$(cat ~/.ath/scr.txt | grep "        " | cut -c 9- | grep "^[A-Za-z]" | cut -f 1 -d ":")"
""")
            let tmpParts = tmp.components(separatedBy: "\n")
            var toSend: [String] = []
            if(qhasBuiltInDisplay) {
                toSend.append(tmpParts[0])
                for i in 2...tmpParts.count-1 {
                    toSend.append(tmpParts[i])
                }
                return toSend
            }
            else {
                return [String](tmpParts.dropFirst())
            }
        }
        return []
    }
    
    
    static func getNumDisplays() -> Int {
        return Int(run("cat ~/.ath/scr.txt | grep -c Resolution | tr -d '\n'")) ?? 0x0
    }
    static func hasBuiltInDisplay() -> Bool {
        let tmp = run("cat ~/.ath/scr.txt | grep Built-In | tr -d '\n'")
        return !(tmp == "")
    }
    
    
    
    static func getStorageType() -> Bool {
        let name = "\(HCStartupDisk.getStartupDisk())"
        print("Startup Disk Name " + name)
        let storageType = run("grep 'Solid State' ~/.ath/sysvolname.txt")
        
        return storageType.contains("Yes")
        
    }


    static func getStorageData() -> [String] {
        let name = "\(HCStartupDisk.getStartupDisk())"
        let size = run("diskutil info \"\(name)\" | grep 'Disk Size' | sed 's/.*:[[:space:]]*//' | cut -f1 -d'(' | tr -d '\n'")
        let available = run("diskutil info \"\(name)\" | Grep 'Container Free Space' | sed 's/.*:[[:space:]]*//' | cut -f1 -d'(' | tr -d '\n'")
        let sizeTrimmed = run("echo \"\(size)\" | cut -f1 -d\" \"").dropLast(1)
        let availableTrimmed = run("echo \"\(available)\" | cut -f1 -d\" \"").dropLast(1)
        print("Size: \(sizeTrimmed)")
        print("Available: \(availableTrimmed)")
        let percent = (Double(availableTrimmed)!) / Double(sizeTrimmed)!
        print("%: \(1 - percent)")
        return ["""
        \(name)
        \(size)(\(available)Available)
        """, String(1 - percent)]
    }
}

