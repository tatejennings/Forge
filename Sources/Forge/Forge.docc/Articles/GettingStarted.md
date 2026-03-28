# Getting Started with Forge

Install Forge and register your first dependencies.

## Overview

Forge is a lightweight dependency injection framework for Swift. This guide walks you
through installation, creating your first container, and injecting dependencies into
your code.

## Installation

Add Forge to your project via Swift Package Manager. In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/tatejennings/forge.git", from: "0.1.0")
]
```

Then add `Forge` to your target's dependencies:

```swift
.target(name: "MyApp", dependencies: ["Forge"])
```

Or add it via Xcode: **File > Add Packages**, enter the repository URL, and add
`Forge` to your target.

## Define a Container

Create a container by subclassing ``Container`` and conforming to ``SharedContainer``.
Register dependencies as computed properties that call ``Container/provide(_:preview:key:_:)``:

```swift
import Forge

// The module-local typealias goes in the container file
typealias Inject<T> = ContainerInject<AppContainer, T>

final class AppContainer: Container, SharedContainer {
    static var shared = AppContainer()

    var networkClient: any NetworkClientProtocol {
        provide(.singleton) { URLSessionNetworkClient() }
    }

    var authService: any AuthServiceProtocol {
        provide(.singleton, preview: { MockAuthService() }) {
            AuthService(network: self.networkClient)
        }
    }

    var tokenStorage: any TokenStorageProtocol {
        provide { KeychainTokenStorage() }
    }
}
```

### The Module-Local Typealias

The `typealias Inject<T> = ContainerInject<AppContainer, T>` line is placed **in the
container file itself** — not in a separate file. This typealias is the only place
where your container type name appears at injection call sites, keeping them clean:

```swift
@Inject(\.authService) private var auth
```

If you later rename or refactor the container, only the typealias needs updating.

## Choose a Scope

Every dependency has a lifecycle controlled by ``Scope``:

| Scope | Behavior |
| --- | --- |
| `.transient` | New instance every time (default) |
| `.singleton` | One instance for the container's lifetime |
| `.cached` | One instance until ``Container/resetCached()`` is called |

```swift
var logger: any LoggerProtocol {
    provide(.transient) { ConsoleLogger() }   // Fresh each time
}

var database: any DatabaseProtocol {
    provide(.singleton) { SQLiteDatabase() }  // Lives forever
}

var session: any SessionProtocol {
    provide(.cached) { UserSession() }        // Resettable
}
```

## Inject Dependencies

### In classes (ViewModels, services)

Use `@Inject` with a key path to the container property:

```swift
final class LoginViewModel: ObservableObject {
    @Inject(\.authService) private var authService
    @Inject(\.tokenStorage) private var tokens

    func login(username: String, password: String) async {
        let user = try? await authService.login(
            username: username,
            password: password
        )
    }
}
```

Resolution is **lazy** — the dependency is resolved on first access of the property,
not when the object is created. This ensures overrides set after initialization
(common in tests) are picked up correctly.

### In SwiftUI views

``ContainerInject`` uses a `mutating get`, which doesn't work directly in SwiftUI
view structs. Instead, resolve directly from the container:

```swift
struct LoginView: View {
    @State private var viewModel = AppContainer.shared.loginViewModel

    var body: some View {
        // use viewModel...
    }
}
```

### Inline resolution

You can also resolve dependencies directly without the property wrapper:

```swift
let service = AppContainer.shared.authService
```

## Next Steps

- <doc:ModularArchitecture> — organize containers across multiple modules
- <doc:TestingWithForge> — mock dependencies in tests
- <doc:XcodePreviewSupport> — provide preview-safe factories
