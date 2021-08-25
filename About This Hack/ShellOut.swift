/**
 *  ShellOut
 *  Copyright (c) John Sundell 2017
 *  Slightly modified by Ben Sova
 *  Licensed under the MIT license.
 */

import Foundation
import Dispatch

@discardableResult func call(_ cmd: String, at: String = "~", h handle: @escaping (String) -> () = {_ in}) throws -> String {
    let psHandle = StringHandle(handlingClosure: { (string) in
        print(string.replacingOccurrences(of: "Password:", with: ""))
        handle(string.replacingOccurrences(of: "Password:", with: ""))
    })
    return try shellOut(to: cmd, at: at, outputHandle: psHandle, errorHandle: psHandle)
}

@discardableResult func call(_ cmd: String, p: String, at: String = "~", h handle: @escaping (String) -> () = {_ in}) throws -> String {
    let psHandle = StringHandle(handlingClosure: { (string) in
        print(string.replacingOccurrences(of: "Password:", with: ""))
        handle(string.replacingOccurrences(of: "Password:", with: ""))
    })
    return try shellOut(to: "echo \(p.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "'", with: "\\'")) | sudo -S \(cmd)", at: at, outputHandle: psHandle, errorHandle: psHandle)
}


@discardableResult func exec(_ cmd: String, p: String, at: String = "~", h handle: @escaping (String) -> () = {_ in}) throws -> String {
    let psHandle = StringHandle(handlingClosure: { (string) in
        print(string)
        handle(string)
    })
    return try shellOut(to: "exec echo \(p.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "'", with: "\\'")) | sudo -S \(cmd)", at: at, outputHandle: psHandle, errorHandle: psHandle)
}

// MARK: - API

/**
 *  Run a shell command using Bash
 *
 *  - parameter command: The command to run
 *  - parameter arguments: The arguments to pass to the command
 *  - parameter path: The path to execute the commands at (defaults to current folder)
 *  - parameter outputHandle: Any `Handle` that any output (STDOUT) should be redirected to
 *              (at the moment this is only supported on macOS)
 *  - parameter errorHandle: Any `Handle` that any error output (STDERR) should be redirected to
 *              (at the moment this is only supported on macOS)
 *
 *  - returns: The output of running the command
 *  - throws: `ShellOutError` in case the command couldn't be performed, or it returned an error
 *
 *  Use this function to "shell out" in a Swift script or command line tool
 *  For example: `shellOut(to: "mkdir", arguments: ["NewFolder"], at: "~/CurrentFolder")`
 */
@discardableResult public func shellOut(to command: String,
                                        arguments: [String] = [],
                                        at path: String = "~",
                                        outputHandle: Handle? = nil,
                                        errorHandle: Handle? = nil) throws -> String {
    let process = Process()
    let command = "cd \(path.escapingSpaces) && \(command) \(arguments.joined(separator: " "))"
    return try process.launchBash(with: command, outputHandle: outputHandle, errorHandle: errorHandle)
}

/**
 *  Run a series of shell commands using Bash
 *
 *  - parameter commands: The commands to run
 *  - parameter path: The path to execute the commands at (defaults to current folder)
 *  - parameter outputHandle: Any `Handle` that any output (STDOUT) should be redirected to
 *              (at the moment this is only supported on macOS)
 *  - parameter errorHandle: Any `Handle` that any error output (STDERR) should be redirected to
 *              (at the moment this is only supported on macOS)
 *
 *  - returns: The output of running the command
 *  - throws: `ShellOutError` in case the command couldn't be performed, or it returned an error
 *
 *  Use this function to "shell out" in a Swift script or command line tool
 *  For example: `shellOut(to: ["mkdir NewFolder", "cd NewFolder"], at: "~/CurrentFolder")`
 */
@discardableResult public func shellOut(to commands: [String],
                                        at path: String = "~",
                                        outputHandle: Handle? = nil,
                                        errorHandle: Handle? = nil) throws -> String {
    let command = commands.joined(separator: " && ")
    return try shellOut(to: command, at: path, outputHandle: outputHandle, errorHandle: errorHandle)
}

/**
 *  Run a pre-defined shell command using Bash
 *
 *  - parameter command: The command to run
 *  - parameter path: The path to execute the commands at (defaults to current folder)
 *  - parameter outputHandle: Any `Handle` that any output (STDOUT) should be redirected to
 *  - parameter errorHandle: Any `Handle` that any error output (STDERR) should be redirected to
 *
 *  - returns: The output of running the command
 *  - throws: `ShellOutError` in case the command couldn't be performed, or it returned an error
 *
 *  Use this function to "shell out" in a Swift script or command line tool
 *  For example: `shellOut(to: .gitCommit(message: "Commit"), at: "~/CurrentFolder")`
 *
 *  See `ShellOutCommand` for more info.
 */
