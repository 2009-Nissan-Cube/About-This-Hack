import Foundation

class ConfigurationManager {
    static let shared = ConfigurationManager()
    private init() {}
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Keys
    private enum Keys {
        static let windowFrame = "MainWindowFrame"
        // Add more keys here as needed
    }
    
    // MARK: - Window Configuration
    var windowFrame: NSRect? {
        get {
            guard let frameString = defaults.string(forKey: Keys.windowFrame) else { return nil }
            return NSRectFromString(frameString)
        }
        set {
            if let newFrame = newValue {
                defaults.set(NSStringFromRect(newFrame), forKey: Keys.windowFrame)
            } else {
                defaults.removeObject(forKey: Keys.windowFrame)
            }
        }
    }
    
    // MARK: - Reset
    func resetAllSettings() {
        Keys.self.allCases.forEach { defaults.removeObject(forKey: $0) }
    }
} 