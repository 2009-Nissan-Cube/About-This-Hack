//
//  ContentView.swift
//  About This Hack
//
//  Created by AvaQueen on 3/08/21.
//

import SwiftUI

struct ContentView: View {
    var systemVersion: String
    var serialNumber: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image("Dark Sur")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.blue)
                .frame(width: 240)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("\(systemVersion)")
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                Text("iHack (5k Retina, 2020)")
                    .font(.system(size: 13))
                    .fontWeight(.bold)
                HStack(spacing: 10) {
                    Text("Processor")
                        .font(.system(size: 13))
                        .fontWeight(.bold)
                    Text("6.9 GHz Intel 10-core i9")
                        .font(.system(size: 13))
                }
                HStack {
                    Text("Memory")
                        .font(.system(size: 13))
                        .fontWeight(.bold)
                    Text("32gb 6900mhz DDR4 RAM")
                        .font(.system(size: 13))
                }
                HStack {
                    Text("Graphics")
                        .font(.system(size: 13))
                        .fontWeight(.bold)
                    Text("Radeon RX 6900 XT (I wish)")
                        .font(.system(size: 13))
                }
                HStack {
                    Text("Monitor")
                        .font(.system(size: 13))
                        .fontWeight(.bold)
                    Text("Some monitor ¯|_(ツ)_|¯")
                        .font(.system(size: 13))
                }
                HStack {
                    Text("Serial Number")
                        .font(.system(size: 13))
                        .fontWeight(.bold)
                    Text(serialNumber)
                        .font(.system(size: 13))
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
        serialNumber = (try? call("system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'")) ?? "Something's outta wack"
        print("Serial Number: \(serialNumber)")
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
