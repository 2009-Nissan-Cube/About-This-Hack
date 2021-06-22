//
//  ContentView.swift
//  About This Hack
//
//  Created by AvaQueen on 3/08/21.
//

import SwiftUI

struct ContentView: View {
    var systemVersion: String
    var modelID: String
    var serialNumber: String
    var ram: String
    var cpu: String
    var graphics: String
    var display: String
    var startupDisk: String
    var opencore1: String
    var opencore2: String
    var opencore3: String
    var OSver: Double
    var ImageName: String
    var qDarkMode: DarwinBoolean
    
    init() {
        systemVersion = (try? call("system_profiler SPSoftwareDataType | grep 'System Version' | cut -c 23-")) ?? "System Version Not Recognized"
        OSver = Double((try? call("sw_vers | grep ProductVersion | cut -c 17-")) ?? "11.0") ?? 11.0
        //modelID = (try? (try? call("'/Applications/About This Hack.app/Contents/Resources/modelID.sh'")) ?? call("sysctl -n hw.model")) ?? "Mac"
        serialNumber = (try? call("system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'")) ?? "Serial # not found"
        print("Serial Number: \(serialNumber)")
        

        ram = (try? call("echo \"$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))\"")) ?? "RAM Error"
        print("\(ram) GB")
        ram = "\(ram) GB"
        let ramSpeedTmp = (try? call("system_profiler SPMemoryDataType | grep Speed:")) ?? "RAM Error"
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
        ram = "\(ram)\(ramSpeedTrim3)"
        
        let ramType = (try? call("system_profiler SPMemoryDataType | grep Type: | cut -c 16-")) ?? "RAM Error"
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
        ram = "\(ram)\(ramTypeOfficial)"
        
        
        cpu = (try? call("sysctl -n machdep.cpu.brand_string")) ?? "Whoopsie"
        
        
        graphics = (try? call("system_profiler SPDisplaysDataType | awk -F': ' '/^\\ *Chipset Model:/ {printf $2 \" \"}'")) ?? "Unknown GPU"
        // system_profiler SPDisplaysDataType | grep VRAM | cut -c 28-
        let graphicsRAM  = (try? call("system_profiler SPDisplaysDataType | grep VRAM | sed 's/.*: //'")) ?? "Unknown GPU RAM"
        graphics = "\(graphics)\(graphicsRAM)"
        
        display = (try? call("system_profiler SPDisplaysDataType | grep Resolution | sed 's/.*: //'")) ?? "Unknown Display"
        if display.contains("(QHD"){
            display = (try? call("system_profiler SPDisplaysDataType | grep Resolution | sed 's/.*: //' | cut -c -11")) ?? "Unknown Display"
        }
        if(display.contains("\n")) {
            let displayID = display.firstIndex(of: "\n")!
            let displayTrimmed = String(display[..<displayID])
            display = displayTrimmed
        }
        //ram = "\(ram)\(ramTypeOfficial)"
        
        // thanks AstroKid for helping out with making "display" work with macOS 12 Monterey
        opencore1 = (try? call("nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | cut -c 59- | cut -c -1")) ?? "X"
        opencore2 = (try? call("nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | cut -c 60- | cut -c -1")) ?? "X"
        opencore3 = (try? call("nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | cut -c 61- | cut -c -1")) ?? "X"
        print("\(opencore1).\(opencore2).\(opencore3)")
        
        // ASTRO KID MODIFIED HERE: allow images to be OS dependent
        qDarkMode = true
        let darkModeStr = (try? call("/usr/bin/defaults read -g AppleInterfaceStyle")) ?? "Light"
        if(darkModeStr != "Dark") {
            qDarkMode = false
        }
        if(OSver >= 12.0) {
            if(qDarkMode == true) {
                ImageName = "Dark Monterey"
            }
            else {
                ImageName = "Light Monterey"
            }
        }
        else if(OSver >= 11.0) {
            if(qDarkMode == true) {
                ImageName = "Dark Sur"
            }
            else {
                ImageName = "Light Sur"
            }
        }
        else {
            ImageName = "Unknown" // default macOS icon
        }
        print(ImageName)
        
        
        // now startup disk
        
        // command: DISK=$(bless --getBoot) | diskutil info $DISK | grep Volume\ Name: | cut -c 31-
        startupDisk = (try? call("DISK=$(bless --getBoot); diskutil info $DISK | grep \"Volume Name:\" | cut -c 31-")) ?? "Macintosh HD"
        print(startupDisk)
        modelID = (try? call("sysctl hw.model | cut -f2 -d \" \"")) ?? "Mac"
        //curl -s 'https://support-sp.apple.com/sp/product?cc='$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}' | cut -c 9-)  | sed 's|.*<configCode>\(.*\)</configCode>.*|\1|'

        print("MAC: \(getMacName(infoString: modelID))")
        
    }

