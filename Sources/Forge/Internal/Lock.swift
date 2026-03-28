import Foundation

/// A thin wrapper around `NSRecursiveLock` that provides a closure-based API.
///
/// Recursive locking is required because container factories can reference
/// sibling dependencies (e.g. `self.httpClient` inside `self.remoteTaskService`),
/// which re-enters `provide` and acquires the same lock.
///
/// `@unchecked Sendable` is safe here because `NSRecursiveLock` is inherently
/// thread-safe — its entire purpose is cross-thread synchronization. The Swift
/// compiler can't verify this automatically since Foundation locks predate
/// the `Sendable` protocol.
final class Lock: @unchecked Sendable {

    private let nsLock = NSRecursiveLock()

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
