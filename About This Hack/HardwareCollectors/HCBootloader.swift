import Foundation
import IOKit

class HCBootloader {
    static let shared = HCBootloader()
    private init() {}
    
    private let cacheLock = NSLock()
    private var bootloaderInfoCache: String?
    private var bootargsInfoCache: String?

    func getBootloader() -> String {
        cachedBootloaderInfo()
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
    
    func getBootargs() -> String {
        cachedBootargsInfo()
    }

    private func cachedBootloaderInfo() -> String {
        cacheLock.lock()
        if let bootloaderInfoCache {
            cacheLock.unlock()
            return bootloaderInfoCache
        }
        cacheLock.unlock()

        let detected = detectBootloaderInfo()

        cacheLock.lock()
        bootloaderInfoCache = detected
        cacheLock.unlock()

        return detected
    }

    private func cachedBootargsInfo() -> String {
        cacheLock.lock()
        if let bootargsInfoCache {
            cacheLock.unlock()
            return bootargsInfoCache
        }
        cacheLock.unlock()

        let detected = detectBootargsInfo()

        cacheLock.lock()
        bootargsInfoCache = detected
        cacheLock.unlock()

        return detected
    }

    private func detectBootloaderInfo() -> String {
        if (getSysctlValueByKey(inputKey: "machdep.cpu.brand_string") ?? "").contains("Apple") {
            return "Apple iBoot"
        }

        if let nvramVersion = readNVRAMValue(named: InitGlobVar.nvramOpencoreVersion),
           let parsedVersion = parseOpenCoreVersion(nvramVersion) {
            return parsedVersion
        }

        if let fallbackVersion = parseCLIValue(
            executeProcess(executableURL: URL(fileURLWithPath: "/usr/sbin/nvram"), arguments: [InitGlobVar.nvramOpencoreVersion]).stdout
        ), let parsedVersion = parseOpenCoreVersion(fallbackVersion) {
            return parsedVersion
        }

        if let hwContent = HardwareCollector.shared.hardwareData {
            let cloverLine = hwContent.components(separatedBy: .newlines)
                .first { $0.contains("Clover") }

            if let line = cloverLine,
               let colonIndex = line.firstIndex(of: ":") {
                let version = String(line[line.index(after: colonIndex)...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !version.isEmpty {
                    return "Clover \(version)"
                }
            }
        }

        return "Apple UEFI"
    }

    private func detectBootargsInfo() -> String {
        if let bootArgs = readNVRAMValue(named: "boot-args"), !bootArgs.isEmpty {
            return bootArgs
        }

        if let bootArgs = parseCLIValue(
            executeProcess(executableURL: URL(fileURLWithPath: "/usr/sbin/nvram"), arguments: ["boot-args"]).stdout
        ), !bootArgs.isEmpty {
            return bootArgs
        }

        let bdmesgOutput = executeProcess(executableURL: URL(fileURLWithPath: InitGlobVar.bdmesgExecID), arguments: []).stdout
        let fallbackBootArgs = bdmesgOutput
            .components(separatedBy: .newlines)
            .last { $0.contains(" boot-args=") }?
            .components(separatedBy: " boot-args=")
            .last?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return fallbackBootArgs?.isEmpty == false ? fallbackBootArgs! : "Empty/Unknown"
    }

    private func readNVRAMValue(named propertyName: String) -> String? {
        let options = IORegistryEntryFromPath(kIOMainPortDefault, "IODeviceTree:/options")
        guard options != MACH_PORT_NULL else {
            return nil
        }
        defer { IOObjectRelease(options) }

        guard let value = IORegistryEntryCreateCFProperty(options, propertyName as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() else {
            return nil
        }

        return normalizeNVRAMValue(value)
    }

    private func normalizeNVRAMValue(_ value: CFTypeRef) -> String? {
        if let stringValue = value as? String {
            return sanitizeNVRAMString(stringValue)
        }

        if let dataValue = value as? Data,
           let stringValue = String(data: dataValue, encoding: .utf8) {
            return sanitizeNVRAMString(stringValue)
        }

        if let numberValue = value as? NSNumber {
            return numberValue.stringValue
        }

        return nil
    }

    private func sanitizeNVRAMString(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\0", with: "")
            .trimmingCharacters(in: CharacterSet.controlCharacters.union(.whitespacesAndNewlines))
    }

    private func parseCLIValue(_ output: String) -> String? {
        let cleanedOutput = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedOutput.isEmpty else {
            return nil
        }

        let parts = cleanedOutput.components(separatedBy: "\t")
        if parts.count >= 2 {
            return parts.dropFirst().joined(separator: "\t").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return cleanedOutput
    }

    private func parseOpenCoreVersion(_ rawValue: String) -> String? {
        let cleanedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedValue.isEmpty else {
            return nil
        }

        let components = cleanedValue.split(separator: "-", maxSplits: 1)
        guard components.count >= 2 else {
            return nil
        }

        let buildType = String(components[0])
        let version = String(components[1])
            .replacingOccurrences(of: " ", with: ".")
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))

        let formattedBuildType: String
        switch buildType {
        case "REL": formattedBuildType = "(Release)"
        case "DEB": formattedBuildType = "(Debug)"
        default: formattedBuildType = buildType.isEmpty ? "" : "(\(buildType))"
        }

        return "OpenCore \(version) \(formattedBuildType)".trimmingCharacters(in: .whitespaces)
    }
}
