//
//  HCGPU.swift
//  About This Hack
//
//  Created by Felix on 16.07.23.
//

import Foundation

class HCGPU {
    
    
    static func getGPU() -> String {
        var graphicsTmp = run("cat ~/.ath/scr.txt | grep 'Chipset' | sed 's/.*: //'")
        if graphicsTmp.contains("Intel") || graphicsTmp.contains("NVIDIA") {
            graphicsTmp = graphicsTmp.replacingOccurrences(of: "Intel ", with: "")
            graphicsTmp = graphicsTmp.replacingOccurrences(of: "NVIDIA ", with: "")
        }
        let graphicsRAM  = run("cat ~/.ath/scr.txt | grep VRAM | sed 's/.*: //'")
        let graphicsArray = graphicsTmp.components(separatedBy: "\n").filter({ $0 != ""})
        print(graphicsArray)
        print(graphicsArray.count)
        let vramArray = graphicsRAM.components(separatedBy: "\n")
        var gpuInfoFormatted = ""
        if graphicsArray.count == 1 {
            gpuInfoFormatted = "\(graphicsArray[0]) \(vramArray[0])"
        } else {
            for index in 0..<graphicsArray.count {
                gpuInfoFormatted += "\(graphicsArray[index]) \(vramArray[index])"
                if index <= graphicsArray.count - 3 {
                    gpuInfoFormatted += " + "
                }
            }
        }

//        while x < min(vramArray.count, graphicsArray.count) {
//            gpuInfoFormatted.append("\(graphicsArray[x]) \(vramArray[x])\n")
//            x += 1
//        }
        return gpuInfoFormatted
    }
    
    
}
