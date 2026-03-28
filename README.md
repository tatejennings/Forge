![Swift](https://img.shields.io/badge/Swift-6.2%20%7C%206.1%20%7C%206.0%20%7C%205.10-F05138.svg?style=flat&logo=swift&logoColor=white)
![Platforms](https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS%20%7C%20tvOS%20%7C%20watchOS%20%7C%20visionOS-4A90D9.svg?style=flat)
![SPM](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg?style=flat)

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

The `typealias` gives you the clean `@Inject(\.property)` syntax throughout your module.

### 2. Inject Dependencies

```swift
final class LoginViewModel: ObservableObject {
    @Inject(\.authService) private var authService

    func login(username: String, password: String) async {
        try? await authService.login(username: username, password: password)
    }
}
```

That's it. No registration ceremony, no service locator, no runtime errors.

---

## Scopes

Forge supports three lifecycle scopes:

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

### Scoped Overrides (preferred)

Override dependencies for the duration of a test closure. Cleanup is automatic:

```swift
func testLoginSuccess() async throws {
    let mock = MockAuthService(shouldSucceed: true)

    try await AppContainer.shared.withOverrides {
        $0.override("authService") { mock }
    } run: {
        let viewModel = LoginViewModel()
        await viewModel.login(username: "user", password: "pass")
        XCTAssertTrue(mock.loginCalled)
    }
    // overrides are automatically restored here
}
```

### Container Swap (for full test isolation)

Create a fresh container per test class:

```swift
final class LoginTests: XCTestCase {
    override func setUp() {
        AppContainer.shared = AppContainer()
    }

    override func tearDown() {
        AppContainer.shared = AppContainer()
    }
}
```

### Direct Overrides (for setUp/tearDown patterns)

```swift
override func setUp() {
    AppContainer.shared.override("authService") { MockAuthService() }
}

override func tearDown() {
    AppContainer.shared.resetAll()
}
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

If `authService` is accidentally called without being overridden, the test fails immediately with a clear message instead of silently executing live code.

---

## Cross-Module Dependencies

Feature modules should never import other feature modules. Proxy dependencies through your own container:

```swift
// In SearchModule — proxies analytics from CoreModule
final class SearchContainer: Container, SharedContainer {
    static var shared = SearchContainer()

    var analytics: any AnalyticsProtocol {
        provide { CoreAnalyticsContainer.shared.analytics }
    }

    var searchService: any SearchServiceProtocol {
        provide(.singleton) { SearchService(analytics: self.analytics) }
    }
}
```

The app target wires the real implementations at launch:

```swift
// In your App's init()
SearchContainer.shared.override("analytics") { CoreContainer.shared.analytics }
```

---

## Best Practices

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

**Keep containers module-scoped.** One container per module, one `DI.swift` per module. An `AuthContainer` should not register analytics services.

**Keep protocols narrow.** A `NetworkClientProtocol` should not carry authentication methods. Separate concerns into separate protocols and separate container registrations.

**Never import concrete modules from feature modules.** Feature modules depend on protocol modules. The app target is the only composition root that imports both.

---

## API Reference

| Type | Purpose |
|------|---------|
| `Container` | Base class for dependency containers. Subclass and add computed properties. |
| `SharedContainer` | Protocol that adds a `static var shared` for convenient `@Inject` syntax. |
| `ContainerInject` | Property wrapper for lazy dependency injection. Aliased as `@Inject` per module. |
| `Scope` | Enum: `.transient`, `.singleton`, `.cached` |
| `OverrideBuilder` | Accumulates overrides for `withOverrides` closures. |
| `unimplemented(_:)` | Returns a value that `fatalError`s if ever called. For explicit test contracts. |

### Container Methods

| Method | Description |
|--------|-------------|
| `provide(_:preview:key:_:)` | Register and resolve a dependency with scope and optional preview factory. |
| `withOverrides(_:run:)` | Apply overrides for the duration of a closure (sync and async variants). |
| `override(_:with:)` | Register a replacement factory for a key. |
| `removeOverride(for:)` | Remove a single override. |
| `resetAll()` | Remove all overrides and clear all cached/singleton values. |
| `resetCached()` | Clear cached-scope values only. Singletons and overrides are preserved. |

---

## Requirements

| Requirement | Minimum |
|-------------|---------|
| Swift | 5.10 |
| iOS | 16.0 |
| macOS | 13.0 |
| tvOS | 16.0 |
| watchOS | 9.0 |
| Xcode | 16.0 |

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
