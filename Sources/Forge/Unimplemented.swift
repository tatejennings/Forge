/// Returns a value of type `T` that will never actually be produced — calling this
/// function always terminates via `fatalError`.
///
/// Use `unimplemented` when defining test container dependencies to ensure that any
/// dependency not explicitly overridden will loudly fail if called, rather than
/// silently executing live code.
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
        "'\(name)' was called but is not implemented. Override this dependency in your test container.",
        file: file,
        line: line
    )
}
