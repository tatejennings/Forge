/// Defines the lifecycle of a dependency managed by a ``Container``.
public enum Scope: Sendable {

    /// A new instance is created every time the dependency is resolved. (Default)
    case transient

    /// One instance per container. Created on first resolution, lives as long as the container.
    case singleton

    /// One instance per container. Created on first resolution. Can be explicitly reset
    /// via ``Container/resetCached()``. Survives until reset or container deallocation.
    case cached
}