@discardableResult public func shellOut(to command: ShellOutCommand,
                                        at path: String = "~",
                                        outputHandle: Handle? = nil,
                                        errorHandle: Handle? = nil) throws -> String {
    return try shellOut(to: command.string, at: path, outputHandle: outputHandle, errorHandle: errorHandle)
}

/// Structure used to pre-define commands for use with ShellOut
public struct ShellOutCommand {
    /// The string that makes up the command that should be run on the command line
    public var string: String

    /// Initialize a value using a string that makes up the underlying command
    public init(string: String) {
        self.string = string
    }
}

/// Error type thrown by the `shellOut()` function, in case the given command failed
public struct ShellOutError: Swift.Error {
    /// The termination status of the command that was run
    public let terminationStatus: Int32
    /// The error message as a UTF8 string, as returned through `STDERR`
    public var message: String { return errorData.shellOutput() }
    /// The raw error buffer data, as returned through `STDERR`
    public let errorData: Data
    /// The raw output buffer data, as retuned through `STDOUT`
    public let outputData: Data
    /// The output of the command as a UTF8 string, as returned through `STDOUT`
    public var output: String { return outputData.shellOutput() }
}

extension ShellOutError: CustomStringConvertible {
    public var description: String {
        return """
               Error 1x\(terminationStatus)
               Message: "\(message.replacingOccurrences(of: "Password:", with: ""))"
               Output: "\(output.replacingOccurrences(of: "Password:", with: ""))"
               """
    }
}

extension ShellOutError: LocalizedError {
    public var errorDescription: String? {
        return description
    }
}

/// Protocol adopted by objects that handles command output
public protocol Handle {
    /// Method called each time command provide new output data
    func handle(data: Data)

    /// Optional method called when command has finished to close the handle
    func endHandling()
}

public extension Handle {
    func endHandling() {}
}

extension FileHandle: Handle {
    public func handle(data: Data) {
        write(data)
    }
    
    public func endHandling() {
        closeFile()
    }
}

/// Handle to get async output from the command. The `handlingClosure` will be called each time new output string appear.
public struct StringHandle: Handle {
    private let handlingClosure: (String) -> Void

    /// Default initializer
    ///
    /// - Parameter handlingClosure: closure called each time new output string is provided
    public init(handlingClosure: @escaping (String) -> Void) {
        self.handlingClosure = handlingClosure
    }
    
    public func handle(data: Data) {
        guard !data.isEmpty else { return }
        let output = data.shellOutput()
        guard !output.isEmpty else { return }
        handlingClosure(output)
    }
}

// MARK: - Private

private extension Process {
    @discardableResult func launchBash(with command: String, outputHandle: Handle? = nil, errorHandle: Handle? = nil) throws -> String {
        launchPath = "/bin/bash"
        arguments = ["-c", command]

        // Because FileHandle's readabilityHandler might be called from a
        // different queue from the calling queue, avoid a data race by
        // protecting reads and writes to outputData and errorData on
        // a single dispatch queue.
        let outputQueue = DispatchQueue(label: "bash-output-queue")

        var outputData = Data()
        var errorData = Data()

        let outputPipe = Pipe()
        standardOutput = outputPipe

        let errorPipe = Pipe()
        standardError = errorPipe

        #if !os(Linux)
        outputPipe.fileHandleForReading.readabilityHandler = { handler in
            let data = handler.availableData
            outputQueue.async {
                outputData.append(data)
                outputHandle?.handle(data: data)
            }
        }

        errorPipe.fileHandleForReading.readabilityHandler = { handler in
            let data = handler.availableData
            outputQueue.async {
                errorData.append(data)
                errorHandle?.handle(data: data)
            }
        }
        #endif

        launch()

        #if os(Linux)
        outputQueue.sync {
            outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        }
        #endif

        waitUntilExit()

        outputHandle?.endHandling()
        errorHandle?.endHandling()

        #if !os(Linux)
        outputPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil
        #endif

        // Block until all writes have occurred to outputData and errorData,
        // and then read the data back out.
        return try outputQueue.sync {
            if terminationStatus != 0 {
                throw ShellOutError(
                    terminationStatus: terminationStatus,
                    errorData: errorData,
                    outputData: outputData
                )
            }

            return outputData.shellOutput()
        }
    }
}

private extension Data {
    func shellOutput() -> String {
        guard let output = String(data: self, encoding: .utf8) else {
            return ""
        }

        guard !output.hasSuffix("\n") else {
            let endIndex = output.index(before: output.endIndex)
            return String(output[..<endIndex])
        }

        return output

    }
}

private extension String {
    var escapingSpaces: String {
        return replacingOccurrences(of: " ", with: "\\ ")
    }

    func appending(argument: String) -> String {
        return "\(self) \"\(argument)\""
    }

    func appending(arguments: [String]) -> String {
        return appending(argument: arguments.joined(separator: "\" \""))
    }

    mutating func append(argument: String) {
        self = appending(argument: argument)
    }

    mutating func append(arguments: [String]) {
        self = appending(arguments: arguments)
    }
}
