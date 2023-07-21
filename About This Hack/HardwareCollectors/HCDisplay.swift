//
//  HCDisplay.swift
//  About This Hack
//
//  Created by Felix on 16.07.23.
//

import Foundation

class HCDisplay {
    
    static func getDisp() -> String {
        var tmp = run("cat ~/.ath/scr.txt | grep Resolution | sed 's/.*: //'")
        if tmp.contains("(QHD"){
            tmp = run("cat ~/.ath/scr.txt | grep Resolution | sed 's/.*: //' | cut -c -11")
        }
        if(tmp.contains("\n")) {
            let displayID = tmp.firstIndex(of: "\n")!
            let displayTrimmed = String(tmp[..<displayID])
            tmp = displayTrimmed
        }
        return tmp
    }
    
}
