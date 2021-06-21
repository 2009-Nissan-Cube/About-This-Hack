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
        modelID = (try? (try? call("'/Applications/About This Hack.app/Contents/Resources/modelID.sh'")) ?? call("sysctl -n hw.model")) ?? "Mac"
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
        let ramSpeedTrim3 = String(ramSpeedTrim2[ramSpeedID2...])
        ram = "\(ram)\(ramSpeedTrim3)"
        
        // "system_profiler SPMemoryDataType | grep Type: | cut -c 16-"
        
        let ramType = (try? call("system_profiler SPMemoryDataType | grep Type: | cut -c 16-")) ?? "RAM Error"
        let ramTypeID = ramType.firstIndex(of: "\n")!
        let ramTypeTrim = String(ramType[ramTypeID...])
        let ramTypeID1 = ramTypeTrim.firstIndex(of: " ")!
        let ramTypeTrim1 = String(ramTypeTrim[ramTypeID1...])
        ram = "\(ram)\(ramTypeTrim1)"
        
        
        cpu = (try? call("sysctl -n machdep.cpu.brand_string")) ?? "Whoopsie"
        
        
        graphics = (try? call("system_profiler SPDisplaysDataType | awk -F': ' '/^\\ *Chipset Model:/ {printf $2 \" \"}'")) ?? "Unknown GPU"
        
        
        display = (try? call("system_profiler SPDisplaysDataType | grep Resolution | cut -c 23-")) ?? "Unknown Display"
        if display.contains("(QHD"){
            display = (try? call("system_profiler SPDisplaysDataType | grep Resolution | cut -c 23- | cut -c -11")) ?? "Unknown Display"
        }
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
        else {
            if(qDarkMode == true) {
                ImageName = "Dark Sur"
            }
            else {
                ImageName = "Light Sur"
            }
        }
        print(ImageName)
        
        
        // now startup disk
        
        // command: DISK=$(bless --getBoot) | diskutil info $DISK | grep Volume\ Name: | cut -c 31-
        startupDisk = (try? call("DISK=$(bless --getBoot); diskutil info $DISK | grep \"Volume Name:\" | cut -c 31-")) ?? "Macintosh HD"
        print(startupDisk)
        
        
    }
    
    var body: some View {
        HStack(spacing: 15) {
            Image(ImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.blue)
                .frame(width: 220)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("\(systemVersion)")
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                Text(modelID)
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
        .frame(minWidth: 580, maxWidth: 580, minHeight: 350, maxHeight: 350)
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
