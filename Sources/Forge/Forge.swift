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
/// > Important: Set ``defaultContainer`` on the main thread before any background
///   work begins. Mutation after startup is not thread-safe.
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
    /// - Note: Must be set on the main thread before any background work begins.
    public static var defaultContainer: Container? = AppContainer.shared
}
