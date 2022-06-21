//
//  HardwareCollector.swift
//  HardwareCollector
//
//

import Foundation

class HardwareCollector {
    static var OSnum: String = "10.10.0"
    static var OSvers: macOSvers = macOSvers.macOS
    static var OSname: String = ""
    static var OSBuildNum: String = "19G101"
    static var macName: String = "Hackintosh Extreme Plus"
    static var osPrefix: String = "macOS"
    static var CPUstring: String = "i7"
    static var RAMstring: String = "16 GB"
    static var GPUstring: String = "Radeon Pro 560 4GB"
    static var DisplayString: String = "Generic LCD"
    static var StartupDiskString: String = "Macintosh HD"
    static var SerialNumberString: String = "XXXXXXXXXXX"
    static var qHackintosh = false // is it a hackintosh
    static var OpenCoreString: String = ""
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
        OSnum = getOSnum()
        setOSvers(osNumber: OSnum)
        OSname = macOSversToString()
        osPrefix = getOSPrefix()
        OSBuildNum = getOSBuildNum()
        macName = getMacName()
        CPUstring = getCPU()
        RAMstring = getRam()
        GPUstring = getGPU()
        DisplayString = getDisp()
        StartupDiskString = getStartupDisk()
        SerialNumberString = getSerialNumber()
        OpenCoreString = getOpenCore()
        if !qHackintosh {
            OpenCoreString = ""
        }
        numberOfDisplays = getNumDisplays()
        qhasBuiltInDisplay = hasBuiltInDisplay()
        displayRes = getDisplayRess()
        displayNames = getDisplayNames()
        // getDisplayDiagonal() Having some issues, removing for now
        storageType = getStorageType()
        storageData = getStorageData()[0]
        storagePercent = Double(getStorageData()[1])!
        
