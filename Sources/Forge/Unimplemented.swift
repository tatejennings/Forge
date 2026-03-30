/// Returns a value of type `T` that will never actually be produced — calling this
/// function always terminates via `fatalError`.
///
/// Use `unimplemented` to make dependency contracts explicit. Any dependency marked
/// as unimplemented will crash immediately if resolved without being overridden,
/// rather than silently running the wrong code.
///
/// **Cross-module proxies** — feature modules that depend on services wired by the
/// app target should use `unimplemented` as the default factory. If the composition
/// root forgets to wire the dependency, the app crashes on launch with a clear
/// message instead of silently running on stale or mock data:
///
/// ```swift
/// public var analytics: any AnalyticsProtocol {
///     provide(.singleton) {
///         unimplemented("analytics")
///     } preview: {
///         MockAnalytics()
///     }
/// }
/// ```
///
/// **Test containers** — use `unimplemented` to ensure that any dependency not
/// explicitly overridden in a test will loudly fail if called:
///
/// ```swift
/// override var analytics: any AnalyticsProtocol {
///     provide { unimplemented("analytics") }
/// }
/// ```
///
/// - Parameters:
///   - name: A descriptive name for the dependency (used in the error message).
///   - file: The file where `unimplemented` was called (auto-captured).
///   - line: The line where `unimplemented` was called (auto-captured).
/// - Returns: Never returns — always calls `fatalError`.
public func unimplemented<T>(_ name: String, file: StaticString = #file, line: UInt = #line) -> T {
    fatalError(
        "'\(name)' was called but is not implemented. Override this dependency before use.",
        file: file,
        line: line
    )
}
