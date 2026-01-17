import Foundation

// MARK: - Shared Constants
struct CustomLogoConstants {
    static let customLogoPathKey = "customLogoPath"
}

// MARK: - Notification Extension
extension Notification.Name {
    static let customLogoDidChange = Notification.Name("customLogoDidChange")
}
