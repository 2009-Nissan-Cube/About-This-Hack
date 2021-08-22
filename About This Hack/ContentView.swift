//
//  ContentView.swift
//  About This Hack
//
//  Created by AvaQueen on 3/08/21.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    var systemVersion: String
    var macModel: String
    var modelID: String
    var serialNumber: String
    var ram: String
    var cpu: String
    var graphics: String
    var display: String
    var startupDisk: String
    var lightImageName: String
    var darkImageName: String
    var ocLevel: String
    var ocVersion: String
    
    init() {
//        systemVersion = (try? call("system_profiler SPSoftwareDataType | grep 'System Version' | cut -c 23-")) ?? "System Version Not Recognized"
        systemVersion = (try? call("sw_vers | grep ProductVersion | cut -c 17-")) ?? "11.0"
        //modelID = (try? (try? call("'/Applications/About This Hack.app/Contents/Resources/modelID.sh'")) ?? call("sysctl -n hw.model")) ?? "Mac"
        let hardwareCache = (try? call("system_profiler SPHardwareDataType")) ?? "Some data idk lol"
        serialNumber = (try? call("echo \"\(hardwareCache)\" | awk '/Serial/ {print $4}'")) ?? "Serial # not found"
        print("Serial Number: \(serialNumber)")
        
        macModel = (try? call("""
 /usr/libexec/PlistBuddy -c "print :'CPU Names':$(echo \"\(hardwareCache)\" | awk '/Serial/ {print $4}' | cut -c 9-)-en-US_US" ~/Library/Preferences/com.apple.SystemProfiler.plist
 """)) ?? "Unknown Model"

        ram = (try? call("echo \"$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))\"")) ?? "RAM Error"
        print("\(ram) GB")
        ram = "\(ram) GB"
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
        ram = "\(ram)\(ramSpeedTrim3)"
        
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
        ram = "\(ram)\(ramTypeOfficial)"
        
        
        cpu = (try? call("sysctl -n machdep.cpu.brand_string")) ?? "Whoopsie"
        
        let displaysCache = (try? call("system_profiler SPDisplaysDataType")) ?? "Unknown GPU"
        graphics = (try? call("echo \"\(displaysCache)\" | awk -F': ' '/^\\ *Chipset Model:/ {printf $2 \" \"}'")) ?? "Unknown GPU"
        // system_profiler SPDisplaysDataType | grep VRAM | cut -c 28-
        let graphicsRAM  = (try? call("echo \"\(displaysCache)\" | grep VRAM | sed 's/.*: //'")) ?? "Unknown GPU RAM"
        graphics = "\(graphics)\(graphicsRAM)"
        
        display = (try? call("echo \"\(displaysCache)\" | grep Resolution | sed 's/.*: //'")) ?? "Unknown Display"
        if display.contains("(QHD"){
            display = (try? call("echo \"\(displaysCache)\" | grep Resolution | sed 's/.*: //' | cut -c -11")) ?? "Unknown Display"
        }
        if(display.contains("\n")) {
            let displayID = display.firstIndex(of: "\n")!
            let displayTrimmed = String(display[..<displayID])
            display = displayTrimmed
        }
        // ram = "\(ram)\(ramTypeOfficial)"
        ocLevel   = "Unknown"
        ocVersion = "Version"
        let ocString = (try? call("nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version")) ?? "X"
        let testString = ocString.replacingOccurrences(of: "4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version", with: "").trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "-")
        if(ocString != "X") {
            ocLevel = String(testString[1]).inserting(separator: ".", every: 1)
            ocVersion = (testString[0] == "REL" ? "(Release)" : "(Debug)")
        }
        
        // thanks AstroKid for helping out with making "display" work with macOS 12 Monterey
        
        if(systemVersion.hasPrefix("12")) {
            lightImageName = "Light Monterey"
            darkImageName = "Dark Monterey"
        }
        else if(systemVersion.hasPrefix("11")) {
            lightImageName = "Light Sur"
            darkImageName = "Dark Sur"
        }
        else {
            lightImageName = "Unknown" // default macOS icon
            darkImageName = "Unknown"
        }
        print("Light Image: \(lightImageName)\nDark Image:\(darkImageName)")
        
        
        // Startup Disk
        startupDisk = (try? call("system_profiler SPSoftwareDataType | grep 'Boot Volume' | sed 's/.*: //'")) ?? "Macintosh HD"
        print(startupDisk)
        modelID = (try? call("sysctl hw.model | cut -f2 -d \" \"")) ?? "Mac"
        // curl -s 'https://support-sp.apple.com/sp/product?cc='$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}' | cut -c 9-)  | sed 's|.*<configCode>\(.*\)</configCode>.*|\1|'
        
        print("MAC: \(macModel)")
        
    }

    var body: some View {
        HStack(spacing: 15) {
            Image(colorScheme == .dark ? darkImageName : lightImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.blue)
                .frame(width: 210)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("\(getOSName())")//": \(systemVersion)")
                    .font(.system(size: 22))
                    .fontWeight(.bold)
                //Text("\(getMacNameSmart()) (\(modelID))")
                Text("\(macModel) (\(modelID))")
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
                if ocLevel != "Unknown" {
                    HStack {
                        Text("OpenCore Version")
                            .font(.system(size: 11))
                            .fontWeight(.bold)
                        Text("\(ocLevel) \(ocVersion)")
                            .font(.system(size: 11))
                    }
                }
            }
            .font(.callout)
        }
        .navigationTitle("About This Hack")
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.willUpdateNotification), perform: { _ in
            hideZoomButton()
        })
        
      // conflict resolved
        .frame(minWidth: 580, maxWidth: 580, minHeight: 320, maxHeight: 320)
    }
    func getOSName() -> String {
        _ = systemVersion
        if(systemVersion.hasPrefix("12")) {
            return "macOS Monterey (\(systemVersion))"
        }
        else if(systemVersion.hasPrefix("11")) {
            return "macOS Big Sur (\(systemVersion))"
        }
        else if (systemVersion.hasPrefix("10")) {
            let infoString1 = (try? call("sw_vers -productVersion | awk -F '.' '{print  $2}'")) ?? "15"
            switch(infoString1) {
            case "16":
                return "macOS Flying Squirrel (\(systemVersion))"
            case "15":
                return "macOS Catalina (\(systemVersion))"
            case "14":
                return "macOS Mojave (\(systemVersion))"
            case "13":
                return "macOS High Sierra (\(systemVersion))"
            case "12":
                return "macOS Sierra (\(systemVersion))"
            case "11":
                return "OS X El Capitan (\(systemVersion))"
            case "10":
                return "OS X Yosemite (\(systemVersion))"
            case "9":
                return "OS X Mavericks (\(systemVersion))"
            case "8":
                return "OS X Mountain Lion (\(systemVersion))"
            case "7":
                return "Mac OS X Lion (\(systemVersion))"
            case "6":
                return "Mac OS X Snow Leopard (\(systemVersion))"
            case "5":
                return "Mac OS X Leopard (\(systemVersion))"
            case "4":
                return "Mac OS X Tiger (\(systemVersion))"
            case "3":
                return "Mac OS X Panther (\(systemVersion))"
            case "2":
                return "Mac OS X Jaguar (\(systemVersion))"
            case "1":
                return "Mac OS X Puma (\(systemVersion))"
            case "0":
                return "Mac OS X Cheetah (\(systemVersion))"
            default:
                return "macOS"
            }
            
        }
        else {
            return "macOS Flying Squirrel (\(systemVersion))"
        }
    }
    
    func hideZoomButton() {
            for window in NSApplication.shared.windows {
                window.standardWindowButton(NSWindow.ButtonType.zoomButton)!.isHidden = true
            }
        }
    }

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        }
    }

