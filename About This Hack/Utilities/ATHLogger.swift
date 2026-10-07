import os

/// Unified logging with one category per app area. Debug messages are compiled
/// into Debug builds only, so Release never pays to format them.
enum ATHLogger {
    enum Category: String {
        case ui = "UI", data = "Data", hardware = "Hardware", system = "System", general = "General"
    }

    static func debug(_ message: @autoclosure () -> String, category: Category = .general) {
        #if DEBUG
        log(.debug, message(), category)
        #endif
    }

    static func info(_ message: @autoclosure () -> String, category: Category = .general) {
        log(.info, message(), category)
    }

    static func warning(_ message: @autoclosure () -> String, category: Category = .general) {
        log(.default, message(), category)
    }

    static func error(_ message: @autoclosure () -> String, category: Category = .general) {
        log(.error, message(), category)
    }

    private static func log(_ type: OSLogType, _ message: String, _ category: Category) {
        Logger(subsystem: "com.alexanderskula.AboutThisHack", category: category.rawValue)
            .log(level: type, "\(message, privacy: .public)")
    }
}
