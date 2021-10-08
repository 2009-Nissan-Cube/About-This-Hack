//
//  Shell.swift
//  About This Hack
//
//  Created by 8itCat on 10/8/21.
//

import Foundation

// Allows native runnning of Terminal commands
func run(_ cmd: String) -> String {
    let pipe = Pipe()
    let process = Process()
    process.launchPath = "/bin/sh"
    process.arguments = ["-c", String(format:"%@", cmd)]
    process.standardOutput = pipe
    let fileHandle = pipe.fileHandleForReading
    process.launch()
    return String(data: fileHandle.readDataToEndOfFile(), encoding: .utf8) ?? "Oops"
}
