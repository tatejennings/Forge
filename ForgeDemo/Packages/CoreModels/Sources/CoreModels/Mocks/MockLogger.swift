#if DEBUG
import Foundation

/// No-op logger for previews and tests. Records messages so tests can assert on them.
public final class MockLogger: LoggerProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var _messages: [(level: LogLevel, message: String)] = []

    public var messages: [(level: LogLevel, message: String)] {
        lock.lock(); defer { lock.unlock() }
        return _messages
    }

    public init() {}

    public func log(_ level: LogLevel, _ message: String) {
        lock.lock(); defer { lock.unlock() }
        _messages.append((level, message))
    }
}
#endif
