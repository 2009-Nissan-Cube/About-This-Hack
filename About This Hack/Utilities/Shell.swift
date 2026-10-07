//
//  Shell.swift
//  About This Hack
//

import Foundation

struct ProcessResult {
    let stdout: String
    let stderr: String
    let terminationStatus: Int32

    var succeeded: Bool {
        terminationStatus == 0
    }

    var combinedOutput: String {
        [stdout, stderr]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n")
    }
}

@discardableResult
func executeProcess(executableURL: URL, arguments: [String]) -> ProcessResult {
    let task = Process()
    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    task.executableURL = executableURL
    task.arguments = arguments
    task.standardOutput = stdoutPipe
    task.standardError = stderrPipe

    do {
        try task.run()
    } catch {
        return ProcessResult(stdout: "", stderr: error.localizedDescription, terminationStatus: -1)
    }

    // Drain stderr concurrently so a full pipe can never stall the child.
    var stderrData = Data()
    let stderrDone = DispatchSemaphore(value: 0)
    DispatchQueue.global(qos: .utility).async {
        stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        stderrDone.signal()
    }
    let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
    stderrDone.wait()
    task.waitUntilExit()

    return ProcessResult(
        stdout: String(decoding: stdoutData, as: UTF8.self),
        stderr: String(decoding: stderrData, as: UTF8.self),
        terminationStatus: task.terminationStatus
    )
}
