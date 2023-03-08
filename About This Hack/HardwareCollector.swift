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
    static var qHackintosh = false
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
            qHackintosh = true
            BootloaderInfo = run("echo \"OpenCore - Version \" $(nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | awk '{print $2}' | awk -F'-' '{print $2}' | sed -e 's/ */./g' -e s'/^.//g' -e 's/.$//g' -e 's/ .//g' -e 's/. //g' | tr -d '\n') $( nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | awk '{print $2}' | awk -F'-' '{print $1}' | sed -e 's/REL/(Release)/g' -e s'/N\\/A//g' -e 's/DEB/(Debug)/g' | tr -d '\n')")
        }
        else {
            BootloaderInfo = run("system_profiler SPHardwareDataType | grep \"Clover\" | awk '{print $4,\"r\" $6,\"(\" $9,\" \"}' | tr -d '\n'")
            if BootloaderInfo  != "" {
                qHackintosh = true
                BootloaderInfo += run("echo \"(\"$(/usr/local/bin/bdmesg | grep -i \"Build with: \\[Args:\" | awk -F '\\-b' '{print $NF}' |  awk -F '\\-t' '{print $1 $2}' | awk  '{print $2}' | awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}') $(/usr/local/bin/bdmesg | grep -i \"Build with: \\[Args:\" | awk -F '\\-b' '{print $NF}' |  awk -F '\\-t' '{print $1 $2}' | awk  '{print $1}' | awk '{print toupper(substr($0,0,1))tolower(substr($0,2))}')\")\"")
            }
            else {
                qHackintosh = false
                BootloaderInfo = " "
                print("No Bootloader found; hiding menu")
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
        case .SIERRA,.HIGH_SIERRA,.MOJAVE,.CATALINA,.BIG_SUR,.MONTEREY,.VENTURA,.macOS:
            return "macOS"
        }
    }
    
    
    static func getOSnum() -> String {
        return run("sw_vers | grep ProductVersion | awk '{print $2}'")
    }
    static func setOSvers(osNumber: String) {
        if (osNumber.hasPrefix("13")) {
            OSvers = macOSvers.VENTURA
        }
        else if (osNumber.hasPrefix("12")) {
            OSvers = macOSvers.MONTEREY
        }
        else if (osNumber.hasPrefix("11")) {
            OSvers = macOSvers.BIG_SUR
        }
        else if (osNumber.hasPrefix("10")) {
            switch(osNumber) {
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
        case .VENTURA:
            return "Ventura"
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
            
        // iMacs
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
            
        // iMac Pros
        case "iMacPro1,1":
            builtInDisplaySize = 27
            return "iMac Pro (2017)"
            
        // Developer Transition Kits
        case "ADP3,2":
            macType = .DESKTOP
            return "Developer Transition Kit (ARM)"
        
        // Mac Minis
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
        case "Mac14,3":
            macType = .DESKTOP
            return "Mac Mini (M2, 2023)"
        case "Mac14,12":
            macType = .DESKTOP
            return "Mac Mini (M2 Pro, 2023)"
            
        // Mac Pros
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
        
        // Mac Studios
        case "Mac13,1","Mac13,2":
            macType = .DESKTOP
            return "Mac Studio (2022)"
        
        // MacBooks
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
            
        // MacBook Airs
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
        case "Mac14,2":
            builtInDisplaySize = 13
            return "MacBook Air (13-inch, M2, 2022)"
        
        // MacBook Pros
        // 13-inch Models
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
        case "MacBookPro17,1":
            builtInDisplaySize = 13
            return "MacBook Pro (13-inch, M1, 2020)"
        case "Mac14,7":
            builtInDisplaySize = 13
            return "MacBook Pro (13-inch, M2, 2022)"
            
        // 14-inch Models
        case "MacBookPro18,3","MacBookPro18,4":
            builtInDisplaySize = 14
            return "MacBook Pro (14-inch, 2021)"
        case "Mac14,5","Mac14,9":
            builtInDisplaySize = 14
            return "MacBook Pro (14-inch, 2023)"
            
        // 15-inch Models
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
        
        // 16-inch Models
        case "MacBookPro16,1":
            builtInDisplaySize = 16
            return "MacBook Pro (Retina, 16-inch, Touch ID/Bar, Mid 2019)"
        case "MacBookPro16,4":
            builtInDisplaySize = 16
            return "MacBook Pro (Retina, 16-inch, Touch ID/Bar, Mid 2019)"
        case "MacBookPro18,1","MacBookPro18,2":
            builtInDisplaySize = 16
            return "MacBook Pro (16-inch, 2021)"
        case "Mac14,6","Mac14,10":
            builtInDisplaySize = 16
            return "MacBook Pro (16-inch, 2023)"
        
        // 17-inch Models
        case "MacBookPro8,3":
            builtInDisplaySize = 17
            return "MacBook Pro (17-inch, Late 2011)"
       
        // In the rare case that the Mac is not detected
        case "Unknown","Mac":
            macType = .DESKTOP
            return "Mac (Unknown)"
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
        print("Size: \(sizeTrimmed)")
        print("Available: \(availableTrimmed)")
        var percent: Double = (Double(availableTrimmed)!) / Double(sizeTrimmed)!
        if(percent > 1.0) {
            percent = percent / 1024.0 // GB instead of TB
            if(percent > 1.0) {
                percent = percent / 1024.0 // MB instead of TB
            }
        }
        print("%: \(1-percent)")
        
        // Get the main language code (en for English, es for Spanish)
        // This is the device language
        // let locale = NSLocale.current.languageCode
        // print ("Device language: \(locale)") // for testing
        // This is the app language
        let idioma = Bundle.main.preferredLocalizations[0]
        // print("Idioma : \(idioma)")  // for testing
        
        // If it's Spanish
        if idioma == "es" {
            return ["""
    \(name)
    \(size)(\(available)Disponible)
    """,String(1-percent)]
        }
        
        else if idioma == "fr" {
            return ["""
    \(name)
    \(size)(\(available)Disponible)
    """,String(1-percent)]
        }
        else if idioma == "ro" {
            return ["""
    \(name)
    \(size)(\(available)Disponibil)
    """,String(1-percent)]
        }
        
        else { // If it isn't Spanish
            return ["""
    \(name)
    \(size)(\(available)Available)
    """,String(1-percent)]
        }

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
    case macOS
}
enum macType {
    case DESKTOP
    case LAPTOP
}
