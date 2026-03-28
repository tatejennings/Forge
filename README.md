![Swift](https://img.shields.io/badge/Swift-6.2%20%7C%206.1%20%7C%206.0%20%7C%205.10-F05138.svg?style=flat&logo=swift&logoColor=white)
![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-4A90D9.svg?style=flat)
![SPM](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg?style=flat)
[![Documentation](https://img.shields.io/badge/DocC-Documentation-blue.svg?style=flat)](https://tatejennings.github.io/forge/documentation/forge)

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

> For a complete walkthrough including your first container and injection, see the [Getting Started](https://tatejennings.github.io/forge/documentation/forge/gettingstarted) guide.

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

### 1. Define a Container

```swift
import Forge

typealias Inject<T> = ContainerInject<AppContainer, T>

final class AppContainer: Container, SharedContainer {
    static var shared = AppContainer()

    var networkClient: any NetworkClientProtocol {
        provide(.singleton) { URLSessionNetworkClient() }
    }

    var authService: any AuthServiceProtocol {
        provide(.singleton) { AuthService(network: self.networkClient) }
    }
}
```

The `typealias` gives you the clean `@Inject(\.property)` syntax throughout your module. See [`ContainerInject`](https://tatejennings.github.io/forge/documentation/forge/containerinject) for details on how lazy resolution works.

### 2. Inject Dependencies

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

Forge supports three lifecycle [scopes](https://tatejennings.github.io/forge/documentation/forge/scope):

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

> Full guide: [Xcode Preview Support](https://tatejennings.github.io/forge/documentation/forge/xcodepreviewsupport) — detection, caching behavior, and multiple preview variants.

Add a `preview:` factory to any dependency. When running in an Xcode Preview, Forge automatically uses the preview factory instead — no conditional compilation needed:

```swift
var authService: any AuthServiceProtocol {
    provide(.singleton, preview: { MockAuthService() }) {
        AuthService(network: self.networkClient)
    }
}
```

Every `#Preview` block will use the mock automatically. No setup required.

---

## Testing

> Full guide: [Testing with Forge](https://tatejennings.github.io/forge/documentation/forge/testingwithforge) — scoped overrides, container swap, `unimplemented`, and best practices.

Use `withOverrides` to swap dependencies for the duration of a test. Cleanup is automatic — overrides are restored when the closure exits, even if it throws:

```swift
@Test("Login calls auth service")
func loginCallsService() async throws {
    let mock = MockAuthService(shouldSucceed: true)

    try await AppContainer.shared.withOverrides {
        $0.override("authService") { mock }
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

Make test boundaries explicit. Any dependency not overridden in a test will loudly fail if called:

```swift
final class TestAppContainer: AppContainer {
    override var authService: any AuthServiceProtocol {
        provide { unimplemented("authService") }
    }
}
```

If `authService` is accidentally called without being overridden, the app crashes immediately with a clear message instead of silently executing live code.

---

## Cross-Module Dependencies

> Full guide: [Modular Architecture](https://tatejennings.github.io/forge/documentation/forge/modulararchitecture) — per-module containers, cross-module proxying, and the composition root pattern.

Feature modules should never import other feature modules directly. Instead, declare the dependency in your container with a safe default, and let the app target wire the real implementation at launch:

```swift
// In SearchModule — depends on analytics, but doesn't import the analytics module
final class SearchContainer: Container, SharedContainer {
    static var shared = SearchContainer()

    // Wired by the app target at startup via override
    var analytics: any AnalyticsProtocol {
        provide(.singleton) { MockAnalytics() }
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
    let core = CoreContainer.shared
    SearchContainer.shared.override("analytics") { core.analytics }
}
```

This keeps feature modules fully independent and testable in isolation.

---

## Best Practices

> See [SOLID Principles with Forge](https://tatejennings.github.io/forge/documentation/forge/solidprinciples) for the full rationale behind each practice.

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

> Browse the full [API documentation](https://tatejennings.github.io/forge/documentation/forge) on GitHub Pages.

| Type | Purpose |
|------|---------|
| [`Container`](https://tatejennings.github.io/forge/documentation/forge/container) | Base class for dependency containers. Subclass and add computed properties. |
| [`SharedContainer`](https://tatejennings.github.io/forge/documentation/forge/sharedcontainer) | Protocol that adds a `static var shared` for convenient `@Inject` syntax. |
| [`ContainerInject`](https://tatejennings.github.io/forge/documentation/forge/containerinject) | Property wrapper for lazy dependency injection. Aliased as `@Inject` per module. |
| [`Scope`](https://tatejennings.github.io/forge/documentation/forge/scope) | Enum: `.transient`, `.singleton`, `.cached` |
| [`OverrideBuilder`](https://tatejennings.github.io/forge/documentation/forge/overridebuilder) | Accumulates overrides for `withOverrides` closures. |
| [`unimplemented(_:)`](https://tatejennings.github.io/forge/documentation/forge/unimplemented(_:file:line:)) | Returns a value that `fatalError`s if ever called. For explicit test contracts. |

### Container Methods

| Method | Description |
|--------|-------------|
| [`provide(_:preview:key:_:)`](https://tatejennings.github.io/forge/documentation/forge/container/provide(_:preview:key:_:)) | Register and resolve a dependency with scope and optional preview factory. |
| [`withOverrides(_:run:)`](https://tatejennings.github.io/forge/documentation/forge/container) | Apply overrides for the duration of a closure (sync and async variants). |
| [`override(_:with:)`](https://tatejennings.github.io/forge/documentation/forge/container/override(_:with:)) | Register a replacement factory for a key. |
| [`removeOverride(for:)`](https://tatejennings.github.io/forge/documentation/forge/container/removeoverride(for:)) | Remove a single override. |
| [`resetAll()`](https://tatejennings.github.io/forge/documentation/forge/container/resetall()) | Remove all overrides and clear all cached/singleton values. |
| [`resetCached()`](https://tatejennings.github.io/forge/documentation/forge/container/resetcached()) | Clear cached-scope values only. Singletons and overrides are preserved. |

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
