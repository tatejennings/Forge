/// The base class for all dependency containers in Forge.
///
/// Subclass `Container` to define your module's dependencies as computed properties.
/// Each property calls ``provide(_:preview:key:_:)`` to register its factory and scope.
///
/// ```swift
/// final class AppContainer: Container, SharedContainer {
///     static var shared = AppContainer()
///
///     var authService: any AuthServiceProtocol {
///         provide(.singleton, preview: { MockAuthService() }) { AuthService() }
///     }
/// }
/// ```
///
/// - Important: Always use protocol return types on dependency properties
///   to enable mock substitution in tests and previews.
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

    public init() {}

    // MARK: - Core Resolution

    /// Resolves a dependency using the given scope and factory.
    ///
    /// Call this from computed properties on your ``Container`` subclass.
    /// The `key` parameter defaults to `#function`, which automatically matches
    /// the enclosing property name.
    ///
    /// - Parameters:
    ///   - scope: The lifecycle scope for this dependency. Defaults to `.transient`.
    ///   - preview: An optional factory used when running inside an Xcode preview.
    ///     Preview values are never cached regardless of the declared scope.
    ///   - key: The registration key. Defaults to the property name via `#function`.
    ///   - factory: The factory closure that creates the dependency.
    /// - Returns: The resolved dependency instance.
    public func provide<T>(
        _ scope: Scope = .transient,
        preview: (() -> T)? = nil,
        key: String = #function,
        _ factory: () -> T
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
            return preview()
        }

        // 3. Transient — always create fresh
        if scope == .transient {
            return factory()
        }

        // 4. Singleton / Cached — double-checked locking
        return resolveScoped(scope: scope, key: key, factory: factory)
    }

    // MARK: - Scoped Resolution

    private func resolveScoped<T>(scope: Scope, key: String, factory: () -> T) -> T {
        // Note: Swift dictionaries are value types — concurrent read + write is UB.
        // All cache access must be locked. The factory is called inside the lock
        // to prevent duplicate instantiation.
        return lock.withLock {
            let cache = scope == .singleton ? singletonCache : cachedCache
            if let cached = cache[key], let value = cached as? T {
                return value
            }

            let value = factory()
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

    /// Async variant of ``withOverrides(_:run:)-6oex3`` for use in async test contexts.
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
    /// ``withOverrides(_:run:)-6oex3`` is impractical.
    ///
    /// - Parameters:
    ///   - key: Must exactly match the computed property name on the container.
    ///   - factory: A closure that produces the override value.
    public func override<T>(_ key: String, with factory: @escaping @Sendable () -> T) {
        lock.withLock {
            // Wrap the factory to return the concrete value directly as Any,
            // avoiding double-existential boxing when T is an existential type
            // (e.g. `any AppStateProtocol`).
            overrides[key] = { factory() as Any }
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

    /// Removes all registered overrides and clears all cached/singleton values.
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
