/// Defines the lifecycle of a dependency managed by a ``Container``.
///
/// Pass a scope to ``Container/provide(_:preview:key:_:)`` to control how
/// instances are created and cached.
///
/// | Scope | Behavior |
/// | --- | --- |
/// | ``transient`` | New instance every resolution (default) |
/// | ``singleton`` | One instance for the container's lifetime |
/// | ``cached`` | One instance until ``Container/resetCached()`` is called |
public enum Scope: Sendable {

    /// A new instance is created every time the dependency is resolved. (Default)
    case transient

    /// One instance per container. Created on first resolution, lives as long as the container.
    case singleton

    /// One instance per container. Created on first resolution. Can be explicitly reset
    /// via ``Container/resetCached()``. Survives until reset or container deallocation.
    case cached
}
