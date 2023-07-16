//
//  HCStartupDisk.swift
//  About This Hack
//
//  Created by Felix on 16.07.23.
//

import Cocoa

class HCStartupDisk {
    static func getStartupDisk() -> String {
        return run("cat ~/.ath/sysvolname.txt | grep 'Volume Name' | sed 's/.*:[[:space:]]*//' | tr -d '\n'")
    }
}
