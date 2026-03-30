/// The base class for all dependency containers in Forge.
///
/// Subclass `Container` to define your module's dependencies as computed properties.
/// Each property calls ``provide(_:key:_:preview:)`` to register its factory and scope.
///
/// ```swift
/// final class AppContainer: Container, SharedContainer {
///     static var shared = AppContainer()
///
///     var authService: any AuthServiceProtocol {
///         provide(.singleton) { AuthService() } preview: { MockAuthService() }
///     }
/// }
/// ```
///
/// Conform to ``SharedContainer`` to enable the zero-argument
/// ``ContainerInject`` syntax (`@Inject(\.property)`).
///
/// - Important: Always use protocol return types on dependency properties
///   to enable mock substitution in tests and previews.
///
/// - Note: All cache and override access is protected by an `NSRecursiveLock`,
///   making `Container` safe to use from multiple threads. The lock is recursive
///   because sibling dependency resolution re-enters ``provide(_:key:_:preview:)``.
///
/// ## Topics
///
/// ### Creating a Container
/// - ``init()``
///
/// ### Resolving Dependencies
/// - ``provide(_:key:_:preview:)``
///
/// ### Testing and Overrides
/// - ``withOverrides(_:run:)-3qdpl``
/// - ``withOverrides(_:run:)-4eui2``
/// - ``override(_:with:)``
/// - ``removeOverride(for:)``
/// - ``resetAll()``
/// - ``resetCached()``
open class Container: @unchecked Sendable {

    // MARK: - Internal Storage

    private let lock = Lock()
    private var singletonCache: [String: Any] = [:]
    private var cachedCache: [String: Any] = [:]
    private var overrides: [String: @Sendable () -> Any] = [:]

    #if DEBUG
    private var registeredOverrideKeys: Set<String> = []
    private var queriedOverrideKeys: Set<String> = []
    #endif

    // MARK: - Initialization

    /// Creates an empty container with no cached values or overrides.
    public init() {}

    // MARK: - Core Resolution

    /// Resolves a dependency using the given scope and factory.
    ///
    /// Call this from computed properties on your ``Container`` subclass.
    /// The generic type `T` is inferred from the computed property's return type,
    /// so factories can return concrete types without explicit casting:
    ///
    /// ```swift
    /// var authService: any AuthServiceProtocol {
    ///     provide(.singleton) {
    ///         LiveAuthService()
    ///     } preview: {
    ///         MockAuthService()
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - scope: The lifecycle scope for this dependency. Defaults to `.transient`.
    ///   - key: The registration key. Defaults to the property name via `#function`.
    ///   - factory: The factory closure that creates the dependency.
    ///   - preview: An optional factory used when running inside an Xcode preview.
    ///     Preview values are never cached regardless of the declared scope.
    /// - Returns: The resolved dependency instance.
    ///
    /// - Note: Resolution follows a strict precedence order:
    ///   1. **Overrides** — checked first; override type mismatches fall through with a
    ///      DEBUG warning instead of crashing.
    ///   2. **Preview factory** — used when running inside an Xcode preview and a
    ///      `preview` closure was provided. Preview values are never cached.
    ///   3. **Normal factory** — the default path for transient, singleton, and cached scopes.
    public func provide<T>(
        _ scope: Scope = .transient,
        key: String = #function,
        _ factory: () -> Any,
        preview: (() -> Any)? = nil
    ) -> T {
        // 1. Check overrides first — overrides are never cached
        if let overrideFactory = lock.withLock({
            #if DEBUG
            queriedOverrideKeys.insert(key)
            #endif
            return overrides[key]
        }) {
            let result = overrideFactory()
            if let value = result as? T {
                return value
            }
            #if DEBUG
            print("[Forge] ⚠️ Override for '\(key)' returned \(type(of: result)) but expected \(T.self). Falling through to factory.")
            #endif
        }

        // 2. Preview factory — never cached
        if PreviewContext.isPreview, let preview {
            guard let value = preview() as? T else {
                fatalError("[Forge] Preview factory for '\(key)' returned wrong type. Expected \(T.self).")
            }
            return value
        }

        // 3. Transient — always create fresh
        if scope == .transient {
            guard let value = factory() as? T else {
                fatalError("[Forge] Factory for '\(key)' returned wrong type. Expected \(T.self).")
            }
            return value
        }

        // 4. Singleton / Cached
        return resolveScoped(scope: scope, key: key, factory: factory)
    }

    // MARK: - Scoped Resolution

    private func resolveScoped<T>(scope: Scope, key: String, factory: () -> Any) -> T {
        // Note: Swift dictionaries are value types — concurrent read + write is UB.
        // All cache access must be locked. The factory is called inside the lock
        // to prevent duplicate instantiation.
        return lock.withLock {
            let cache = scope == .singleton ? singletonCache : cachedCache
            if let cached = cache[key], let value = cached as? T {
                return value
            }

            let result = factory()
            guard let value = result as? T else {
                fatalError("[Forge] Factory for '\(key)' returned \(type(of: result)) but expected \(T.self).")
            }
            if scope == .singleton {
                singletonCache[key] = value
            } else {
                cachedCache[key] = value
            }
            return value
        }
    }

