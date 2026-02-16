//
//  SystemFunctions.swift
//

import Cocoa
import AppKit
import Darwin

var thisApplicationVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String

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

extension Bundle {
    /// Application name shown under the application icon.
    var applicationName: String? {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
            object(forInfoDictionaryKey: "CFBundleName") as? String ??
                object(forInfoDictionaryKey: "CFBundleExecutable") as? String
    }
}
