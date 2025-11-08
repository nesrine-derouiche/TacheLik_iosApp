//
//  Logger.swift
//  projectDAM
//
//  Created on 11/7/2025.
//

import Foundation
import Combine
import os.log

// MARK: - Logger
/// Centralized logging utility for the app
final class Logger {
    
    // MARK: - Log Levels
    enum Level {
        case debug, info, warning, error
        
        var icon: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            }
        }
    }
    
    // MARK: - Shared Instance
    static let shared = Logger()
    
    private let osLog = OSLog(subsystem: "com.esprit.projectDAM", category: "app")
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Log a debug message
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    /// Log an info message
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    /// Log a warning message
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    /// Log an error message
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    // MARK: - Private Methods
    
    private func log(_ message: String, level: Level, file: String, function: String, line: Int) {
        let fileName = (file as NSString).lastPathComponent
        let logMessage = "\(level.icon) [\(fileName):\(line)] \(function) - \(message)"
        
        #if DEBUG
        print(logMessage)
        #endif
        
        // Also log to system
        os_log("%{public}@", log: osLog, type: osLogType(for: level), logMessage)
    }
    
    private func osLogType(for level: Level) -> OSLogType {
        switch level {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }
}
