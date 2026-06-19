/// Severity of a log message. Maps onto the system log levels in `OSLogger`.
public enum LogLevel: String, Sendable {
    case debug
    case info
    case warning
    case error
}

/// A minimal logging facade. The app depends only on this protocol, so the concrete
/// backend (OSLog, a file logger, a remote sink) can be swapped in one place — the
/// `LoggerContainer` — without touching any call site.
public protocol LoggerProtocol: Sendable {
    func log(_ level: LogLevel, _ message: String)
}

public extension LoggerProtocol {
    func debug(_ message: String)   { log(.debug, message) }
    func info(_ message: String)    { log(.info, message) }
    func warning(_ message: String) { log(.warning, message) }
    func error(_ message: String)   { log(.error, message) }
}