    // MARK: - Testing / Overrides

    /// Registers overrides for the duration of a closure, then automatically restores
    /// the previous state.
    ///
    /// Overrides registered via the builder take precedence over original factories
    /// within the closure body. Cleanup is guaranteed even if the body throws.
    ///
    /// ```swift
    /// container.withOverrides {
    ///     $0.override("authService") { MockAuthService() }
    /// } run: {
    ///     let vm = LoginViewModel()
    ///     // test assertions...
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - configure: A closure that registers overrides via an ``OverrideBuilder``.
    ///   - body: The closure to execute with overrides active.
    public func withOverrides(
        _ configure: (inout OverrideBuilder) -> Void,
        run body: () throws -> Void
    ) rethrows {
        var builder = OverrideBuilder()
        configure(&builder)

        let snapshot = lock.withLock {
            let saved = overrides
            for (key, factory) in builder.factories {
                overrides[key] = factory
                #if DEBUG
                registeredOverrideKeys.insert(key)
                #endif
            }
            return saved
        }

        defer { restoreOverrides(snapshot) }
        try body()
    }

    /// Registers overrides for the duration of an async closure, then automatically
    /// restores the previous state.
    ///
    /// This is the async variant of ``withOverrides(_:run:)-3qdpl``. Use it when your
    /// test body contains `await` calls.
    ///
    /// - Parameters:
    ///   - configure: A closure that registers overrides via an ``OverrideBuilder``.
    ///   - body: The async closure to execute with overrides active.
    public func withOverrides(
        _ configure: (inout OverrideBuilder) -> Void,
        run body: () async throws -> Void
    ) async rethrows {
        var builder = OverrideBuilder()
        configure(&builder)

        let snapshot = lock.withLock {
            let saved = overrides
            for (key, factory) in builder.factories {
                overrides[key] = factory
                #if DEBUG
                registeredOverrideKeys.insert(key)
                #endif
            }
            return saved
        }

        defer { restoreOverrides(snapshot) }
        try await body()
    }

    /// Registers a replacement factory for a given key directly.
    ///
    /// Use this for `setUp`/`tearDown` patterns where the closure-based
    /// ``withOverrides(_:run:)-3qdpl`` is impractical.
    ///
    /// - Parameters:
    ///   - key: Must exactly match the computed property name on the container.
    ///   - factory: A closure that produces the override value.
    public func override<T>(_ key: String, with factory: @escaping @Sendable () -> T) {
        lock.withLock {
            overrides[key] = factory
            #if DEBUG
            registeredOverrideKeys.insert(key)
            #endif
        }
    }

    /// Removes a single override by key, restoring the original factory behavior.
    public func removeOverride(for key: String) {
        _ = lock.withLock {
            overrides.removeValue(forKey: key)
        }
    }

    /// Removes all registered overrides and clears all cached and singleton values.
    ///
    /// In DEBUG builds, emits warnings for any override keys that were registered but
    /// never accessed — this helps catch typos in override key strings.
    ///
    /// - SeeAlso: ``resetCached()`` to clear only cached-scope values.
    public func resetAll() {
        lock.withLock {
            #if DEBUG
            emitUnmatchedOverrideWarnings()
            registeredOverrideKeys.removeAll()
            queriedOverrideKeys.removeAll()
            #endif
            overrides.removeAll()
            singletonCache.removeAll()
            cachedCache.removeAll()
        }
    }

    /// Clears only cached-scope values. Leaves singletons and overrides intact.
    ///
    /// Use this to reset ``Scope/cached`` dependencies between test cases while
    /// preserving longer-lived singletons.
    ///
    /// - SeeAlso: ``resetAll()`` to clear everything including singletons and overrides.
    public func resetCached() {
        lock.withLock {
            cachedCache.removeAll()
        }
    }

    // MARK: - Private Helpers

    private func restoreOverrides(_ snapshot: [String: @Sendable () -> Any]) {
        lock.withLock {
            #if DEBUG
            emitUnmatchedOverrideWarnings()
            registeredOverrideKeys.removeAll()
            queriedOverrideKeys.removeAll()
            #endif
            overrides = snapshot
        }
    }

    #if DEBUG
    private func emitUnmatchedOverrideWarnings() {
        let unmatched = registeredOverrideKeys.subtracting(queriedOverrideKeys)
        for key in unmatched.sorted() {
            print("[Forge] ⚠️ Override registered for '\(key)' but never accessed. Check for typos in the override key.")
        }
    }
    #endif
}
