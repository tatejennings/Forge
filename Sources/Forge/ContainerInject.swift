/// A property wrapper that lazily resolves a dependency from a ``Container``.
///
/// Resolution is deferred to first access of `wrappedValue`, not at initialization.
/// This avoids ordering issues when containers are configured after object creation.
///
/// **With a `SharedContainer`** (preferred — clean call sites):
/// ```swift
/// // In your module's DI.swift:
/// typealias Inject<T> = ContainerInject<AppContainer, T>
///
/// // At the call site:
/// @Inject(\.authService) private var auth
/// ```
///
/// **With an explicit container instance:**
/// ```swift
/// @ContainerInject(myContainer, \.authService) private var auth
/// ```
///
/// - Note: This property wrapper uses a `mutating get` for lazy resolution,
///   which works in class contexts. In struct contexts, the enclosing struct
///   must be declared as `var`.
@propertyWrapper
public struct ContainerInject<C: Container, Value> {

    private let keyPath: KeyPath<C, Value>
    private let container: C
    private var _resolved: Value?

    /// The resolved dependency value. Resolved lazily on first access.
    public var wrappedValue: Value {
        mutating get {
            if let resolved = _resolved {
                return resolved
            }
            let value = container[keyPath: keyPath]
            _resolved = value
            return value
        }
    }

    /// Creates an injection wrapper with an explicit container instance.
    ///
    /// - Parameters:
    ///   - container: The container instance to resolve from.
    ///   - keyPath: A key path to the dependency property on the container.
    public init(_ container: C, _ keyPath: KeyPath<C, Value>) {
        self.container = container
        self.keyPath = keyPath
    }

    /// Creates an injection wrapper using the container's shared instance.
    ///
    /// Requires `C` to conform to ``SharedContainer``.
    ///
    /// - Parameter keyPath: A key path to the dependency property on the container.
    public init(_ keyPath: KeyPath<C, Value>) where C: SharedContainer {
        self.container = C.shared
        self.keyPath = keyPath
    }
}
