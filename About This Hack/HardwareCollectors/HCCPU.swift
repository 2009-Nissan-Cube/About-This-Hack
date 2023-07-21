//
//  HCCPU.swift
//  About This Hack
//
//  Created by Felix on 15.07.23.
//

import Cocoa

class HCCPU {
    
    static func getCPU() -> String {
        return run("sysctl -n machdep.cpu.brand_string")
    }
}
