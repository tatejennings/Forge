# SOLID Principles with Forge

How each SOLID principle maps to Forge usage, with practical Swift examples.

## Overview

Forge is designed to make SOLID principles the path of least resistance. Each
principle applies to both the framework's internal design and how you structure
your own code when using it.

## Single Responsibility Principle

> Each type should have one reason to change.

**In the framework:** Every Forge type does one thing — ``Container`` manages
lifecycle and resolution, ``Scope`` describes caching behavior,
``ContainerInject`` handles injection, ``OverrideBuilder`` handles test
configuration.

**In your code:** Each container should own dependencies for exactly one module.
If a container grows beyond its module's concerns, that signals the module has
too many responsibilities.

```swift
// Correct: one container per module
final class AuthContainer: Container, SharedContainer {
    static var shared = AuthContainer()

    var authService: any AuthServiceProtocol {
        provide(.singleton) { AuthService() }
    }
}

final class AnalyticsContainer: Container, SharedContainer {
    static var shared = AnalyticsContainer()

    var tracker: any AnalyticsTrackerProtocol {
        provide(.singleton) { MixpanelTracker() }
    }
}
```

## Open/Closed Principle

> Open for extension, closed for modification.

**In the framework:** ``Container`` is an `open class`. New containers extend it
by adding computed properties — you never modify the base class.

**In your code:** Change behavior by overriding at the container boundary, not by
modifying implementation types. A test that needs different behavior provides a
different factory:

```swift
// Correct: extend at the container boundary
try await AuthContainer.shared.withOverrides {
    $0.override("authService") { MockAuthService() }
} run: {
    // test code...
}

// Incorrect: adding test flags inside production types
class AuthService {
    var isTesting = false  // Don't do this
}
```

## Liskov Substitution Principle

> Subtypes must be substitutable for their base types.

**In the framework:** ``Container`` subclasses are always valid containers. The
base class API works identically on any subclass.

**In your code:** Always declare container properties using protocol return types.
This is what makes mocks substitutable for live implementations:

```swift
// Correct: protocol return type — mock is substitutable
public var authService: any AuthServiceProtocol {
    provide(.singleton) { AuthService() }
}

// Incorrect: concrete type — cannot substitute a mock
public var authService: AuthService {
    provide(.singleton) { AuthService() }
}
```

When the return type is a protocol, any conforming type — live or mock — can be
swapped in without changing consuming code.

## Interface Segregation Principle

> Clients should not depend on interfaces they do not use.

**In the framework:** ``SharedContainer`` is a minimal protocol with a single
requirement (`static var shared`). ``Container`` does not conform to it by
default — you opt in only when you need the zero-argument `@Inject` syntax.

**In your code:** Define narrow protocols for each dependency. A
`NetworkClientProtocol` should not carry authentication methods just because the
networking layer also handles auth:

```swift
// Correct: narrow protocols
protocol NetworkClientProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

protocol AuthTokenProviderProtocol {
    var currentToken: String? { get }
}

// Incorrect: fat protocol
protocol NetworkClientProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    var currentToken: String? { get }   // Not a networking concern
    func logout()                        // Definitely not networking
}
```

## Dependency Inversion Principle

> High-level modules should not depend on low-level modules. Both should depend
> on abstractions.

**This is Forge's entire purpose.** The container is the composition root — the
only place where abstractions are wired to concrete implementations. Everything
above it (ViewModels, services) depends only on protocols. Everything below it
(concrete implementations) knows nothing about the container.

```
CoreProtocols (protocols only — no Forge import)
       ^
       |
Feature modules (depend on protocols, use Forge for wiring)
       ^
       |
App target (imports both, wires at startup)
```

ViewModels and services never `import` a concrete implementation module directly.
They inject via protocol. The container handles the wiring:

```swift
// ViewModel depends only on the protocol
final class LoginViewModel: ObservableObject {
    @Inject(\.authService) private var authService
    // LoginViewModel has no idea what AuthService is —
    // it only knows AuthServiceProtocol
}
```

## Summary

| Principle | Forge Pattern |
| --- | --- |
| Single Responsibility | One container per module |
| Open/Closed | Override at the container, don't modify types |
| Liskov Substitution | Protocol return types on all properties |
| Interface Segregation | Narrow protocols, opt-in `SharedContainer` |
| Dependency Inversion | Container is the composition root |
