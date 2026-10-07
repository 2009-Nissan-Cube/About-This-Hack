import AppKit
import CoreGraphics

private struct DisplaySnapshot {
    let name: String
    let resolution: String
    let isBuiltIn: Bool
    let scale: Double
    let diagonalInches: Double?
}

/// Connected displays. AppKit-backed, so main thread only; `invalidate()` on screen changes.
final class HCDisplay {
    static let shared = HCDisplay()
    private init() {}

    private var cachedDisplays: [DisplaySnapshot]?

    private var displays: [DisplaySnapshot] {
        dispatchPrecondition(condition: .onQueue(.main))
        if let cachedDisplays {
            return cachedDisplays
        }
        let computed = NSScreen.screens.map(Self.snapshot)
        cachedDisplays = computed
        return computed
    }

    func invalidate() {
        cachedDisplays = nil
    }

    private static func snapshot(of screen: NSScreen) -> DisplaySnapshot {
        let displayID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
        let mode = displayID != 0 ? CGDisplayCopyDisplayMode(displayID) : nil
        let width = mode?.pixelWidth ?? Int(screen.frame.width * screen.backingScaleFactor)
        let height = mode?.pixelHeight ?? Int(screen.frame.height * screen.backingScaleFactor)
        let millimeters = displayID != 0 ? CGDisplayScreenSize(displayID) : .zero
        let inches = millimeters.width > 0 ? (millimeters.width * millimeters.width + millimeters.height * millimeters.height).squareRoot() / 25.4 : nil

        return DisplaySnapshot(
            name: screen.localizedName,
            resolution: "\(width) × \(height)",
            isBuiltIn: displayID != 0 && CGDisplayIsBuiltin(displayID) != 0,
            scale: Double(screen.backingScaleFactor),
            diagonalInches: inches.map(Double.init)
        )
    }

    func getDisp() -> String {
        guard let primary = displays.first else {
            return "Unknown Display"
        }
        return "\(primary.name) (\(primary.resolution))"
    }

    func getDispInfo() -> String {
        guard !displays.isEmpty else {
            return "No display information available"
        }

        return displays.map { display in
            var lines = [display.name, "Resolution: \(display.resolution)"]
            if let inches = display.diagonalInches {
                lines.append("Size: \(String(format: "%.0f", inches))-inch")
            }
            lines.append("Built-In: \(display.isBuiltIn ? "Yes" : "No")")
            if display.scale != 1 {
                lines.append("Scale: \(String(format: "%gx", display.scale))")
            }
            return lines.joined(separator: "\n")
        }.joined(separator: "\n\n")
    }

    func getDisplayNames() -> [String] {
        displays.map(\.name)
    }

    func getDisplayResolutions() -> [String] {
        displays.map(\.resolution)
    }
}
