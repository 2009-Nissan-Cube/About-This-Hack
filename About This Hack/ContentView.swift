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
    var opencore1: String
    var opencore2: String
    var opencore3: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image("Dark Sur")
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
                    Text("\(ram) GB")
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
    init() {
        systemVersion = (try? call("system_profiler SPSoftwareDataType | grep 'System Version' | cut -c 23-")) ?? "System Version Not Recognized"
        modelID = (try? (try? call("'/Applications/About This Hack.app/Contents/Resources/modelID.sh'")) ?? call("sysctl -n hw.model")) ?? "Mac"
        serialNumber = (try? call("system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'")) ?? "Something's outta wack"
        print("Serial Number: \(serialNumber)")
        ram = (try? call("echo \"$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))\"")) ?? "Whoopsie"
        print("\(ram) GB")
        cpu = (try? call("sysctl -n machdep.cpu.brand_string")) ?? "Whoopsie"
        graphics = (try? call("system_profiler SPDisplaysDataType | awk -F': ' '/^\\ *Chipset Model:/ {printf $2 \" \"}'")) ?? "Unknown GPU"
        display = (try? call("system_profiler SPDisplaysDataType | grep UI | cut -c 26-")) ?? "Unknown Display"
        opencore1 = (try? call("nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | cut -c 59- | cut -c -1")) ?? "X"
        opencore2 = (try? call("nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | cut -c 60- | cut -c -1")) ?? "X"
        opencore3 = (try? call("nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | cut -c 61- | cut -c -1")) ?? "X"
        print("\(opencore1).\(opencore2).\(opencore3)")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
