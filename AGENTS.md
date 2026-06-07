# AGENTS.md

Instructions for AI coding agents (Cursor, Aider, Codex CLI, Sourcegraph Cody, etc.) working in a Swift project that uses the [Forge](https://github.com/tatejennings/Forge) dependency injection framework.

> Using Claude Code? Install the dedicated plugin for richer, context-aware support:
> `/plugin marketplace add tatejennings/Forge` then `/plugin install forge@forge-plugins`.

---

## What Forge is

Forge is a lightweight DI framework for Swift — compile-time-safe at the call site (KeyPaths + inferred types), with loud, fail-fast runtime checks underneath. Registration is a computed property on a `Container` subclass; injection is a `@Inject(\.keyPath)` property wrapper. No code generation. No reflection. No build phases.

```swift
import Forge

extension AppContainer {
    var authService: any AuthServiceProtocol {
        provide(.singleton) { AuthService(network: self.networkClient) }
    }
}

@Observable
final class LoginViewModel {
    @ObservationIgnored
    @Inject(\.authService) private var authService
}
```

## Non-negotiable rules

1. **Always return a protocol type from `provide`.** Concrete types cannot be overridden in tests or previews.
2. **One container per module.** An `AuthContainer` registers auth deps, not analytics.
3. **Feature modules never import other feature modules.** Use protocol modules and cross-module proxies (see "Modular apps" below).

## Scope selection

| Scope | Behavior | Use when |
|---|---|---|
| `.transient` (default) | New instance per resolution | Stateless services, per-screen ViewModels |
| `.singleton` | One instance for container lifetime | Network clients, databases, analytics |
| `.cached` | One instance until `resetCached()` | ViewModels that survive nav but can be refreshed |

`provide { ... }` and `provide(.transient) { ... }` are equivalent.

## Injection sites

- **Classes (ViewModels, services):** `@Inject(\.x)` works directly. Uses `mutating get` for lazy resolution.
- **SwiftUI Views:** `@Inject` doesn't work — Views are value types. Use `@State` with direct resolution:
  ```swift
  struct LoginView: View {
      @State private var viewModel = AppContainer.shared.loginViewModel
  }
  ```

## Preview support

Add a `preview:` factory to swap dependencies automatically inside `#Preview`:
```swift
var authService: any AuthServiceProtocol {
    provide(.singleton) { AuthService(network: self.networkClient) } preview: { MockAuthService() }
}
```
Add a preview factory for services that hit the network, disk, or other side effects. Skip for pure value-producing services.

## Testing

Use `withOverrides` — overrides are scoped to the closure and restored automatically, even on throw:

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
}
```

Never mutate `Container.shared` directly in test bodies — it persists across tests and causes order-dependent failures.

Reset helpers:
- `resetCached()` — clears `.cached` values only.
- `resetAll()` — clears all overrides AND all cached/singleton values.

## `unimplemented` — explicit contracts

`unimplemented(_:)` returns a value that crashes immediately if resolved. Use it for dependencies that MUST be overridden — most commonly cross-module proxies:

```swift
// In FeatureSearch — analytics is wired by the app target
var analytics: any AnalyticsProtocol {
    provide(.singleton) { unimplemented("analytics") } preview: { MockAnalytics() }
}
```

## Modular apps

For multi-module SPM workspaces, the pattern is:

1. **Per-module container** with `SharedContainer` and a local `Inject` typealias:
   ```swift
   typealias Inject<T> = ContainerInject<AuthContainer, T>

   final class AuthContainer: Container, SharedContainer {
       static let shared = AuthContainer()
       var authService: any AuthServiceProtocol {
           provide(.singleton) { AuthService() }
       }
   }
   ```

2. **Cross-module deps use `unimplemented` proxies** — feature modules declare the dep but don't import the implementation module.

3. **App target wires real implementations at launch** (composition root):
   ```swift
   func wireContainers() {
       let app = AppContainer.shared
       SearchContainer.shared.override(\.analytics) { app.analytics }
   }
   ```

Protocols live in a small `*Protocols` module that everyone can import without pulling in implementations.

## Common mistakes to avoid

- **Concrete return type on `provide`** — breaks override / mock substitution.
- **`.singleton` on a per-screen ViewModel** — state leaks across navigations. Use `.transient` or `.cached`.
- **Direct `.shared.override` in tests** without cleanup — use `withOverrides`.
- **Cross-module dep with `provide { Real() }` instead of `unimplemented`** — either won't compile, or silently runs the wrong code.
- **`@Inject` in a SwiftUI View** — Views are value types; use `@State` + direct resolution.
- **Feature module importing another feature module's implementation** — use protocol modules + cross-module proxies.

## What Forge does NOT support

Do not propose or expect:
- Weak-reference or TTL-based scopes
- Named/tagged registrations
- Decorator or middleware hooks
- Circular dependency detection
- Auto-wiring or reflection-based resolution
- Codegen or build phases

Forge is intentionally minimal. If a feature request implies one of these, suggest a manual pattern instead.

## Quick API reference

| Type / function | Purpose |
|---|---|
| `AppContainer` | Built-in ready-to-use container. Extend it with your dependencies. |
| `Container` | Base class. Subclass and add computed properties. |
| `SharedContainer` | Protocol that adds a stable `static let shared` instance (requirement is `{ get }`). |
| `@Inject(\.x)` | Property wrapper for lazy injection (classes only). |
| `ContainerInject<C, T>` | Underlying type — aliased per module via `typealias Inject<T> = ContainerInject<MyContainer, T>`. |
| `Scope` | Enum: `.transient`, `.singleton`, `.cached`. |
| `provide(_:_:preview:)` | Register / resolve a dependency. |
| `withOverrides(_:run:)` | Scoped overrides for tests. Sync + async variants. |
| `override(\.x) { ... }` | Add a single override. Use inside `withOverrides` builders. |
| `unimplemented(_:)` | Returns a value that crashes if resolved. For explicit test/wiring contracts. |
| `resetCached()` | Clear `.cached` values. |
| `resetAll()` | Clear all overrides + cached/singleton values. |
