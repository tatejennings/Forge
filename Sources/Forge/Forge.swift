/// The Forge namespace. Use this to configure framework-level settings.
///
/// ## Default Container
///
/// ``defaultContainer`` is automatically set to ``AppContainer/shared`` when the
/// framework is loaded. For simple apps that extend ``AppContainer``, no manual
/// configuration is needed.
///
/// ```swift
/// // Only needed if you have a custom container:
/// Forge.defaultContainer = MyCustomContainer.shared
/// ```
///
/// > Tip: Configure ``defaultContainer`` once at startup, before resolving any
///   dependencies. Reads and writes are synchronized, so it is safe to access from
///   any thread, but reassigning it mid-flight can change which container a later
///   `@Inject` resolves from.
public enum Forge {

    /// The default container used by the framework.
    ///
    /// This is automatically set to ``AppContainer/shared`` when the framework
    /// is first loaded. You only need to set this manually if you are using
    /// a custom container class instead of the built-in ``AppContainer``.
    ///
    /// ```swift
    /// // Only needed if you have a custom container
    /// Forge.defaultContainer = MyCustomContainer.shared
    /// ```
    ///
    /// - Note: Access is synchronized by an internal lock, so reading and writing
    ///   from multiple threads is safe. Prefer configuring it once at startup.
    public static var defaultContainer: Container? {
        get { lock.withLock { _defaultContainer } }
        set { lock.withLock { _defaultContainer = newValue } }
    }

    /// Backing storage for ``defaultContainer``. Guarded by ``lock`` — never touch
    /// it directly. `nonisolated(unsafe)` is sound because every access goes through
    /// the lock.
    private nonisolated(unsafe) static var _defaultContainer: Container? = AppContainer.shared
    private static let lock = Lock()
}
