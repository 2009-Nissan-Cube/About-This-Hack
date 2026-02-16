import Foundation
import os.log

/// ATHLogger provides a unified logging system for the application
/// with support for different log levels and categories.
final class ATHLogger {
    // MARK: - Log Levels
    
    /// Defines the severity levels for logging
    enum Level: Int, CaseIterable, Comparable {
        case debug = 0, info = 1, warning = 2, error = 3

        static func < (lhs: Level, rhs: Level) -> Bool { lhs.rawValue < rhs.rawValue }

        var label: String {
            switch self {
            case .debug: return "DEBUG"
            case .info: return "INFO"
            case .warning: return "WARNING"
            case .error: return "ERROR"
            }
        }
        
        /// Log level icon for visual distinction in console
        var icon: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            }
        }
        
        /// Converts to system log type
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            }
        }
    }
    
    // MARK: - Categories
    
    /// Defines logical categories for logs
    enum Category: String {
        case ui = "UI"
        case data = "Data"
        case hardware = "Hardware"
        case system = "System"
        case general = "General"
        
        /// Returns OSLog object for this category
        var osLog: OSLog {
            OSLog(subsystem: "com.alexanderskula.AboutThisHack", category: rawValue)
        }
    }
    
    // MARK: - Configuration
    
    /// The minimum log level that will be displayed
    #if DEBUG
    static var minimumLogLevel: Level = .debug
    #else
    static var minimumLogLevel: Level = .info
    #endif
    
    /// Whether to show file and line information in logs
    static var showSourceInfo = true
    
    /// Whether to show timestamps in logs
    static var showTimestamps = true

    private static let timestampFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
    
    // MARK: - Logging Methods
    
    /// Log a message with the specified level and category
    static func log(
        _ message: String,
        level: Level = .info,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        // Skip logging if below minimum level
        guard level >= minimumLogLevel else {
            return
        }
        
        // Format message with metadata
        let formattedMessage = formatLogMessage(
            message: message,
            level: level,
            category: category,
            file: file,
            function: function,
            line: line
        )
        
        // Log using OSLog (which also outputs to console)
        os_log("%{public}@", log: category.osLog, type: level.osLogType, formattedMessage)
    }
    
    /// Formats a log message with relevant metadata
    private static func formatLogMessage(
        message: String,
        level: Level,
        category: Category,
        file: String,
        function: String,
        line: Int
    ) -> String {
        var components = [String]()
        
        // Add level icon
        components.append(level.icon)
        
        // Add timestamp if enabled
        if showTimestamps {
            components.append("[\(timestampFormatter.string(from: Date()))]")
        }
        
        // Add level and category
        components.append("[\(level.label)][\(category.rawValue)]")
        
        // Add source information if enabled
        if showSourceInfo {
            let fileName = URL(fileURLWithPath: file).lastPathComponent
            components.append("[\(fileName):\(line)]")
        }
        
        // Add function name and message
        components.append("\(function):")
        components.append(message)
        
        return components.joined(separator: " ")
    }
    
    // MARK: - Convenience Methods
    
    /// Log a debug message
    static func debug(
        _ message: String,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, category: category, file: file, function: function, line: line)
    }
    
    /// Log an info message
    static func info(
        _ message: String,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, category: category, file: file, function: function, line: line)
    }
    
    /// Log a warning message
    static func warning(
        _ message: String,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, category: category, file: file, function: function, line: line)
    }
    
    /// Log an error message
    static func error(
        _ message: String,
        category: Category = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, category: category, file: file, function: function, line: line)
    }
} 