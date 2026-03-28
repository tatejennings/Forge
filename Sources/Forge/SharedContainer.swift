/// A container that provides a shared static instance for convenient access.
///
/// Conform your ``Container`` subclass to this protocol to enable the
/// zero-argument ``ContainerInject`` initializer (`@Inject(\.property)`).
///
/// ```swift
/// final class AppContainer: Container, SharedContainer {
///     static var shared = AppContainer()
/// }
/// ```
///
/// The `shared` property is declared `{ get set }` so tests can swap the
/// container instance for a fresh one — see <doc:TestingWithForge> for details.
public protocol SharedContainer: AnyObject {
    static var shared: Self { get set }
}
