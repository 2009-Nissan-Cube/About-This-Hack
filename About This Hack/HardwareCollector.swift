//
//  HardwareCollector.swift
//  HardwareCollector
//
//  Created by Marc Nich on 8/26/21.
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
    static var dataHasBeenSet: Bool = false
    
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
        if qHackintosh {
            OpenCoreString = getOpenCore()
        }
        else {
            OpenCoreString = ""
        }
        
        dataHasBeenSet = true
    }
    
    
    static func getOpenCore() -> String {
        var opencore1: String
        var opencore2: String
        var opencore3: String
        var tmp: String
        var opencoreType: String
        opencore1 = (try? call("nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | cut -c 59- | cut -c -1")) ?? "X"
        opencore2 = (try? call("nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | cut -c 60- | cut -c -1")) ?? "X"
        opencore3 = (try? call("nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | cut -c 61- | cut -c -1")) ?? "X"
        opencoreType = (try? call("nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | cut -c 55- | cut -c -3")) ?? "N/A"
        if opencore1 == "0" {
            if opencoreType == "REL" {
                opencoreType = "(Release)"
            } else if opencoreType == "N/A" {
                opencoreType = ""
            } else {
                opencoreType = "(Debug)"
            }
            tmp = "\(opencore1).\(opencore2).\(opencore3) \(opencoreType)"
            qHackintosh = true
        }
        if(opencore1 == opencore2 && opencore2 == opencore3 && opencore3 == "") {
            qHackintosh = false
            print("No opencore thus hidden")
            return ""
        }
        return "\(opencore1).\(opencore2).\(opencore3) \(opencoreType)"
    }
    
    
    static func getSerialNumber() -> String {
        return (try? call("system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'")) ?? "Unknown Serial Number"
    }
    
    static func getStartupDisk() -> String {
        return (try? call("system_profiler SPSoftwareDataType | grep 'Boot Volume' | sed 's/.*: //'")) ?? "Unknown Startup Disk"
    }
    
    static func getGPU() -> String {
        let graphicsTmp = (try? call("system_profiler SPDisplaysDataType | awk -F': ' '/^\\ *Chipset Model:/ {printf $2 \" \"}'")) ?? "Unknown GPU"
        let graphicsRAM  = (try? call("system_profiler SPDisplaysDataType | grep VRAM | sed 's/.*: //'")) ?? "Unknown GPU RAM"
        return "\(graphicsTmp)\(graphicsRAM)"
    }
    static func getDisp() -> String {
        var tmp = (try? call("system_profiler SPDisplaysDataType | grep Resolution | sed 's/.*: //'")) ?? "Unknown Display"
        if tmp.contains("(QHD"){
            tmp = (try? call("system_profiler SPDisplaysDataType | grep Resolution | sed 's/.*: //' | cut -c -11")) ?? "Unknown Display"
        }
        if(tmp.contains("\n")) {
            let displayID = tmp.firstIndex(of: "\n")!
            let displayTrimmed = String(tmp[..<displayID])
            tmp = displayTrimmed
        }
        return tmp
    }
    
    static func getRam() -> String {
        var ram = (try? call("echo \"$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))\"")) ?? "RAM Error"
        var ramReturn = "\(ram) GB"
        let ramInfoCache = (try? call("system_profiler SPMemoryDataType")) ?? "RAM Error"
        let ramSpeedTmp = (try? call("echo \"\(ramInfoCache)\" | grep Speed:")) ?? "RAM Error"
        let ramSpeedID = ramSpeedTmp.firstIndex(of: "\n")!
        let ramSpeedTrim1 = String(ramSpeedTmp[ramSpeedID...])
        print(ramSpeedTrim1)
        let ramSpeedID1 = ramSpeedTrim1.firstIndex(of: ":")!
        let ramSpeedTrim2 = String(ramSpeedTrim1[ramSpeedID1...])
        let ramSpeedID2 = ramSpeedTrim2.firstIndex(of: " ")!
        var ramSpeedTrim3 = String(ramSpeedTrim2[ramSpeedID2...])
        if(ramSpeedTrim3.contains("\n")) {
            let ramID = ramSpeedTrim3.firstIndex(of: "\n")!
            let ramTrimFinal = String(ramSpeedTrim3[..<ramID])
            ramSpeedTrim3 = ramTrimFinal
        }
        ramReturn = "\(ramReturn)\(ramSpeedTrim3)"
        let ramType = (try? call("echo \"\(ramInfoCache)\" | grep Type: | cut -c 16-")) ?? "RAM Error"
        let ramTypeID = ramType.firstIndex(of: "\n")!
        let ramTypeTrim = String(ramType[ramTypeID...])
        let ramTypeID1 = ramTypeTrim.firstIndex(of: " ")!
        let ramTypeTrim1 = String(ramTypeTrim[ramTypeID1...])
        var ramTypeOfficial = ramTypeTrim1
        if(ramTypeTrim1.contains("\n")) {
            let ramTypeID2 = ramTypeTrim1.firstIndex(of: "\n")!
            let ramTypeTrim2 = String(ramTypeTrim1[..<ramTypeID2])
            ramTypeOfficial = ramTypeTrim2
        }
        ramReturn = "\(ramReturn)\(ramTypeOfficial)"
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
        return (try? call("sw_vers | grep ProductVersion | cut -c 17-")) ?? "macOS"
    }
    static func setOSvers(osNumber: String) {
        if(osNumber.hasPrefix("12")) {
            OSvers = macOSvers.MONTEREY
        }
        else if(osNumber.hasPrefix("11")) {
            OSvers = macOSvers.BIG_SUR
        }
        else if (osNumber.hasPrefix("10")) {
            let infoString1 = (try? call("sw_vers -productVersion | awk -F '.' '{print  $2}'")) ?? "15"
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
        return (try? call("system_profiler SPSoftwareDataType | grep 'System Version' | cut -c 29-")) ?? ""
    }
    
    
    static func getMacName() -> String {
        // from https://everymac.com/systems/by_capability/mac-specs-by-machine-model-machine-id.html
        let infoString = (try? call("sysctl hw.model | cut -f2 -d \" \"")) ?? "Mac"
        switch(infoString) {
        case "iMac4,1":
            return "iMac 17-Inch \"Core Duo\" 1.83"
        case "iMac4,2":
            return "iMac 17-Inch \"Core Duo\" 1.83 (IG)"
        case "iMac5,2":
            return "iMac 17-Inch \"Core 2 Duo\" 1.83 (IG)"
        case "iMac5,1":
            return "iMac 17-Inch \"Core 2 Duo\" 2.0"
        case "iMac7,1":
            return "iMac 20-Inch \"Core 2 Duo\" 2.0 (Al)"
        case "iMac8,1":
            return "iMac (Early 2008)"
        case "iMac9,1":
            return "iMac (Mid 2009)"
        case "iMac10,1":
            return "iMac (Late 2009)"
        case "iMac11,2":
            return "iMac 21.5-Inch (Mid 2010)"
        case "iMac12,1":
            return "iMac 21.5-Inch (Mid 2011)"
        case "iMac13,1":
            return "iMac 21.5-Inch (Mid 2012/Early 2013)"
        case "iMac14,1","iMac14,3":
            return "iMac 21.5-Inch (Late 2013)"
        case "iMac14,4":
            return "iMac 21.5-Inch (Mid 2014)"
        case "iMac16,1","iMac16,2":
            return "iMac 21.5-Inch (Late 2015)"
        case "iMac18,1":
            return "iMac 21.5-Inch (2017)"
        case "iMac18,2":
            return "iMac 21.5-Inch (Retina 4K, 2017)"
        case "iMac19,3":
            return "iMac 21.5-Inch (Retina 4K, 2019)"
        case "iMac11,1":
            return "iMac 27-Inch (Late 2009)"
        case "iMac11,3":
            return "iMac 27-Inch (Mid 2010)"
        case "iMac12,2":
            return "iMac 27-inch (Mid 2011)"
        case "iMac13,2":
            return "iMac 27-inch (Mid 2012)"
        case "iMac14,2":
            return "iMac 27-inch (Late 2013)"
        case "iMac15,1":
            return "iMac 27-inch (Retina 5K, Late 2014)"
        case "iMac17,1":
            return "iMac 27-inch (Retina 5K, Late 2015)"
        case "iMac18,3":
            return "iMac 27-inch (Retina 5K, 2017)"
        case "iMac19,1":
            return "iMac 27-inch (Retina 5K, 2019)"
        case "iMac19,2":
            return "iMac 21.5-inch (Retina 4K, 2019)"
        case "iMac20,1","iMac20,2":
            return "iMac 27-inch (Retina 5K, 2020)"
        case "iMac21,1","iMac21,2":
            return "iMac (24-inch, M1, 2021)"
            
        
        case "iMacPro1,1":
            return "iMac Pro (2017)"
        
        case "Macmini3,1":
            return "Mac Mini (Late 2009)"
        case "Macmini4,1":
            return "Mac Mini (Mid 2010)"
        case "Macmini5,1":
            return "Mac Mini (Mid 2011)"
        case "Macmini5,2","Macmini5,3":
            return "Mac Mini (Mid 2011)"
        case "Macmini6,1":
            return "Mac Mini (Late 2012)"
        case "Macmini6,2":
            return "Mac Mini Server (Late 2012)"
        case "Macmini7,1":
            return "Mac Mini (Late 2014)"
        case "Macmini8,1":
            return "Mac Mini (Late 2018)"
        case "Macmini9,1":
            return "Mac Mini (M1, 2020)"
            
        case "MacPro3,1":
            return "Mac Pro (2008)"
        case "MacPro4,1":
            return "Mac Pro (2009)"
        case "MacPro5,1":
            return "Mac Pro (2010-2012)"
        case "MacPro6,1":
            return "Mac Pro (Late 2013)"
        case "MacPro7,1":
            return "Mac Pro (2019)"
            
        case "MacBook5,1":
            return "MacBook (Original, Unibody)"
        case "MacBook5,2":
            return "MacBook (2009)"
        case "MacBook6,1":
            return "MacBook (Late 2009)"
        case "MacBook7,1":
            return "MacBook (Mid 2010)"
        case "MacBook8,1":
            return "MacBook (Early 2015)"
        case "MacBook9,1":
            return "MacBook (Early 2016)"
        case "MacBook10,1":
            return "MacBook (Mid 2017)"
        case "MacBookAir1,1":
            return "MacBook Air (2008, Original)"
        case "MacBookAir2,1":
            return "MacBook Air (Mid 2009, NVIDIA)"
        case "MacBookAir3,1":
            return "MacBook Air (11-inch, Late 2010)"
        case "MacBookAir3,2":
            return "MacBook Air (13-inch, Late 2010)"
        case "MacBookAir4,1":
            return "MacBook Air (11-inch, Mid 2011)"
        case "MacBookAir4,2":
            return "MacBook Air (13-inch, Mid 2011)"
        case "MacBookAir5,1":
            return "MacBook Air (11-inch, Mid 2012)"
        case "MacBookAir5,2":
            return "MacBook Air (13-inch, Mid 2012)"
        case "MacBookAir6,1":
            return "MacBook Air (11-inch, Mid 2013/Early 2014)"
        case "MacBookAir6,2":
            return "MacBook Air (13-inch, Mid 2013/Early 2014)"
        case "MacBookAir7,1":
            return "MacBook Air (11-inch, Early 2015/2017)"
        case "MacBookAir7,2":
            return "MacBook Air (13-inch, Early 2015/2017)"
        case "MacBookAir8,1":
            return "MacBook Air (13-inch, Late 2018)"
        case "MacBookAir8,2":
            return "MacBook Air (13-inch, True-Tone, 2019)"
        case "MacBookAir9,1":
            return "MacBook Air (13-inch, 2020)"
        case "MacBookAir10,1":
            return "MacBook Air (13-inch, M1, 2020)"
            
        case "MacBookPro5,5":
            return "MacBook Pro (13-inch, 2009)"
        case "MacBookPro7,1":
            return "MacBook Pro (13-inch, Mid 2010)"
        case "MacBookPro8,1":
            return "MacBook Pro (13-inch, Early 2011)"
        case "MacBookPro9,2":
            return "MacBook Pro (13-inch, Mid 2012)"
        case "MacBookPro10,2":
            return "MacBook Pro (Retina, 13-inch, 2012)"
        case "MacBookPro11,1":
            return "MacBook Pro (Retina, 13-inch, Late 2013/Mid 2014)"
        case "MacBookPro12,1":
            return "MacBook Pro (Retina, 13-inch, 2015)"
        case "MacBookPro13,1":
            return "MacBook Pro (Retina, 13-inch, Late 2016)"
        case "MacBookPro13,2":
            return "MacBook Pro (Retina, 13-inch, Touch ID/Bar, Late 2016)"
        case "MacBookPro14,1":
            return "MacBook Pro (Retina, 13-inch, Mid 2017)"
        case "MacBookPro14,2":
            return "MacBook Pro (Retina, 13-inch, Touch ID/Bar, Mid 2017)"
        case "MacBookPro15,2":
            return "MacBook Pro (Retina, 13-inch, Touch ID/Bar, Mid 2018)"
        case "MacBookPro15,4":
            return "MacBook Pro (Retina, 13-inch, Touch ID/Bar, Mid 2019)"
        case "MacBookPro16,2","MacBookPro16,3":
            return "MacBook Pro (Retina, 13-inch, Touch ID/Bar, Mid 2020)"
        case "MacBookPro17,1":
            return "MacBook Pro (13-inch, M1, 2020)"
            
        case "MacBookPro6,2":
            return "MacBook Pro (15-inch, Mid 2010)"
        case "MacBookPro8,2":
            return "MacBook Pro (15-inch, Early 2011)"
        case "MacBookPro9,1":
            return "MacBook Pro (15-inch, Mid 2012)"
        case "MacBookPro10,1":
            return "MacBook Pro (Retina, 15-inch, Mid 2012)"
        case "MacBookPro11,2":
            return "MacBook Pro (Retina, 15-inch, Late 2013)"
        case "MacBookPro11,3":
            return "MacBook Pro (Retina, 15-inch, Mid 2014)"
        case "MacBookPro11,4","MacBookPro11,5":
            return "MacBook Pro (Retina, 15-inch, Mid 2015)"
        case "MacBookPro13,3":
            return "MacBook Pro (Retina, 15-inch, Touch ID/Bar, Late 2016)"
        case "MacBookPro14,3":
            return "MacBook Pro (Retina, 15-inch, Touch ID/Bar, Late 2017)"
        case "MacBookPro15,1":
            return "MacBook Pro (Retina, 15-inch, Touch ID/Bar, 2018/2019)"
        case "MacBookPro15,3":
            return "MacBook Pro (Retina Vega Graphics, 15-inch, Touch ID/Bar, 2018/2019)"
        case "MacBookPro16,1":
            return "MacBook Pro (Retina, 16-inch, Touch ID/Bar, 2019)"
        case "MacBookPro8,3":
            return "MacBook Pro (17-inch, Late 2011)"
        case "Unkown","Mac":
            return "Hackintosh Extreme Plus" // hehe just for fun
        default:
            return "Mac"
        }
    }
    
    
    
    
    
    static func getCPU() -> String {
        return (try? call("sysctl -n machdep.cpu.brand_string")) ?? "Unknown"
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