        dataHasBeenSet = true
    }
    
    static func getDisplayDiagonal() -> Float {
        
        return 13.3
    }
    
    static func getDisplayRess() -> [String] {
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
        return []
    }
    
    static func getDisplayNames() -> [String] {
        let numDispl = getNumDisplays()
        if numDispl == 1 {
            return [run("""
echo "$(system_profiler SPDisplaysDataType | grep "Display Type" | cut -c 25-)"
echo "$(system_profiler SPDisplaysDataType -xml | grep -A2 "</data>" | awk -F'>|<' '/_name/{getline; print $3}')" | tr -d '\n'
""")] //

        }
        else if (numDispl == 2) {
            let tmp = run("""
echo "$(system_profiler SPDisplaysDataType -xml | grep -A2 "</data>" | awk -F'>|<' '/_name/{getline; print $3}')" | tr -d '\n'
""")
            let tmpParts = tmp.components(separatedBy: "\n")
            return tmpParts
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
    
    
    static func getOpenCore() -> String {
        var opencore1: String
        var opencore2: String
        var opencore3: String
        var tmp: String
        var opencoreType: String
        opencore1 = run("nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | cut -c 59- | cut -c -1 | tr -d '\n'")
        opencore2 = run("nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | cut -c 60- | cut -c -1 | tr -d '\n'")
        opencore3 = run("nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | cut -c 61- | cut -c -1 | tr -d '\n'")
        opencoreType = run("nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | cut -c 55- | cut -c -3 | tr -d '\n'")
        if opencore1.contains("0") {
            if opencoreType.contains("REL") {
                opencoreType = "(Release)"
            } else if opencoreType.contains("N/A") {
                opencoreType = ""
            } else {
                opencoreType = "(Debug)"
            }
            tmp = "\(opencore1).\(opencore2).\(opencore3) \(opencoreType)"
            print(tmp, terminator: "")
            qHackintosh = true
        }
        if(opencore1 == opencore2 && opencore2 == opencore3 && opencore3 == "") {
            qHackintosh = false
            print("No opencore; hiding menu")
            return ""
        }
        return "\(opencore1).\(opencore2).\(opencore3) \(opencoreType)"
    }
    
    
    static func getSerialNumber() -> String {
        return run("system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'")
    }
    
    static func getStartupDisk() -> String {
        return run("system_profiler SPSoftwareDataType | grep 'Boot Volume' | sed 's/.*: //' | tr -d '\n'")
    }
    
    static func getGPU() -> String {
        let graphicsTmp = run("system_profiler SPDisplaysDataType | awk -F': ' '/^\\ *Chipset Model:/ {printf $2 \" \"}'")
        let graphicsRAM  = run("system_profiler SPDisplaysDataType | grep VRAM | sed 's/.*: //'")
        return "\(graphicsTmp)\(graphicsRAM)"
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
        let ramReturn = "\(ram) GB"
        return ramReturn
    }
    
    
    
    static func getOSPrefix() -> String{
        switch OSvers {
        case .MAVERICKS,.YOSEMITE,.EL_CAPITAN:
            return "OS X"
        case .SIERRA,.HIGH_SIERRA,.MOJAVE,.CATALINA,.BIG_SUR,.MONTEREY,.macOS:
            return "macOS"
        }
    }
    
    
    static func getOSnum() -> String {
        return run("sw_vers | grep ProductVersion | cut -c 17-")
    }
    static func setOSvers(osNumber: String) {
        if(osNumber.hasPrefix("12")) {
            OSvers = macOSvers.MONTEREY
        }
        else if(osNumber.hasPrefix("11")) {
            OSvers = macOSvers.BIG_SUR
        }
        else if (osNumber.hasPrefix("10")) {
            let infoString1 = run("sw_vers -productVersion | awk -F '.' '{print  $2}' | tr -d '\n'")
            switch(infoString1) {
            case "16":
                OSvers = macOSvers.BIG_SUR
            case "15":
                OSvers = macOSvers.CATALINA
            case "14":
                OSvers = macOSvers.MOJAVE
            case "13":
                OSvers = macOSvers.HIGH_SIERRA
            case "12":
                OSvers = macOSvers.SIERRA
            case "11":
                OSvers = macOSvers.EL_CAPITAN
            case "10":
                OSvers = macOSvers.YOSEMITE
            case "9":
                OSvers = macOSvers.MAVERICKS
            default:
                OSvers = macOSvers.macOS
            }
            
        }
        else {
            OSvers = macOSvers.macOS
        }
    }
    
    
    static func macOSversToString() -> String {
        switch OSvers {
        case .MAVERICKS:
            return "Mavericks"
        case .YOSEMITE:
            return "Yosemite"
        case .EL_CAPITAN:
            return "El Capitan"
        case .SIERRA:
            return "Sierra"
        case .HIGH_SIERRA:
            return "High Sierra"
        case .MOJAVE:
            return "Mojave"
        case .CATALINA:
            return "Catalina"
        case .BIG_SUR:
            return "Big Sur"
        case .MONTEREY:
            return "Monterey"
        case .macOS:
            return ""
        }
    }
    
    
    static func getOSBuildNum() -> String {
        return run("system_profiler SPSoftwareDataType | grep 'System Version' | cut -c 29-")
    }
    
    
    static func getMacName() -> String {
        // from https://everymac.com/systems/by_capability/mac-specs-by-machine-model-machine-id.html
        let infoString = run("sysctl hw.model | cut -f2 -d \" \" | tr -d '\n'")
        switch(infoString) {
        case "iMac4,1":
            builtInDisplaySize = 17
            return "iMac 17-Inch \"Core Duo\" 1.83"
        case "iMac4,2":
            builtInDisplaySize = 17
            return "iMac 17-Inch \"Core Duo\" 1.83 (IG)"
        case "iMac5,2":
            builtInDisplaySize = 17
            return "iMac 17-Inch \"Core 2 Duo\" 1.83 (IG)"
        case "iMac5,1":
            builtInDisplaySize = 17
            return "iMac 17-Inch \"Core 2 Duo\" 2.0"
        case "iMac7,1":
            builtInDisplaySize = 17
            return "iMac 20-Inch \"Core 2 Duo\" 2.0 (Al)"
        case "iMac8,1":
            builtInDisplaySize = 20
            return "iMac (Early 2008)"
        case "iMac9,1":
            builtInDisplaySize = 20
            return "iMac (Mid 2009)"
        case "iMac10,1":
            builtInDisplaySize = 20
            return "iMac (Late 2009)"
        case "iMac11,2":
            builtInDisplaySize = 21.5
            return "iMac 21.5-Inch (Mid 2010)"
        case "iMac12,1":
            builtInDisplaySize = 21.5
            return "iMac 21.5-Inch (Mid 2011)"
        case "iMac13,1":
            builtInDisplaySize = 21.5
            return "iMac 21.5-Inch (Mid 2012/Early 2013)"
        case "iMac14,1","iMac14,3":
            builtInDisplaySize = 21.5
            return "iMac 21.5-Inch (Late 2013)"
        case "iMac14,4":
            builtInDisplaySize = 21.5
            return "iMac 21.5-Inch (Mid 2014)"
        case "iMac16,1","iMac16,2":
            builtInDisplaySize = 21.5
            return "iMac 21.5-Inch (Late 2015)"
        case "iMac18,1":
            builtInDisplaySize = 21.5
            return "iMac 21.5-Inch (2017)"
        case "iMac18,2":
            builtInDisplaySize = 21.5
            return "iMac 21.5-Inch (Retina 4K, 2017)"
        case "iMac19,3":
            builtInDisplaySize = 21.5
            return "iMac 21.5-Inch (Retina 4K, 2019)"
        case "iMac11,1":
            builtInDisplaySize = 27
            return "iMac 27-Inch (Late 2009)"
        case "iMac11,3":
            builtInDisplaySize = 27
            return "iMac 27-Inch (Mid 2010)"
        case "iMac12,2":
            builtInDisplaySize = 27
            return "iMac 27-inch (Mid 2011)"
        case "iMac13,2":
            builtInDisplaySize = 27
            return "iMac 27-inch (Mid 2012)"
        case "iMac14,2":
            builtInDisplaySize = 27
            return "iMac 27-inch (Late 2013)"
        case "iMac15,1":
            builtInDisplaySize = 27
            return "iMac 27-inch (Retina 5K, Late 2014)"
        case "iMac17,1":
            builtInDisplaySize = 27
            return "iMac 27-inch (Retina 5K, Late 2015)"
        case "iMac18,3":
            builtInDisplaySize = 27
            return "iMac 27-inch (Retina 5K, 2017)"
        case "iMac19,1":
            builtInDisplaySize = 27
            return "iMac 27-inch (Retina 5K, 2019)"
        case "iMac19,2":
            builtInDisplaySize = 27
            return "iMac 21.5-inch (Retina 4K, 2019)"
        case "iMac20,1","iMac20,2":
            builtInDisplaySize = 27
            return "iMac 27-inch (Retina 5K, 2020)"
        case "iMac21,1","iMac21,2":
            builtInDisplaySize = 24
            return "iMac (24-inch, M1, 2021)"
            
        
        case "iMacPro1,1":
            builtInDisplaySize = 27
            return "iMac Pro (2017)"
            
        case "ADP3,2":
            macType = .DESKTOP
            return "Developer Transition Kit (ARM)"
        
        case "Macmini3,1":
            macType = .DESKTOP
            return "Mac Mini (Late 2009)"
        case "Macmini4,1":
            macType = .DESKTOP
            return "Mac Mini (Mid 2010)"
        case "Macmini5,1":
            macType = .DESKTOP
            return "Mac Mini (Mid 2011)"
        case "Macmini5,2","Macmini5,3":
            return "Mac Mini (Mid 2011)"
        case "Macmini6,1":
            macType = .DESKTOP
            return "Mac Mini (Late 2012)"
        case "Macmini6,2":
            macType = .DESKTOP
            return "Mac Mini Server (Late 2012)"
        case "Macmini7,1":
            macType = .DESKTOP
            return "Mac Mini (Late 2014)"
        case "Macmini8,1":
            macType = .DESKTOP
            return "Mac Mini (Late 2018)"
        case "Macmini9,1":
            macType = .DESKTOP
            return "Mac Mini (M1, 2020)"
            
        case "MacPro3,1":
            macType = .DESKTOP
            return "Mac Pro (2008)"
        case "MacPro4,1":
            macType = .DESKTOP
            return "Mac Pro (2009)"
        case "MacPro5,1":
            macType = .DESKTOP
            return "Mac Pro (2010-2012)"
        case "MacPro6,1":
            macType = .DESKTOP
            return "Mac Pro (Late 2013)"
        case "MacPro7,1":
            macType = .DESKTOP
            return "Mac Pro (2019)"
            
        case "Mac13,1","Mac13,2":
            macType = .DESKTOP
            return "Mac Studio (2022)"
            
        case "MacBook5,1":
            builtInDisplaySize = 13
            return "MacBook (Original, Unibody)"
        case "MacBook5,2":
            builtInDisplaySize = 13
            return "MacBook (2009)"
        case "MacBook6,1":
            builtInDisplaySize = 13
            return "MacBook (Late 2009)"
        case "MacBook7,1":
            builtInDisplaySize = 13
            return "MacBook (Mid 2010)"
        case "MacBook8,1":
            builtInDisplaySize = 13
            return "MacBook (Early 2015)"
        case "MacBook9,1":
            builtInDisplaySize = 13
            return "MacBook (Early 2016)"
        case "MacBook10,1":
            builtInDisplaySize = 13
            return "MacBook (Mid 2017)"
        case "MacBookAir1,1":
            builtInDisplaySize = 13
            return "MacBook Air (2008, Original)"
        case "MacBookAir2,1":
            builtInDisplaySize = 13
            return "MacBook Air (Mid 2009, NVIDIA)"
        case "MacBookAir3,1":
            builtInDisplaySize = 11
            return "MacBook Air (11-inch, Late 2010)"
        case "MacBookAir3,2":
            builtInDisplaySize = 13
            return "MacBook Air (13-inch, Late 2010)"
        case "MacBookAir4,1":
            builtInDisplaySize = 11
            return "MacBook Air (11-inch, Mid 2011)"
        case "MacBookAir4,2":
            builtInDisplaySize = 13
            return "MacBook Air (13-inch, Mid 2011)"
        case "MacBookAir5,1":
            builtInDisplaySize = 11
            return "MacBook Air (11-inch, Mid 2012)"
        case "MacBookAir5,2":
            builtInDisplaySize = 13
            return "MacBook Air (13-inch, Mid 2012)"
        case "MacBookAir6,1":
            builtInDisplaySize = 11
            return "MacBook Air (11-inch, Mid 2013/Early 2014)"
        case "MacBookAir6,2":
            builtInDisplaySize = 13
            return "MacBook Air (13-inch, Mid 2013/Early 2014)"
        case "MacBookAir7,1":
            builtInDisplaySize = 11
            return "MacBook Air (11-inch, Early 2015/2017)"
        case "MacBookAir7,2":
            builtInDisplaySize = 13
            return "MacBook Air (13-inch, Early 2015/2017)"
        case "MacBookAir8,1":
            builtInDisplaySize = 13
            return "MacBook Air (13-inch, Late 2018)"
        case "MacBookAir8,2":
            builtInDisplaySize = 13
            return "MacBook Air (13-inch, True-Tone, 2019)"
        case "MacBookAir9,1":
            builtInDisplaySize = 13
            return "MacBook Air (13-inch, 2020)"
        case "MacBookAir10,1":
            builtInDisplaySize = 13
            return "MacBook Air (13-inch, M1, 2020)"
            
        case "MacBookPro5,5":
            builtInDisplaySize = 13
            return "MacBook Pro (13-inch, 2009)"
        case "MacBookPro7,1":
            builtInDisplaySize = 13
            return "MacBook Pro (13-inch, Mid 2010)"
        case "MacBookPro8,1":
            builtInDisplaySize = 13
            return "MacBook Pro (13-inch, Early 2011)"
        case "MacBookPro9,2":
            builtInDisplaySize = 13
            return "MacBook Pro (13-inch, Mid 2012)"
        case "MacBookPro10,2":
            builtInDisplaySize = 13
            return "MacBook Pro (Retina, 13-inch, 2012)"
        case "MacBookPro11,1":
            builtInDisplaySize = 13
            return "MacBook Pro (Retina, 13-inch, Late 2013/Mid 2014)"
        case "MacBookPro12,1":
            builtInDisplaySize = 13
            return "MacBook Pro (Retina, 13-inch, 2015)"
        case "MacBookPro13,1":
            builtInDisplaySize = 13
            return "MacBook Pro (Retina, 13-inch, Late 2016)"
        case "MacBookPro13,2":
            builtInDisplaySize = 13
            return "MacBook Pro (Retina, 13-inch, Touch ID/Bar, Late 2016)"
        case "MacBookPro14,1":
            builtInDisplaySize = 13
            return "MacBook Pro (Retina, 13-inch, Mid 2017)"
        case "MacBookPro14,2":
            builtInDisplaySize = 13
            return "MacBook Pro (Retina, 13-inch, Touch ID/Bar, Mid 2017)"
        case "MacBookPro15,2":
            builtInDisplaySize = 13
            return "MacBook Pro (Retina, 13-inch, Touch ID/Bar, Mid 2018)"
        case "MacBookPro15,4":
            builtInDisplaySize = 13
            return "MacBook Pro (Retina, 13-inch, Touch ID/Bar, Mid 2019)"
        case "MacBookPro16,2","MacBookPro16,3":
            builtInDisplaySize = 13
            return "MacBook Pro (Retina, 13-inch, Touch ID/Bar, Mid 2020)"
        case "MacBookPro16,4":
            builtInDisplaySize = 16
            return "MacBook Pro (Retina, 16-inch, Touch ID/Bar, Mid 2019)"
        case "MacBookPro17,1":
            builtInDisplaySize = 13
            return "MacBook Pro (13-inch, M1, 2020)"
            
        case "MacBookPro6,2":
            builtInDisplaySize = 15
            return "MacBook Pro (15-inch, Mid 2010)"
        case "MacBookPro8,2":
            builtInDisplaySize = 15
            return "MacBook Pro (15-inch, Early 2011)"
        case "MacBookPro9,1":
            builtInDisplaySize = 15
            return "MacBook Pro (15-inch, Mid 2012)"
        case "MacBookPro10,1":
            builtInDisplaySize = 15
            return "MacBook Pro (Retina, 15-inch, Mid 2012)"
        case "MacBookPro11,2":
            builtInDisplaySize = 15
            return "MacBook Pro (Retina, 15-inch, Late 2013)"
        case "MacBookPro11,3":
            builtInDisplaySize = 15
            return "MacBook Pro (Retina, 15-inch, Mid 2014)"
        case "MacBookPro11,4","MacBookPro11,5":
            builtInDisplaySize = 15
            return "MacBook Pro (Retina, 15-inch, Mid 2015)"
        case "MacBookPro13,3":
            builtInDisplaySize = 15
            return "MacBook Pro (Retina, 15-inch, Touch ID/Bar, Late 2016)"
        case "MacBookPro14,3":
            builtInDisplaySize = 15
            return "MacBook Pro (Retina, 15-inch, Touch ID/Bar, Late 2017)"
        case "MacBookPro15,1":
            builtInDisplaySize = 15
            return "MacBook Pro (Retina, 15-inch, Touch ID/Bar, 2018/2019)"
        case "MacBookPro15,3":
            builtInDisplaySize = 15
            return "MacBook Pro (Retina Vega Graphics, 15-inch, Touch ID/Bar, 2018/2019)"
        case "MacBookPro16,1":
            builtInDisplaySize = 16
            return "MacBook Pro (Retina, 16-inch, Touch ID/Bar, 2019)"
        case "MacBookPro8,3":
            builtInDisplaySize = 17
            return "MacBook Pro (17-inch, Late 2011)"
       
        case "Unkown","Mac":
            macType = .DESKTOP
            return "Hackintosh Extreme Plus" // hehe just for fun
        default:
            return "Mac"
        }
    }
    
    static func getCPU() -> String {
        return run("sysctl -n machdep.cpu.brand_string")
    }
    
    static func getStorageType() -> Bool {
        let name = "\(HardwareCollector.getStartupDisk())"
        let storageType = run("diskutil info \"\(name)\" | grep 'Solid State'")
        if storageType.contains("Yes") {
            return true
        } else {
            return false
        }
    }
    
    static func getStorageData() -> [String] {
        let name = "\(HardwareCollector.getStartupDisk())"
        let size = run("diskutil info \"\(name)\" | grep 'Disk Size' | sed 's/.*:                 //' | cut -f1 -d'(' | tr -d '\n'")
        let available = run("diskutil info \"\(name)\" | Grep 'Container Free Space' | sed 's/.*:      //' | cut -f1 -d'(' | tr -d '\n'")
        let sizeTrimmed = run("echo \"\(size)\" | cut -f1 -d\" \"").dropLast(1)
        let availableTrimmed = run("echo \"\(available)\" | cut -f1 -d\" \"").dropLast(1)
        //print("Size: \(sizeTrimmed)")
        //print("Available: \(availableTrimmed)")
        let percent: Double = Double(availableTrimmed)! / Double(sizeTrimmed)!
        //print("%: \(percent)")
        return ["""
\(name)
\(size)(\(available)Available)
""",String(percent)]
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
    case macOS
}
enum macType {
    case DESKTOP
    case LAPTOP
}
