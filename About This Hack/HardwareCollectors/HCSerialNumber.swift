//
//  HCSerialNumber.swift
//  About This Hack
//
//  Created by Felix on 16.07.23.
//

import Foundation

class HCSerialNumber {
    
    static func getSerialNumber() -> String {
        return run("cat ~/.ath/hw.txt | awk '/Serial/ {print $4}'")
    }
}
