/// A convenience typealias for injecting dependencies from ``AppContainer``.
///
/// This typealias enables zero-config injection using the framework's built-in
/// ``AppContainer``:
///
/// ```swift
/// extension AppContainer {
///     var authService: any AuthServiceProtocol {
///         provide(.singleton) { AuthService() }
///     }
/// }
///
/// class LoginViewModel {
///     @Inject(\.authService) private var authService
/// }
/// ```
///
/// For modular apps with per-module containers, shadow this typealias in your
/// module's container file:
///
/// ```swift
/// // FeatureAuth/AuthContainer.swift
/// typealias Inject<T> = ContainerInject<AuthContainer, T>
/// ```
///
/// The module-local typealias takes precedence over this framework-provided one.
public typealias Inject<T> = ContainerInject<AppContainer, T>
