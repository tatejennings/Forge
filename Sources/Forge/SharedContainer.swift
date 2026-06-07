/// A container that provides a shared static instance for convenient access.
///
/// Conform your ``Container`` subclass to this protocol to enable the
/// zero-argument ``ContainerInject`` initializer (`@Inject(\.property)`).
///
/// ```swift
/// final class AppContainer: Container, SharedContainer {
///     static let shared = AppContainer()
/// }
/// ```
///
/// The `shared` instance is stable for the lifetime of the process — declare it
/// as a `let`. For test isolation, reset the shared container in place with
/// ``Container/resetAll()`` or scope substitutions with
/// ``OverridableContainer/withOverrides(_:run:)-3qdpl`` rather than swapping the
/// instance — see <doc:TestingWithForge>.
public protocol SharedContainer: AnyObject {
    static var shared: Self { get }
}
