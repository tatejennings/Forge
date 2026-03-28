# ``Forge``

A lightweight, compile-time safe dependency injection framework for Swift.

## Overview

Forge makes dependency injection feel natural in Swift. Define a container, register
dependencies as computed properties, and inject them with a single line. No code
generation, no reflection, no third-party dependencies.

**Key capabilities:**

- **Scope management** — transient, singleton, and cached lifecycles via ``Scope``
- **Preview support** — provide mock factories that activate automatically in Xcode Previews
- **Testing overrides** — swap dependencies in tests with automatic cleanup
- **Modular architecture** — one container per module with clean cross-module proxying

```swift
final class AppContainer: Container, SharedContainer {
    static var shared = AppContainer()

    var authService: any AuthServiceProtocol {
        provide(.singleton, preview: { MockAuthService() }) {
            AuthService(network: self.networkClient)
        }
    }
}
```

## Topics

### Essentials

- <doc:GettingStarted>
- ``Container``
- ``Scope``

### Injection

- ``ContainerInject``
- ``SharedContainer``

### Testing

- <doc:TestingWithForge>
- ``OverrideBuilder``
- ``unimplemented(_:file:line:)``

### Architecture and Best Practices

- <doc:ModularArchitecture>
- <doc:SOLIDPrinciples>
- <doc:XcodePreviewSupport>
