import Foundation

// MARK: - Shared Constants
struct CustomLogoConstants {
    static let customLogoPathKey = "customLogoPath"
    static let customLogoFileName = "custom-logo.png"

    /// Stable Application Support directory for the custom logo copy.
    static var supportDirectoryURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let bundleID = Bundle.main.bundleIdentifier ?? "AboutThisHack"
        return base.appendingPathComponent(bundleID, isDirectory: true)
    }

    static var storedLogoURL: URL {
        supportDirectoryURL.appendingPathComponent(customLogoFileName)
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let customLogoDidChange = Notification.Name("customLogoDidChange")
}
