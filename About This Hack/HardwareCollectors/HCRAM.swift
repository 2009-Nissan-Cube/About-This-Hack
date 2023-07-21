//
//  HCRAM.swift
//  About This Hack
//
//  Created by Felix on 15.07.23.
//

import Cocoa

class HCRAM {
    
    static func getRam() -> String {
        let ram = run("echo \"$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))\" | tr -d '\n'")
        let ramType = run("cat ~/.ath/sysmem.txt  | grep 'Type' | awk '{print $2}' | sed -n '1p'")
        print("RAM Type: " + ramType)
        let ramSpeed = run("cat ~/.ath/sysmem.txt | grep 'Speed' | grep 'MHz' | awk '{print $2\" \"$3}' | sed -n '1p'").trimmingCharacters(in: .whitespacesAndNewlines)
        let ramReturn = "\(ram) GB \(ramSpeed) \(ramType)"
        return ramReturn
    }
}
