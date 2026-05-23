//
//  SystemFunctions.swift
//

import Cocoa
import AppKit
import Darwin

let thisApplicationVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"

// IOReg port default
var IOMainorMasterPortDefault: UInt32 = 0

// Define RTLD_DEFAULT for symbol lookup
let RTLD_DEFAULT = UnsafeMutableRawPointer(bitPattern: -2)

func initPortDefault() -> mach_port_t {
    if #available(macOS 12.0, *) {
        guard let sym = dlsym(RTLD_DEFAULT, "kIOMainPortDefault") else {
            return kIOMasterPortDefault
        }
        let ptr = sym.assumingMemoryBound(to: mach_port_t.self)
        return ptr.pointee
    } else {
        return kIOMasterPortDefault
    }
}

func getSysctlValueByKey(inputKey sysctlKey: String) -> String? {
    var oNbrBytes: Int = 0
    sysctlbyname(sysctlKey, nil, &oNbrBytes, nil, 0)
    var sysctlValue = [CChar](repeating: 0, count: Int(oNbrBytes))
    sysctlbyname(sysctlKey, &sysctlValue, &oNbrBytes, nil, 0)
    return String(validatingUTF8: sysctlValue) ?? "unknown"
}

func numericVersionComponents(from version: String) -> [Int] {
    version
        .split(whereSeparator: { !$0.isNumber })
        .compactMap { Int($0) }
}

func compareVersionStrings(_ lhs: String, _ rhs: String) -> ComparisonResult {
    let lhsComponents = numericVersionComponents(from: lhs)
    let rhsComponents = numericVersionComponents(from: rhs)
    let maxCount = max(lhsComponents.count, rhsComponents.count)

    guard maxCount > 0 else {
        return lhs.compare(rhs, options: [.numeric, .caseInsensitive])
    }

    for index in 0..<maxCount {
        let lhsValue = index < lhsComponents.count ? lhsComponents[index] : 0
        let rhsValue = index < rhsComponents.count ? rhsComponents[index] : 0

        if lhsValue < rhsValue {
            return .orderedAscending
        }

        if lhsValue > rhsValue {
            return .orderedDescending
        }
    }

    return .orderedSame
}

func isVersion(_ lhs: String, atLeast rhs: String) -> Bool {
    compareVersionStrings(lhs, rhs) != .orderedAscending
}

@discardableResult
func openFirstAvailableURL(urlStrings: [String], fallbackFilePaths: [String] = []) -> Bool {
    for urlString in urlStrings {
        guard let url = URL(string: urlString) else {
            continue
        }

        if NSWorkspace.shared.open(url) {
            return true
        }
    }

    for path in fallbackFilePaths where FileManager.default.fileExists(atPath: path) {
        if NSWorkspace.shared.open(URL(fileURLWithPath: path)) {
            return true
        }
    }

    return false
}

extension Bundle {
    /// Application name shown under the application icon.
    var applicationName: String? {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
            object(forInfoDictionaryKey: "CFBundleName") as? String ??
            object(forInfoDictionaryKey: "CFBundleExecutable") as? String
    }
}
