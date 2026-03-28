/// Accumulates override registrations for use with ``Container/withOverrides(_:run:)-6oex3``.
///
/// The builder is passed into the configuration closure of `withOverrides`.
/// Register overrides by calling ``override(_:with:)`` with a key that matches
/// the computed property name on the container.
public struct OverrideBuilder: Sendable {

    var factories: [String: @Sendable () -> Any] = [:]

    /// Registers an override factory for the given key.
    ///
    /// - Parameters:
    ///   - key: Must exactly match the computed property name on the container.
    ///   - factory: A closure that produces the override value.
    public mutating func override<T>(_ key: String, with factory: @escaping @Sendable () -> T) {
        factories[key] = { factory() as Any }
    }
}
