/// Accumulates override registrations for use with ``Container/withOverrides(_:run:)-3qdpl``.
///
/// The builder is passed into the configuration closure of `withOverrides`.
/// Register overrides by calling ``override(_:with:)`` with a KeyPath to the
/// container property you want to override.
///
/// ```swift
/// container.withOverrides {
///     $0.override(\.authService) { MockAuthService() }
/// } run: {
///     // test code...
/// }
/// ```
public struct OverrideBuilder<C: Container>: Sendable {

    var factories: [String: @Sendable () -> Any] = [:]

    /// Registers an override factory for the dependency at the given KeyPath.
    ///
    /// The property name is extracted automatically from the KeyPath, ensuring
    /// compile-time safety — the property must exist on the container and
    /// Xcode rename refactoring works correctly.
    ///
    /// - Parameters:
    ///   - keyPath: A KeyPath to the container property to override.
    ///   - factory: A closure that produces the override value.
    public mutating func override<T>(_ keyPath: KeyPath<C, T>, with factory: @escaping @Sendable () -> T) {
        guard let name = propertyName(from: keyPath) else {
            assertionFailure(
                "Forge: could not extract property name from \(keyPath). "
                + "Override not registered. This is a Forge bug — please file an issue."
            )
            return
        }
        factories[name] = factory
    }
}
