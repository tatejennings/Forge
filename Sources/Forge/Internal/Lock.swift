import Foundation

/// A thin wrapper around `NSRecursiveLock` that provides a closure-based API.
///
/// The lock is **recursive**. ``Container/provide(_:key:_:preview:)`` runs a
/// dependency's factory *inside* the lock so that a `.singleton`/`.cached` value is
/// built exactly once, even under concurrent first resolution. Because a factory may
/// resolve sibling dependencies (e.g. `self.httpClient` inside `self.remoteTaskService`),
/// which re-enters `provide` and re-acquires the same lock, recursion is required to
/// avoid deadlock.
///
/// `@unchecked Sendable` is safe here because `NSRecursiveLock` is inherently
/// thread-safe — its entire purpose is cross-thread synchronization. The Swift compiler
/// can't verify this automatically since Foundation locks predate the `Sendable` protocol.
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
