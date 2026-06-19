---
name: using-forge
description: Use when reading, writing, or editing Swift code that imports Forge or uses @Inject, Container, SharedContainer, provide(...), AppContainer, or unimplemented(...). Provides Forge's core conventions for dependency registration, scope selection, injection, and preview support.
---

# Using Forge

Forge is a compile-time-safe dependency injection framework for Swift. Registration is a computed property on a `Container` subclass; injection is a `@Inject(\.keyPath)` property wrapper.

## Which path am I in? (decide this first)

Forge projects follow one of two paths. **Detect the path from the code before writing any — don't guess from the target count alone.** This is the single source of truth for the decision; other skills and `AGENTS.md` mirror it.

- **Modular** if ANY of these are present: a custom `final class XContainer: Container, SharedContainer`; a module-local `typealias Inject<T> = ContainerInject<XContainer, T>`; `unimplemented(...)` factories; or composition-root wiring (`XContainer.shared.override(\.y) { … }`). A Modular app *also* extends `AppContainer` (as its composition root holding the live implementations) — so **seeing an `AppContainer` extension does NOT mean Simple.**
- **Simple** if the ONLY registration site is `extension AppContainer { … }`, injection uses Forge's built-in `@Inject(\.x)`, and there are **no** custom `Container` subclasses, **no** module-local `Inject` typealias, and **no** `unimplemented()`.
- **Starting fresh?** Single target → Simple. Multi-module SPM → Modular.
- **Never mix:** `unimplemented()` and composition-root wiring are **Modular-only**. In a Simple app, register the real implementation directly — never introduce a proxy or a `wireContainers()` step. For the full Modular pattern, see the `forge-modular` skill.

## Core rules (non-negotiable)

1. **Always return a protocol type from `provide`.** Concrete return types cannot be overridden in tests or previews.
   ```swift
   // ✅ Good
   var authService: any AuthServiceProtocol {
       provide(.singleton) { AuthService(network: self.networkClient) }
   }
   // ❌ Bad — can't substitute a mock
   var authService: AuthService {
       provide(.singleton) { AuthService(network: self.networkClient) }
   }
   ```

2. **One container per module.** An `AuthContainer` registers auth dependencies, not analytics. For single-target (Simple) apps, extend the built-in `AppContainer` instead — see "Which path am I in?" above.

3. **Keep protocols narrow.** A `NetworkClientProtocol` does not also carry auth methods. Split concerns into separate protocols and separate registrations.

## Two setup styles

### Simple — extend `AppContainer`
For single-target apps. No container class, no typealias, no setup code.
```swift
import Forge

extension AppContainer {
    var networkClient: any NetworkClientProtocol {
        provide(.singleton) { URLSessionNetworkClient() }
    }
}

@Observable
final class LoginViewModel {
    @ObservationIgnored
    @Inject(\.networkClient) private var network
}
```

### Custom — your own container
For multi-module apps (see `forge-modular` skill for the full pattern):
```swift
typealias Inject<T> = ContainerInject<AuthContainer, T>

final class AuthContainer: Container, SharedContainer {
    static let shared = AuthContainer()

    var authService: any AuthServiceProtocol {
        provide(.singleton) { AuthService() }
    }
}
```

The local `typealias` shadows Forge's framework-level `Inject` so `@Inject(\.x)` resolves from your module's container.

## Scopes — choose deliberately

| Scope | Behavior | Use when |
|---|---|---|
| `.transient` (default) | New instance every resolution | Stateless services, ViewModels created per-sheet/per-presentation |
| `.singleton` | One instance for container lifetime | Database connections, network clients, analytics |
| `.cached` | One instance until `resetCached()` | ViewModels that survive tab switches but can be refreshed |

Default is `.transient`. `provide { ... }` and `provide(.transient) { ... }` are equivalent.

Common mistake: using `.singleton` for a per-screen ViewModel. If the ViewModel holds screen-local state, it should be `.transient` (new per presentation) or `.cached` (survives navigation but resettable).

## `@Inject` in classes vs SwiftUI Views

- **Classes (ViewModels, services):** `@Inject` works directly. It uses a `mutating get` for lazy resolution.
- **SwiftUI Views:** `@Inject` doesn't work — Views are value types. Use `@State` with direct resolution:
  ```swift
  struct LoginView: View {
      @State private var viewModel = AppContainer.shared.loginViewModel
  }
  ```

## Preview factories

Add a `preview:` factory to swap dependencies automatically inside `#Preview`. No conditional compilation needed.
```swift
var authService: any AuthServiceProtocol {
    provide(.singleton) {
        AuthService(network: self.networkClient)
    } preview: {
        MockAuthService()
    }
}
```

When to add a preview factory:
- Services that hit the network, disk, or other side effects.
- Anything that would crash, hang, or produce noise in a preview.

Skip the preview factory for pure value-producing services that are safe to construct in a preview.

## `unimplemented` — explicit contracts (Modular-only)

`unimplemented(_:)` returns a value that crashes immediately if resolved. It exists for **cross-module proxies** in the Modular path — dependencies a feature module declares but cannot construct, which the app target's composition root **must** wire at startup:
```swift
var analytics: any AnalyticsProtocol {
    provide(.singleton) { unimplemented("analytics") } preview: { MockAnalytics() }
}
```

It surfaces missing wiring as an immediate, clear crash instead of silent wrong behavior. See the `forge-modular` skill for the full pattern.

**Do not use `unimplemented()` in a Simple (single-`AppContainer`) app.** There is no other module to wire it from — register the real implementation directly in your `AppContainer` extension.

## What Forge does NOT support

Do not propose or expect:
- Weak-reference or TTL-based scopes
- Named/tagged registrations (no string keys exposed to the user)
- Decorator or middleware hooks
- Circular dependency detection
- Auto-wiring or reflection-based resolution
- Codegen or build phases

Forge is intentionally minimal. If a feature request implies one of these, push back and suggest a manual pattern instead.

## Related skills

- `forge-testing` — `withOverrides`, `override(\.x)`, test containers
- `forge-modular` — multi-module setup, cross-module proxies, composition root
- `forge-migration` — adopting Forge in an existing app
