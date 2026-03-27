import Foundation

/// A thin wrapper around `NSLock` that provides a closure-based API.
final class Lock: @unchecked Sendable {

    private let nsLock = NSLock()

    /// Acquires the lock, executes `body`, and releases the lock.
    ///
    /// - Returns: The value returned by `body`.
    /// - Throws: Rethrows any error thrown by `body`.
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        nsLock.lock()
        defer { nsLock.unlock() }
        return try body()
    }
}
