//
//  HCGPU.swift
//  About This Hack
//
//  Created by Felix on 16.07.23.
//

import Foundation

class HCGPU {
    
    
    static func getGPU() -> String {
        let graphicsTmp = run("cat ~/.ath/scr.txt | grep 'Chipset' | sed 's/.*: //'")
        let graphicsRAM  = run("cat ~/.ath/scr.txt | grep VRAM | sed 's/.*: //'")
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
    
    
}
