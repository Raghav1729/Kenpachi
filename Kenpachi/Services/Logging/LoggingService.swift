//
//  LoggingService.swift
//  Kenpachi
//
//  Created by Raghav Mishra on 26/05/25.
//

import Foundation
import ComposableArchitecture

// MARK: - Logging Service Interface

/// A service protocol for logging various types of messages within the application.
struct LoggingService {
    /// Logs an informational message.
    var logInfo: @Sendable (_ message: String, _ file: String, _ function: String, _ line: Int) -> Void
    /// Logs a warning message.
    var logWarning: @Sendable (_ message: String, _ file: String, _ function: String, _ line: Int) -> Void
    /// Logs an error message, typically with an associated Swift Error.
    var logError: @Sendable (_ message: String, _ error: Error?, _ file: String, _ function: String, _ line: Int) -> Void
    /// Logs a page opening event.
    var logPageOpened: @Sendable (_ pageName: String, _ file: String, _ function: String, _ line: Int) -> Void
}

// MARK: - Live Logging Service Implementation

extension LoggingService: DependencyKey {
    static let liveValue = Self(
        logInfo: { message, file, function, line in
            // In a real app, you might send this to a remote logging service (e.g., Firebase Crashlytics, Sentry)
            // or write to a local log file. For now, we'll just print.
            print("[\(Date())] ℹ️ INFO [\(URL(fileURLWithPath: file).lastPathComponent):\(line)] \(function): \(message)")
        },
        logWarning: { message, file, function, line in
            print("[\(Date())] ⚠️ WARNING [\(URL(fileURLWithPath: file).lastPathComponent):\(line)] \(function): \(message)")
        },
        logError: { message, error, file, function, line in
            let errorMessage = error?.localizedDescription ?? "No error description."
            print("[\(Date())] ❌ ERROR [\(URL(fileURLWithPath: file).lastPathComponent):\(line)] \(function): \(message) - Error: \(errorMessage)")
        },
        logPageOpened: { pageName, file, function, line in
            print("[\(Date())] ➡️ PAGE OPENED [\(URL(fileURLWithPath: file).lastPathComponent):\(line)] \(function): Page: \(pageName)")
        }
    )
}

// MARK: - Mock Logging Service Implementation (for testing and previews)

extension LoggingService: TestDependencyKey {
    static let testValue = Self(
        logInfo: { _, _, _, _ in }, // Do nothing in tests by default
        logWarning: { _, _, _, _ in },
        logError: { _, _, _, _,_  in },
        logPageOpened: { _, _, _, _ in }
    )

    // A recording logger for tests that want to inspect logs
    static func recording() -> Self {
        var recordedLogs: [String] = []
        return Self(
            logInfo: { message, _, _, _ in recordedLogs.append("INFO: \(message)") },
            logWarning: { message, _, _, _ in recordedLogs.append("WARNING: \(message)") },
            logError: { message, error, _, _, _ in recordedLogs.append("ERROR: \(message) - \(error?.localizedDescription ?? "")") },
            logPageOpened: { pageName, _, _, _ in recordedLogs.append("PAGE_OPENED: \(pageName)") }
        )
    }
}

// MARK: - Dependency Values Extension

extension DependencyValues {
    var loggingService: LoggingService {
        get { self[LoggingService.self] }
        set { self[LoggingService.self] = newValue }
    }
}

// MARK: - Convenience Global Functions (Optional, but often useful)

// These global functions make logging calls cleaner, automatically capturing file/function/line.
func LogInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    @Dependency(\.loggingService) var loggingService
    loggingService.logInfo(message, file, function, line)
}

func LogWarning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
    @Dependency(\.loggingService) var loggingService
    loggingService.logWarning(message, file, function, line)
}

func LogError(_ message: String, error: Error? = nil, file: String = #file, function: String = #function, line: Int = #line) {
    @Dependency(\.loggingService) var loggingService
    loggingService.logError(message, error, file, function, line)
}

func LogPageOpened(_ pageName: String, file: String = #file, function: String = #function, line: Int = #line) {
    @Dependency(\.loggingService) var loggingService
    loggingService.logPageOpened(pageName, file, function, line)
}
