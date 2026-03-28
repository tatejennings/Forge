/// A ready-to-use container provided by Forge for simple single-container apps.
///
/// Extend `AppContainer` to register your dependencies:
///
/// ```swift
/// extension AppContainer {
///     var authService: any AuthServiceProtocol {
///         provide(.singleton) { AuthService() }
///     }
///
///     var networkClient: any NetworkClientProtocol {
///         provide(.singleton) { URLSessionNetworkClient() }
///     }
/// }
/// ```
///
/// Then inject anywhere in your app using the framework-provided ``Inject`` typealias:
///
/// ```swift
/// class LoginViewModel {
///     @ObservationIgnored
///     @Inject(\.authService) var authService
/// }
/// ```
///
/// `AppContainer.shared` is automatically set as ``Forge/defaultContainer``
/// so no additional setup is required.
///
/// > Note: When using `@Inject` inside an `@Observable` class, mark the property
///   with `@ObservationIgnored` to prevent observation tracking on the injected wrapper.
///
/// > Tip: For modular SPM apps with multiple feature containers, create your own
///   container by subclassing ``Container``, conform to ``SharedContainer``, and use
///   a module-local `typealias Inject<T> = ContainerInject<YourContainer, T>`.
///   See <doc:ModularArchitecture>.
public final class AppContainer: Container, SharedContainer, @unchecked Sendable {
    nonisolated(unsafe) public static var shared = AppContainer()
}