    var body: some View {
        HStack(spacing: 15) {
            Image(ImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.blue)
                .frame(width: 210)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("\(getOSName())")//": \(systemVersion)")
                    .font(.system(size: 22))
                    .fontWeight(.bold)
                //Text("\(getMacNameSmart()) (\(modelID))")
                Text("\(getMacName(infoString: modelID)) (\(modelID))")
                    .font(.system(size: 11))
                    .fontWeight(.bold)
                HStack(spacing: 11) {
                    Text("Processor")
                        .font(.system(size: 11))
                        .fontWeight(.bold)
                    Text(cpu)
                        .font(.system(size: 11))
                }
                HStack {
                    Text("Memory")
                        .font(.system(size: 11))
                        .fontWeight(.bold)
                    Text(ram)
                        .font(.system(size: 11))
                }
                HStack {
                    Text("Graphics")
                        .font(.system(size: 11))
                        .fontWeight(.bold)
                    Text(graphics)
                        .font(.system(size: 11))
                }
                HStack {
                    Text("Display")
                        .font(.system(size: 11))
                        .fontWeight(.bold)
                    Text(display)
                        .font(.system(size: 11))
                }
                HStack {
                    Text("Startup Disk")
                        .font(.system(size: 11))
                        .fontWeight(.bold)
                    Text(startupDisk)
                        .font(.system(size: 11))
                }
                HStack {
                    Text("Serial Number")
                        .font(.system(size: 11))
                        .fontWeight(.bold)
                    Text(serialNumber)
                        .font(.system(size: 11))
                }
                HStack {
                    if opencore1 == "0" {
                        Text("OpenCore Version")
                            .font(.system(size: 11))
                            .fontWeight(.bold)
                        Text("\(opencore1).\(opencore2).\(opencore3)")
                            .font(.system(size: 11))
                    }
                }
            }
            .font(.callout)
            .padding(.top)
        }
        .navigationTitle("About This Hack")
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willUpdateNotification), perform: { _ in
            hideZoomButton()
        })
        
      // conflict resolved
        .frame(minWidth: 580, maxWidth: 580, minHeight: 320, maxHeight: 320)
    }
    func getOSName() -> String {
        let infoString = (try? call("sw_vers | grep ProductVersion | cut -c 17-")) ?? "Unknown"
        let OSnumber = Double(infoString)
        if(OSnumber ?? 11.0 >= 12.0) {
            return "macOS Monterey (\(OSnumber ?? 12.0))"
        }
        else if(OSnumber ?? 11.0 >= 11.0) {
            return "macOS Big Sur (\(OSnumber ?? 11.0))"
        }
        else if (OSnumber ?? 11.0 >= 10.0) {
            let infoString1 = (try? call("sw_vers -productVersion | awk -F '.' '{print  $2}'")) ?? "15"
            switch(infoString1) {
            case "16":
                return "macOS Flying Squirrel (\(OSnumber ?? 10.16))"
            case "15":
                return "macOS Catalina (\(OSnumber ?? 10.15))"
            case "14":
                return "macOS Mojave (\(OSnumber ?? 10.14))"
            case "13":
                return "macOS High Sierra (\(OSnumber ?? 10.13))"
            case "12":
                return "macOS Sierra (\(OSnumber ?? 10.12))"
            case "11":
                return "OS X El Capitan (\(OSnumber ?? 10.11))"
            case "10":
                return "OS X Yosemite (\(OSnumber ?? 10.10))"
            case "9":
                return "OS X Mavericks (\(OSnumber ?? 10.9))"
            case "8":
                return "OS X Mountain Lion (\(OSnumber ?? 10.8))"
            case "7":
                return "Mac OS X Lion (\(OSnumber ?? 10.7))"
            case "6":
                return "Mac OS X Snow Leopard (\(OSnumber ?? 10.6))"
            case "5":
                return "Mac OS X Leopard (\(OSnumber ?? 10.5))"
            case "4":
                return "Mac OS X Tiger (\(OSnumber ?? 10.4))"
            case "3":
                return "Mac OS X Panther (\(OSnumber ?? 10.3))"
            case "2":
                return "Mac OS X Jaguar (\(OSnumber ?? 10.2))"
            case "1":
                return "Mac OS X Puma (\(OSnumber ?? 10.1))"
            case "0":
                return "Mac OS X Cheetah (\(OSnumber ?? 10.0))"
            default:
                return "macOS Catalina (10.15.6)"
            }
            
        }
        else {
            return "macOS Flying Squirrel (\(OSnumber ?? 10.16))"
        }
    }
    
    func hideZoomButton() {
            for window in NSApplication.shared.windows {
                window.standardWindowButton(NSWindow.ButtonType.zoomButton)!.isHidden = true
            }
        }
    }
    
    func getMacNameSmart() -> String {
        return (try? call("defaults read ~/Library/Preferences/com.apple.SystemProfiler.plist \"CPU Names\" | cut -f 2 -d = | sed 's/..$//' | tail -n 2 | head -n 1 | sed 's/$//' | cut -c 3-")) ?? "Mac"
    }
    func getMacName(infoString: String) -> String {
        // from https://everymac.com/systems/by_capability/mac-specs-by-machine-model-machine-id.html
        
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
        case "Unkown":
            return "Hackintosh Extreme Plus" // hehe just for fun
        default:
            return "Mac"
        }
    }

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        }
    }

