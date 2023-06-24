//
//  HardwareCollector.swift
//  HardwareCollector
//

import Foundation

class HardwareCollector {
    static var OSnum: String = "10.10.0"
    static var OSvers: macOSvers = macOSvers.macOS
    static var OSname: String = ""
    static var OSBuildNum: String = "19G101"
    static var macName: String = "Hackintosh Extreme Plus"
    static var macInfo: String = "Hackintosh Extreme Plus"
    static var SMBios: String = ""
    static var osPrefix: String = "macOS"
    static var CPUstring: String = "i7"
    static var RAMstring: String = "16 GB"
    static var GPUstring: String = "Radeon Pro 560 4GB"
    static var DisplayString: String = "Generic LCD"
    static var StartupDiskString: String = "Macintosh HD"
    static var SerialNumberString: String = "XXXXXXXXXXX"
    static var BootloaderString: String = ""
    static var BootloaderInfo: String = ""
    static var macType: macType = .LAPTOP
    static var numberOfDisplays: Int = 1
    static var dataHasBeenSet: Bool = false
    static var qhasBuiltInDisplay: Bool = (macType == .LAPTOP)
    static var displayRes: [String] = []
    static var displayNames: [String] = []
    static var builtInDisplaySize: Float = 0
    static var storageType: Bool = false
    static var storageData: String = ""
    static var storagePercent: Double = 0.0

    
    static func getAllData() {
        if (dataHasBeenSet) {return}
        let queue = DispatchQueue(label: "ga.0xCUBE.athqueue", attributes: .concurrent)

        queue.async{
            OSnum = getOSnum()
            print("OS Number: \(OSnum)")
            setOSvers(osNumber: OSnum)
            OSname = macOSversToString()
            print("OS Name: \(OSname)")
            osPrefix = getOSPrefix()
            print("OS Prefix: \(osPrefix)")
            OSBuildNum = getOSBuildNum()
            print("OS Build Number: \(OSBuildNum)")
        }
        queue.async {
            macName = getMacName()
            print("Mac name: \(macName)")
            CPUstring = getCPU()
            print("CPU: \(CPUstring)")
        }
        queue.async {
            RAMstring = getRam()
            print("RAM: \(RAMstring)")
        }
        queue.async {
            GPUstring = getGPU()
            print("GPU: \(GPUstring)")
        }
        queue.async {
            DisplayString = getDisp()
            print("Display(s): \(DisplayString)")
            numberOfDisplays = getNumDisplays()
            print("Number of Displays: \(numberOfDisplays)")
            qhasBuiltInDisplay = hasBuiltInDisplay()
            print("Has built-in display: \(qhasBuiltInDisplay)")
            // getDisplayDiagonal() Having some issues, removing for now
        }
        queue.async {
            StartupDiskString = getStartupDisk()
            print("Startup Disk: \(StartupDiskString)")
        }
        queue.async {
            SerialNumberString = getSerialNumber()
            print("Serial Number: \(SerialNumberString)")
            BootloaderString = getBootloader()
            print("Bootloader: \(BootloaderString)")
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
echo "$(system_profiler SPDisplaysDataType -xml | grep -A2 _spdisplays_resolution | grep string | cut -c 15- | cut -f1 -d"<")"
""") ]
        }
        else if (numDispl == 2) {
            let tmp = run("system_profiler SPDisplaysDataType | grep Resolution | cut -c 23-")
            let tmpParts = tmp.components(separatedBy: "\n")
            return tmpParts
        }
        else if (numDispl == 3) {
            let tmp = run("system_profiler SPDisplaysDataType | grep Resolution | cut -c 23-")
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
echo "$(system_profiler SPDisplaysDataType | grep "Display Type" | cut -c 25-)"
echo "$(system_profiler SPDisplaysDataType -xml | grep -A2 "</data>" | awk -F'>|<' '/_name/{getline; print $3}')" | tr -d '\n'
""")] }
            else {
                return [run("""
echo "$(system_profiler SPDisplaysDataType | grep "        " | cut -c 9- | grep "^[A-Za-z]" | cut -f 1 -d ":")"
""")]
            }

        }
        else if (numDispl == 2 || numDispl == 3) {
            print("2 or 3 displays found")
            let tmp = run("""
echo "$(system_profiler SPDisplaysDataType | grep "Display Type" | cut -c 25-)"
echo "$(system_profiler SPDisplaysDataType | grep "        " | cut -c 9- | grep "^[A-Za-z]" | cut -f 1 -d ":")"
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
        return Int(run("system_profiler SPDisplaysDataType | grep -c Resolution | tr -d '\n'")) ?? 0x0
    }
    static func hasBuiltInDisplay() -> Bool {
        let tmp = run("system_profiler SPDisplaysDataType | grep Built-In | tr -d '\n'")
        return !(tmp == "")
    }
    
    
    static func getBootloader() -> String {
        var BootloaderInfo: String = ""
        BootloaderInfo = run("nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | awk '{print $2}' | awk -F'-' '{print $2}'")
        if BootloaderInfo != "" {
            BootloaderInfo = run("echo \"OpenCore - Version \" $(nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | awk '{print $2}' | awk -F'-' '{print $2}' | sed -e 's/ */./g' -e s'/^.//g' -e 's/.$//g' -e 's/ .//g' -e 's/. //g' | tr -d '\n') $( nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | awk '{print $2}' | awk -F'-' '{print $1}' | sed -e 's/REL/(Release)/g' -e s'/N\\/A//g' -e 's/DEB/(Debug)/g' | tr -d '\n')")
        }
        else {
            BootloaderInfo = run("system_profiler SPHardwareDataType | grep \"Clover\" | awk '{print $4,\"r\" $6,\"(\" $9,\" \"}' | tr -d '\n'")
            if BootloaderInfo  != "" {
                BootloaderInfo += run("echo \"(\"$(/usr/local/bin/bdmesg | grep -i \"Build with: \\[Args:\" | awk -F '\\-b' '{print $NF}' |  awk -F '\\-t' '{print $1 $2}' | awk  '{print $2}' | awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}') $(/usr/local/bin/bdmesg | grep -i \"Build with: \\[Args:\" | awk -F '\\-b' '{print $NF}' |  awk -F '\\-t' '{print $1 $2}' | awk  '{print $1}' | awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}')\")\"")
            }
            else {
                BootloaderInfo = "Apple UEFI"
            }
        }
        return BootloaderInfo
    }

    
    
    static func getSerialNumber() -> String {
        return run("system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'")
    }
    
    static func getStartupDisk() -> String {
        return run("system_profiler SPSoftwareDataType | grep 'Boot Volume' | sed 's/.*: //' | tr -d '\n'")
    }
    
    static func getGPU() -> String {
        let graphicsTmp = run("system_profiler SPDisplaysDataType | grep 'Chipset' | sed 's/.*: //'")
        let graphicsRAM  = run("system_profiler SPDisplaysDataType | grep VRAM | sed 's/.*: //'")
        let graphicsArray = graphicsTmp.components(separatedBy: "\n")
        let vramArray = graphicsRAM.components(separatedBy: "\n")
        _ = graphicsArray.count
        var x = 0
        var gpuInfoFormatted = ""
        while x < min(vramArray.count, graphicsArray.count) {
            gpuInfoFormatted.append("\(graphicsArray[x]) \(vramArray[x])\n")
            x += 1
        }
        return gpuInfoFormatted
    }
    
    static func getDisp() -> String {
        var tmp = run("system_profiler SPDisplaysDataType | grep Resolution | sed 's/.*: //'")
        if tmp.contains("(QHD"){
            tmp = run("system_profiler SPDisplaysDataType | grep Resolution | sed 's/.*: //' | cut -c -11")
        }
        if(tmp.contains("\n")) {
            let displayID = tmp.firstIndex(of: "\n")!
            let displayTrimmed = String(tmp[..<displayID])
            tmp = displayTrimmed
        }
        return tmp
    }
    
    static func getRam() -> String {
        let ram = run("echo \"$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))\" | tr -d '\n'")
        let ramType = run("system_profiler SPMemoryDataType | grep 'Type: DDR' | awk '{print $2}' | sed -n '1p'").trimmingCharacters(in: .whitespacesAndNewlines)
        let ramSpeed = run("system_profiler SPMemoryDataType | grep 'Speed' | grep 'MHz' | awk '{print $2\" \"$3}' | sed -n '1p'").trimmingCharacters(in: .whitespacesAndNewlines)
        let ramReturn = "\(ram) GB \(ramSpeed) \(ramType)"
        return ramReturn
    }
    
    
    
    static func getOSPrefix() -> String{
        switch OSvers {
        case .MAVERICKS,.YOSEMITE,.EL_CAPITAN:
            return "OS X"
        case .SIERRA,.HIGH_SIERRA,.MOJAVE,.CATALINA,.BIG_SUR,.MONTEREY,.VENTURA,.SONOMA,.macOS:
            return "macOS"
        }
    }
    
    
    static func getOSnum() -> String {
        
        let osVersion = run("sw_vers | grep ProductVersion | awk '{print $2}'")
        
        return osVersion
    }
    static func setOSvers(osNumber: String) {
        switch osNumber.prefix(2) {
            case "14": OSvers = macOSvers.SONOMA
            case "13": OSvers = macOSvers.VENTURA
            case "12": OSvers = macOSvers.MONTEREY
            case "11": OSvers = macOSvers.BIG_SUR
            case "10":
                if osNumber.contains("16") { OSvers = macOSvers.BIG_SUR }
                else if osNumber.contains("15") { OSvers = macOSvers.CATALINA }
                else if osNumber.contains("14") { OSvers = macOSvers.MOJAVE }
                else if osNumber.contains("13") { OSvers = macOSvers.HIGH_SIERRA }
                else if osNumber.contains("12") { OSvers = macOSvers.SIERRA }
                else if osNumber.contains("11") { OSvers = macOSvers.EL_CAPITAN }
                else if osNumber.contains("10") { OSvers = macOSvers.YOSEMITE }
                else if osNumber.contains("9") { OSvers = macOSvers.MAVERICKS }
                else { OSvers = macOSvers.macOS }
            default: OSvers = macOSvers.macOS
        }
    }

    
    
    static func macOSversToString() -> String {
        switch OSvers {
        case .MAVERICKS: return "Mavericks"
        case .YOSEMITE: return "Yosemite"
        case .EL_CAPITAN: return "El Capitan"
        case .SIERRA: return "Sierra"
        case .HIGH_SIERRA: return "High Sierra"
        case .MOJAVE: return "Mojave"
        case .CATALINA: return "Catalina"
        case .BIG_SUR: return "Big Sur"
        case .MONTEREY: return "Monterey"
        case .VENTURA: return "Ventura"
        case .SONOMA: return "Sonoma"
        case .macOS: return ""
        }
    }
    
    
    static func getOSBuildNum() -> String {
        return run("system_profiler SPSoftwareDataType | grep 'System Version' | cut -c 29-")
    }
    
    
    static func getMacName() -> String {
        // from https://everymac.com/systems/by_capability/mac-specs-by-machine-model-machine-id.html
        let infoString = run("sysctl hw.model | cut -f2 -d \" \" | tr -d '\n'")
        
        // Determines if Desktop or Laptop
        let desktopStrings = ["iMac", "Macmini", "ADP", "MacPro", "Mac13,1", "Mac13,2"]
        macType = desktopStrings.contains(where: infoString.contains) ? .DESKTOP : .LAPTOP

        
        let macModels: [String: (Float, String)] = [
            // iMacs
            "iMac4,1": (17, "iMac 17-Inch \"Core Duo\" 1.83"),
            "iMac4,2": (17, "iMac 17-Inch \"Core Duo\" 1.83"),
            "iMac5,1": (17, "iMac 17-Inch \"Core 2 Duo\" 2.0"),
            "iMac5,2": (17, "iMac 17-Inch \"Core 2 Duo\" 1.83"),
            "iMac7,1": (17, "iMac 17-Inch \"Core 2 Duo\" 2.0"),
            "iMac8,1": (20, "iMac (Early 2008)"),
            "iMac9,1": (20, "iMac (Mid 2009)"),
            "iMac10,1": (20, "iMac (Late 2009)"),
            "iMac11,2": (21.5, "iMac (21.5-Inch, Mid 2010)"),
            "iMac12,1": (21.5, "iMac (21.5-Inch, Mid 2011)"),
            "iMac13,1": (21.5, "iMac (21.5-Inch, Mid 2012/Early 2013)"),
            "iMac14,1": (21.5, "iMac (21.5-Inch, Late 2013)"),
            "iMac14,3": (21.5, "iMac (21.5-Inch, Late 2013)"),
            "iMac14,4": (21.5, "iMac (21.5-Inch, Mid 2014)"),
            "iMac16,1": (21.5, "iMac (21.5-Inch, Late 2015)"),
            "iMac16,2": (21.5, "iMac (21.5-Inch, Late 2015)"),
            "iMac18,1": (21.5, "iMac (21.5-Inch, 2017)"),
            "iMac18,2": (21.5, "iMac (Retina 4K, 2017)"),
            "iMac19,2": (21.5, "iMac (Retina 4K, 2019)"),
            "iMac19,3": (21.5, "iMac (Retina 4K, 2019)"),
            "iMac11,1": (27, "iMac (27-Inch, Late 2009)"),
            "iMac11,3": (27, "iMac (27-Inch, Mid 2010)"),
            "iMac12,2": (27, "iMac (27-Inch, Mid 2011)"),
            "iMac13,2": (27, "iMac (27-Inch, Mid 2012)"),
            "iMac14,2": (27, "iMac (27-Inch, Late 2013)"),
            "iMac15,1": (27, "iMac (Retina 5K, Late 2014)"),
            "iMac17,1": (27, "iMac (Retina 5K, Late 2015)"),
            "iMac18,3": (27, "iMac (Retina 5K, 2017)"),
            "iMac19,1": (27, "iMac (Retina 5K, 2019)"),
            "iMac20,1": (27, "iMac (Retina 5K, 2020)"),
            "iMac20,2": (27, "iMac (Retina 5K, 2020)"),
            "iMac21,1": (24, "iMac (24-inch, M1, 2021)"),
            "iMac21,2": (24, "iMac (24-inch, M1, 2021)"),
            
            // iMac Pros
            "iMacPro1,1": (27, "iMac Pro (2017)"),
            
            // Developer Transition Kits
            "ADP3,2": (0, "Developer Transition Kit (ARM)"),
            
            // Mac Minis
            "Macmini3,1": (0, "Mac Mini (Early 2009)"),
            "Macmini4,1": (0, "Mac Mini (Mid 2010)"),
            "Macmini5,1": (0, "Mac Mini (Mid 2011)"),
            "Macmini5,2": (0, "Mac Mini (Mid 2011)"),
            "Macmini5,3": (0, "Mac Mini (Mid 2011)"),
            "Macmini6,1": (0, "Mac Mini (Late 2012)"),
            "Macmini6,2": (0, "Mac Mini Server (Late 2012)"),
            "Macmini7,1": (0, "Mac Mini (Late 2014)"),
            "Macmini8,1": (0, "Mac Mini (Late 2018)"),
            "Macmini9,1": (0, "Mac Mini (M1, 2020)"),
            "Mac14,3": (0, "Mac Mini (M2, 2023)"),
            "Mac14,12": (0, "Mac Mini (M2 Pro, 2023)"),
            
            // Mac Pros
            "MacPro3,1": (0, "Mac Pro (2008)"),
            "MacPro4,1": (0, "Mac Pro (2009)"),
            "MacPro5,1": (0, "Mac Pro (2010-2012)"),
            "MacPro6,1": (0, "Mac Pro (Late 2013)"),
            "MacPro7,1": (0, "Mac Pro (2019)"),
            
            // Mac Studios
            "Mac13,1": (0, "Mac Studio (2022)"),
            "Mac13,2": (0, "Mac Studio (2022)"),
            
            // MacBooks
            "MacBook5,1": (13, "MacBook"),
            "MacBook5,2": (13, "MacBook (2009)"),
            "MacBook6,1": (13, "MacBook (Late 2009)"),
            "MacBook7,1": (13, "MacBook (Mid 2010)"),
            "MacBook8,1": (13, "MacBook (Early 2015)"),
            "MacBook9,1": (13, "MacBook (Early 2016)"),
            "MacBook10,1": (13, "MacBook (Mid 2017)"),
            
            // MacBook Airs
            "MacBookAir1,1": (13, "MacBook Air (2008)"),
            "MacBookAir2,1": (13, "MacBook Air (Mid 2009)"),
            "MacBookAir3,1": (11, "MacBook Air (11-inch, Late 2010)"),
            "MacBookAir3,2": (13, "MacBook Air (13-inch, Late 2010)"),
            "MacBookAir4,1": (11, "MacBook Air (11-inch, Mid 2011)"),
            "MacBookAir4,2": (13, "MacBook Air (13-inch, Mid 2011)"),
            "MacBookAir5,1": (11, "MacBook Air (11-inch, Mid 2012)"),
            "MacBookAir5,2": (13, "MacBook Air (13-inch, Mid 2012)"),
            "MacBookAir6,1": (11, "MacBook Air (11-inch, Mid 2013/Early 2014)"),
            "MacBookAir6,2": (13, "MacBook Air (13-inch, Mid 2013/Early 2014)"),
            "MacBookAir7,1": (11, "MacBook Air (11-inch, Early 2015/2017)"),
            "MacBookAir7,2": (13, "MacBook Air (13-inch, Early 2015/2017)"),
            "MacBookAir8,1": (13, "MacBook Air (13-inch, Late 2018)"),
            "MacBookAir8,2": (13, "MacBook Air (13-inch, 2019)"),
            "MacBookAir9,1": (13, "MacBook Air (13-inch, 2020)"),
            "MacBookAir10,1": (13, "MacBook Air (13-inch, M1, 2020)"),
            "Mac14,2": (13, "MacBook Air (13-inch, M2, 2022)"),
            
            // MacBook Pros
            // 13-inch
            "MacBookPro5,5": (13, "MacBook Pro (13-inch, 2009)"),
            "MacBookPro7,1": (13, "MacBook Pro (13-inch, Mid 2010)"),
            "MacBookPro8,1": (13, "MacBook Pro (13-inch, Early 2011)"),
            "MacBookPro9,2": (13, "MacBook Pro (13-inch, Mid 2012)"),
            "MacBookPro10,2": (13, "MacBook Pro (Retina, 13-inch, 2012)"),
            "MacBookPro11,1": (13, "MacBook Pro (Retina, 13-inch, Late 2013/Mid 2014)"),
            "MacBookPro12,1": (13, "MacBook Pro (Retina, 13-inch, Early 2015)"),
            "MacBookPro13,1": (13, "MacBook Pro (Retina, 13-inch, Late 2016)"),
            "MacBookPro13,2": (13, "MacBook Pro (Retina, 13-inch, Late 2016)"),
            "MacBookPro14,1": (13, "MacBook Pro (Retina, 13-inch, Mid 2017)"),
            "MacBookPro14,2": (13, "MacBook Pro (Retina, 13-inch, Mid 2017)"),
            "MacBookPro15,2": (13, "MacBook Pro (Retina, 13-inch, Mid 2018)"),
            "MacBookPro15,4": (13, "MacBook Pro (Retina, 13-inch, Mid 2019)"),
            "MacBookPro16,2": (13, "MacBook Pro (Retina, 13-inch, Mid 2020)"),
            "MacBookPro16,3": (13, "MacBook Pro (Retina, 13-inch, Mid 2020)"),
            "MacBookPro17,1": (13, "MacBook Pro (13-inch, M1, 2020)"),
            "Mac14,7": (13, "MacBook Pro (13-inch, M2, 2022)"),
            
            // 14-inch
            "MacBookPro18,3": (14, "MacBook Pro (14-inch, 2021)"),
            "MacBookPro18,4": (14, "MacBook Pro (14-inch, 2021)"),
            "Mac14,5": (14, "MacBook Pro (14-inch, 2023)"),
            "Mac14,9": (14, "MacBook Pro (14-inch, 2023)"),
            
            // 15-inch
            "MacBookPro4,1": (15, "MacBook Pro (15/17-inch, 2008)"),
            "MacBookPro6,2": (15, "MacBook Pro (15-inch, Mid 2010)"),
            "MacBookPro8,2": (15, "MacBook Pro (15-inch, Early 2011)"),
            "MacBookPro9,1": (15, "MacBook Pro (15-inch, Mid 2012)"),
            "MacBookPro10,1": (15, "MacBook Pro (Retina, 15-inch, Mid 2012)"),
            "MacBookPro11,2": (15, "MacBook Pro (Retina, 15-inch, Late 2013)"),
            "MacBookPro11,3": (15, "MacBook Pro (Retina, 15-inch, Mid 2014)"),
            "MacBookPro11,4": (15, "MacBook Pro (Retina, 15-inch, Mid 2015)"),
            "MacBookPro11,5": (15, "MacBook Pro (Retina, 15-inch, Mid 2015)"),
            "MacBookPro13,3": (15, "MacBook Pro (Retina, 15-inch, Late 2016)"),
            "MacBookPro14,3": (15, "MacBook Pro (Retina, 15-inch, Late 2017)"),
            "MacBookPro15,1": (15, "MacBook Pro (Retina, 15-inch, 2018/2019)"),
            "MacBookPro15,3": (15, "MacBook Pro (Retina, 15-inch, 2018/2019)"),
            
            // 16-inch
            "MacBookPro16,1": (16, "MacBook Pro (Retina, 16-inch, Mid 2019)"),
            "MacBookPro16,4": (16, "MacBook Pro (Retina, 16-inch, Mid 2019)"),
            "MacBookPro18,1": (16, "MacBook Pro (16-inch, 2021)"),
            "MacBookPro18,2": (16, "MacBook Pro (16-inch, 2021)"),
            "Mac14,6": (16, "MacBook Pro (16-inch, 2023)"),
            "Mac14,10": (16, "MacBook Pro (16-inch, 2023)"),
            
            // 17-inch
            "MacBookPro8,3": (17, "MacBook Pro (17-inch, Late 2011)"),
            
            // In the rare case that the Mac model is not found
            "Unknown": (0, "Mac (UNKNOWN)"),
            "Mac": (0, "Mac"),
        ]
        if let (displaySize, name) = macModels[infoString] {
            builtInDisplaySize = displaySize
            return name
        }
        return "Mac"
    }
    
    static func getCPU() -> String {
        return run("sysctl -n machdep.cpu.brand_string")
    }
    
    static func getStorageType() -> Bool {
        let name = "\(HardwareCollector.getStartupDisk())"
        let storageType = run("diskutil info \"\(name)\" | grep 'Solid State'")
        return storageType.contains("Yes")
    }

    
    static func getStorageData() -> [String] {
        let name = "\(HardwareCollector.getStartupDisk())"
        let size = run("diskutil info \"\(name)\" | grep 'Disk Size' | sed 's/.*:                 //' | cut -f1 -d'(' | tr -d '\n'")
        let available = run("diskutil info \"\(name)\" | Grep 'Container Free Space' | sed 's/.*:      //' | cut -f1 -d'(' | tr -d '\n'")
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

enum macOSvers {
    case MAVERICKS
    case YOSEMITE
    case EL_CAPITAN
    case SIERRA
    case HIGH_SIERRA
    case MOJAVE
    case CATALINA
    case BIG_SUR
    case MONTEREY
    case VENTURA
    case SONOMA
    case macOS
}
enum macType {
    case DESKTOP
    case LAPTOP
}
