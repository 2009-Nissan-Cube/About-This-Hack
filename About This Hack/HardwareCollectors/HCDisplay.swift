import Foundation
import AppKit
import CoreGraphics

private struct DisplaySnapshot {
    let name: String
    let resolution: String
    let isBuiltIn: Bool
    let scale: Double
}

class HCDisplay {
    static let shared = HCDisplay()
    private init() {}

    private let displayLock = NSLock()
    private var _displays: [DisplaySnapshot]?

    private var displays: [DisplaySnapshot] {
        displayLock.lock()
        defer { displayLock.unlock() }

        if let cached = _displays {
            return cached
        }

        let computed = computeDisplays()
        _displays = computed
        return computed
    }

    func reset() {
        displayLock.lock()
        defer { displayLock.unlock() }
        _displays = nil
        ATHLogger.debug(NSLocalizedString("log.display.reset", comment: "Display info reset"), category: .hardware)
    }

    func getDisp() -> String {
        ATHLogger.debug(NSLocalizedString("log.display.getting_main", comment: "Getting main display string"), category: .hardware)
        guard let primaryDisplay = displays.first else {
            return "Unknown Display"
        }
        return "\(primaryDisplay.name) (\(primaryDisplay.resolution))"
    }

    func getDispInfo() -> String {
        ATHLogger.debug(NSLocalizedString("log.display.getting_all", comment: "Getting all displays info string"), category: .hardware)
        guard !displays.isEmpty else {
            return "No display information available"
        }

        return displays.enumerated().map { index, display in
            var lines = [String]()
            lines.append(display.name)
            lines.append("Resolution: \(display.resolution)")
            lines.append("Built-In: \(display.isBuiltIn ? "Yes" : "No")")
            if display.scale != 1 {
                lines.append("Scale: \(String(format: "%.1fx", display.scale))")
            }
            if index != displays.count - 1 {
                lines.append("")
            }
            return lines.joined(separator: "\n")
        }.joined(separator: "\n")
    }

    func getDisplayNames() -> [String] {
        displays.map(\.name)
    }

    func getDisplayResolutions() -> [String] {
        displays.map(\.resolution)
    }

    func hasBuiltInDisplay() -> Bool {
        displays.contains { $0.isBuiltIn }
    }

    private func computeDisplays() -> [DisplaySnapshot] {
        ATHLogger.debug(NSLocalizedString("log.display.init", comment: "Initializing Display Info"), category: .hardware)

        let snapshots = NSScreen.screens.map { screen -> DisplaySnapshot in
            let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
            let cgDisplayID = CGDirectDisplayID(displayID?.uint32Value ?? 0)
            let mode = cgDisplayID != 0 ? CGDisplayCopyDisplayMode(cgDisplayID) : nil
            let pixelWidth = mode?.pixelWidth ?? Int(screen.frame.width * screen.backingScaleFactor)
            let pixelHeight = mode?.pixelHeight ?? Int(screen.frame.height * screen.backingScaleFactor)
            let resolution = "\(pixelWidth) x \(pixelHeight)"
            let builtIn = cgDisplayID != 0 ? CGDisplayIsBuiltin(cgDisplayID) != 0 : false
            let displayName: String
            if #available(macOS 10.15, *) {
                displayName = screen.localizedName
            } else {
                displayName = builtIn ? "Built-in Display" : "Display"
            }

            return DisplaySnapshot(
                name: displayName,
                resolution: resolution,
                isBuiltIn: builtIn,
                scale: Double(screen.backingScaleFactor)
            )
        }

        ATHLogger.debug(String(format: NSLocalizedString("log.display.parsing_data", comment: "Parsing display data"), snapshots.count), category: .hardware)
        return snapshots
    }
}
