//
//  Shell.swift
//  About This Hack
//
//

import Foundation

struct ProcessResult {
    let executableURL: URL
    let arguments: [String]
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
    let readGroup = DispatchGroup()
    let readQueue = DispatchQueue(label: "AboutThisHack.ProcessRead", qos: .utility, attributes: .concurrent)

    task.executableURL = executableURL
    task.arguments = arguments
    task.standardOutput = stdoutPipe
    task.standardError = stderrPipe

    var stdoutData = Data()
    var stderrData = Data()

    readGroup.enter()
    readQueue.async {
        stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        readGroup.leave()
    }

    readGroup.enter()
    readQueue.async {
        stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        readGroup.leave()
    }

    do {
        try task.run()
        task.waitUntilExit()
        readGroup.wait()
    } catch {
        return ProcessResult(
            executableURL: executableURL,
            arguments: arguments,
            stdout: "",
            stderr: error.localizedDescription,
            terminationStatus: -1
        )
    }

    return ProcessResult(
        executableURL: executableURL,
        arguments: arguments,
        stdout: String(data: stdoutData, encoding: .utf8) ?? "",
        stderr: String(data: stderrData, encoding: .utf8) ?? "",
        terminationStatus: task.terminationStatus
    )
}
