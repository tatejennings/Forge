![Swift](https://img.shields.io/badge/Swift-6.2%20%7C%206.1%20%7C%206.0%20%7C%205.10-F05138.svg?style=flat&logo=swift&logoColor=white)
![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-4A90D9.svg?style=flat)
![SPM](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg?style=flat)
[![Documentation](https://img.shields.io/badge/DocC-Documentation-blue.svg?style=flat)](https://tatejennings.github.io/Forge/documentation/forge)

![Forge](.github/forge_logo.png)

A lightweight, compile-time safe dependency injection framework for Swift.

Forge makes dependency injection feel natural in Swift — minimal boilerplate, no magic, just clean code. Define a container, register dependencies as computed properties, and inject them with a single line. No code generation, no reflection, no third-party dependencies.

---

## Why Forge?

Most DI frameworks in Swift are either too heavy (requiring code generation and build phases) or too magical (relying on reflection and runtime registration). Forge takes a different approach:

- **One line to register** a dependency
- **One line to inject** a dependency
- **One line to mock** for tests
- **One line to preview** in Xcode Previews
- **Zero** external dependencies, build plugins, or generated code

---

## Installation

> For a complete walkthrough including your first container and injection, see the [Getting Started](https://tatejennings.github.io/Forge/documentation/forge/gettingstarted) guide.

Add Forge to your project via Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/tatejennings/forge.git", from: "0.1.0")
]
```

Then add `Forge` to your target's dependencies:

```swift
.target(name: "MyApp", dependencies: ["Forge"])
```

---

## Quick Start

### Simple Setup (zero config)

Extend Forge's built-in `AppContainer` with your dependencies and inject them immediately — no container class, no typealias, no setup code:

```swift
import Forge

// 1. Extend AppContainer with your dependencies
extension AppContainer {
    var networkClient: any NetworkClientProtocol {
        provide(.singleton) { URLSessionNetworkClient() }
    }

    var authService: any AuthServiceProtocol {
        provide(.singleton) { AuthService(network: self.networkClient) }
    }
}

// 2. Inject anywhere — that's it
@Observable
final class LoginViewModel {
    @ObservationIgnored
    @Inject(\.authService) private var authService

    func login(username: String, password: String) async {
        try? await authService.login(username: username, password: password)
    }
}
```

No `App.init()`. No `Forge.defaultContainer = ...`. No typealias. Just extend and inject.

### Modular Setup (per-module containers)

For multi-module SPM apps, create a container per module and add a local `typealias` that shadows the framework's `Inject`:

```swift
import Forge

typealias Inject<T> = ContainerInject<AuthContainer, T>

final class AuthContainer: Container, SharedContainer {
    static var shared = AuthContainer()

    var networkClient: any NetworkClientProtocol {
        provide(.singleton) { URLSessionNetworkClient() }
    }

    var authService: any AuthServiceProtocol {
        provide(.singleton) { AuthService(network: self.networkClient) }
    }
}
```

The `typealias` shadows Forge's built-in `Inject` so `@Inject(\.property)` resolves from your module's container. See [`ContainerInject`](https://tatejennings.github.io/Forge/documentation/forge/containerinject) for details on how lazy resolution works.

### Inject Dependencies

```swift
@Observable
final class LoginViewModel {
    @ObservationIgnored
    @Inject(\.authService) private var authService

    func login(username: String, password: String) async {
        try? await authService.login(username: username, password: password)
    }
}
```

> **Note:** `@Inject` uses a `mutating get` for lazy resolution, which works in classes (ViewModels, services). In SwiftUI Views, use `@State` with direct container resolution instead: `@State private var viewModel = AppContainer.shared.myViewModel`

That's it. No registration ceremony, no service locator, no runtime errors.

---

## Scopes

Forge supports three lifecycle [scopes](https://tatejennings.github.io/Forge/documentation/forge/scope):

```swift
// New instance every time (default)
var analytics: any AnalyticsProtocol {
    provide(.transient) { AnalyticsService() }
}

// One instance for the lifetime of the container
var database: any DatabaseProtocol {
    provide(.singleton) { SQLiteDatabase() }
}

// One instance until explicitly reset via container.resetCached()
var viewModel: TaskListViewModel {
    provide(.cached) { TaskListViewModel() }
}
```

| Scope | Behavior | Use When |
|-------|----------|----------|
| `.transient` | New instance per resolution | Stateless services, ViewModels for sheets |
| `.singleton` | Created once, lives forever | Database connections, network clients |
| `.cached` | Created once, resettable | ViewModels that survive tab switches but can be refreshed |

---

## Xcode Preview Support

> Full guide: [Xcode Preview Support](https://tatejennings.github.io/Forge/documentation/forge/xcodepreviewsupport) — detection, caching behavior, and multiple preview variants.

Add a `preview:` factory to any dependency. When running in an Xcode Preview, Forge automatically uses the preview factory instead — no conditional compilation needed:

```swift
var authService: any AuthServiceProtocol {
    provide(.singleton) {
        AuthService(network: self.networkClient)
    } preview: {
        MockAuthService()
    }
}
```

Every `#Preview` block will use the mock automatically. No setup required.

---

## Testing

> Full guide: [Testing with Forge](https://tatejennings.github.io/Forge/documentation/forge/testingwithforge) — scoped overrides, container swap, `unimplemented`, and best practices.

Use `withOverrides` to swap dependencies for the duration of a test. Cleanup is automatic — overrides are restored when the closure exits, even if it throws:

```swift
@Test("Login calls auth service")
func loginCallsService() async throws {
    let mock = MockAuthService(shouldSucceed: true)

    try await AppContainer.shared.withOverrides {
        $0.override(\.authService) { mock }
    } run: {
        let viewModel = LoginViewModel()
        await viewModel.login(username: "user", password: "pass")
        #expect(mock.loginCalled)
    }
    // overrides are automatically restored here
}
```

Need a completely fresh container with no cached singletons? Call `resetAll()`:

```swift
AppContainer.shared.resetAll()
```

---

## The `unimplemented` Helper

Make dependency contracts explicit. Any dependency marked as `unimplemented` will crash immediately if resolved without being overridden — instead of silently running the wrong code.

**Cross-module proxies** — feature modules that depend on services wired by the app target should use `unimplemented` as the default factory. If the composition root forgets to wire the dependency, the app crashes on launch with a clear message:

```swift
// In FeatureSearch — analytics is wired by the app target
var analytics: any AnalyticsProtocol {
    provide(.singleton) {
        unimplemented("analytics")
    } preview: {
        MockAnalytics()
    }
}
```

**Test containers** — ensure any dependency not explicitly overridden in a test fails loudly if called:

```swift
final class TestAuthContainer: AuthContainer {
    override var authService: any AuthServiceProtocol {
        provide { unimplemented("authService") }
    }
}
```

---

## Cross-Module Dependencies

> Full guide: [Modular Architecture](https://tatejennings.github.io/Forge/documentation/forge/modulararchitecture) — per-module containers, cross-module proxying, and the composition root pattern.

Feature modules should never import other feature modules directly. Instead, declare the dependency in your container with a safe default, and let the app target wire the real implementation at launch:

```swift
// In SearchModule — depends on analytics, but doesn't import the analytics module
final class SearchContainer: Container, SharedContainer {
    static var shared = SearchContainer()

    // Wired by the app target at startup via override
    var analytics: any AnalyticsProtocol {
        provide(.singleton) { unimplemented("analytics") }
    }

    var searchService: any SearchServiceProtocol {
        provide(.singleton) { SearchService(analytics: self.analytics) }
    }
}
```

The app target is the **composition root** — it's the only place that imports both modules and wires them together:

```swift
// In your App's init()
func wireContainers() {
    let app = AppContainer.shared
    SearchContainer.shared.override(\.analytics) { app.analytics }
}
```

This keeps feature modules fully independent and testable in isolation.

---

## Best Practices

> See [SOLID Principles with Forge](https://tatejennings.github.io/Forge/documentation/forge/solidprinciples) for the full rationale behind each practice.

**Always use protocol return types** on container properties. This is what makes mock substitution work:

```swift
// Good — protocol return type allows mock substitution
var authService: any AuthServiceProtocol {
    provide(.singleton) { AuthService() }
}

// Bad — concrete return type can't be overridden with a mock
var authService: AuthService {
    provide(.singleton) { AuthService() }
}
```

**Keep containers module-scoped.** One container per module. An `AuthContainer` should not register analytics services.

**Keep protocols narrow.** A `NetworkClientProtocol` should not carry authentication methods. Separate concerns into separate protocols and separate container registrations.

**Never import concrete modules from feature modules.** Feature modules depend on protocol modules. The app target is the only composition root that imports both.

---

## API Reference

> Browse the full [API documentation](https://tatejennings.github.io/Forge/documentation/forge) on GitHub Pages.

| Type | Purpose |
|------|---------|
| [`AppContainer`](https://tatejennings.github.io/Forge/documentation/forge/appcontainer) | Built-in ready-to-use container. Extend it with your dependencies for zero-config injection. |
| [`Inject`](https://tatejennings.github.io/Forge/documentation/forge/inject) | Framework-provided typealias for `ContainerInject<AppContainer, T>`. Shadow it in modules with custom containers. |
| [`Forge`](https://tatejennings.github.io/Forge/documentation/forge/forge-swift.forge) | Namespace enum. Access `Forge.defaultContainer` for programmatic resolution. |
| [`Container`](https://tatejennings.github.io/Forge/documentation/forge/container) | Base class for dependency containers. Subclass and add computed properties. |
| [`SharedContainer`](https://tatejennings.github.io/Forge/documentation/forge/sharedcontainer) | Protocol that adds a `static var shared` for convenient `@Inject` syntax. |
| [`ContainerInject`](https://tatejennings.github.io/Forge/documentation/forge/containerinject) | Property wrapper for lazy dependency injection. Aliased as `@Inject` per module. |
| [`Scope`](https://tatejennings.github.io/Forge/documentation/forge/scope) | Enum: `.transient`, `.singleton`, `.cached` |
| [`OverrideBuilder`](https://tatejennings.github.io/Forge/documentation/forge/overridebuilder) | Accumulates overrides for `withOverrides` closures. |
| [`unimplemented(_:)`](https://tatejennings.github.io/Forge/documentation/forge/unimplemented(_:file:line:)) | Returns a value that `fatalError`s if ever called. For explicit test contracts. |

### Container Methods

| Method | Description |
|--------|-------------|
| [`provide(_:key:_:preview:)`](https://tatejennings.github.io/Forge/documentation/forge/container/provide(_:key:_:preview:)) | Register and resolve a dependency with scope and optional preview factory. |
| [`withOverrides(_:run:)`](https://tatejennings.github.io/Forge/documentation/forge/container) | Apply overrides for the duration of a closure (sync and async variants). |
| [`override(_:with:)`](https://tatejennings.github.io/Forge/documentation/forge/container/override(_:with:)) | Register a KeyPath-based replacement factory. |
| [`removeOverride(for:)`](https://tatejennings.github.io/Forge/documentation/forge/container/removeoverride(for:)) | Remove a single override by KeyPath. |
| [`resetAll()`](https://tatejennings.github.io/Forge/documentation/forge/container/resetall()) | Remove all overrides and clear all cached/singleton values. |
| [`resetCached()`](https://tatejennings.github.io/Forge/documentation/forge/container/resetcached()) | Clear cached-scope values only. Singletons and overrides are preserved. |

---

## Requirements

| Requirement | Minimum |
|-------------|---------|
| Swift | 5.10 |
| iOS | 16.0 |
| macOS | 13.0 |
| tvOS | 16.0 |
| watchOS | 9.0 |
| Xcode | 15.3 |

---

## What Forge Is Not

Forge intentionally does **not** include:

- Weak-reference or TTL-based scopes
- Named/tagged registrations
- Decorator or middleware hooks
- Circular dependency detection
- Auto-wiring or reflection-based resolution
- Objective-C compatibility
- Code generation or build phases

These are excluded by design, not oversight. Forge is minimal on purpose.

---

## License

MIT
