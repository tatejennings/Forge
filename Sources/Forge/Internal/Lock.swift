import Foundation

/// A thin wrapper around `NSLock` that provides a closure-based API.
///
/// The lock is **non-recursive**. Forge never runs user-provided factory closures
/// while holding it: ``Container/provide(_:key:_:preview:)`` builds values *outside*
/// the lock and takes it only for the brief dictionary reads/writes around the cache
/// (double-checked locking). Because a factory that resolves sibling dependencies
/// runs between `withLock` blocks rather than inside one, it never re-enters the lock,
/// so recursion is not required.
///
/// `@unchecked Sendable` is safe here because `NSLock` is inherently thread-safe —
/// its entire purpose is cross-thread synchronization. The Swift compiler can't
/// verify this automatically since Foundation locks predate the `Sendable` protocol.
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
