---
name: forge-modular
description: Use when working in a multi-module SPM workspace or Xcode project that uses Forge, or when editing a per-module Container or the app target's composition root. Covers per-module containers, cross-module dependency proxying with unimplemented(), and the composition-root wiring pattern.
---

# Forge Modular Architecture

**First, confirm this project is actually Modular** (see the decision rule in the `using-forge` skill): there must be custom per-module containers, module-local `Inject` typealiases, `unimplemented()` proxies, or composition-root wiring. If the only registration site is `extension AppContainer { … }` with no custom containers, this is a **Simple** app — stop and use `using-forge` instead. Do not introduce the machinery below into a Simple app.

The core rule: **feature modules never import other feature modules.** They import protocol modules. The app target is the only composition root — the only place that imports concrete modules and wires them together.

## Per-module container

Each feature module owns one `Container` subclass with the `SharedContainer` protocol and a local `Inject` typealias:

```swift
// In FeatureAuth module
import Forge

typealias Inject<T> = ContainerInject<AuthContainer, T>

final class AuthContainer: Container, SharedContainer {
    static let shared = AuthContainer()

    var authService: any AuthServiceProtocol {
        provide(.singleton) { AuthService(network: self.networkClient) }
    }

    var networkClient: any NetworkClientProtocol {
        provide(.singleton) { URLSessionNetworkClient() }
    }
}
```

The local `typealias` shadows Forge's framework-level `Inject` so `@Inject(\.authService)` resolves from `AuthContainer.shared`.

## Cross-module dependencies — use `unimplemented` proxies

When a feature module depends on something it can't construct (e.g., analytics, logged-in user, feature flags), declare the dependency in the module's container with `unimplemented(...)` as the default factory:

```swift
// In FeatureSearch — depends on analytics, but FeatureSearch does NOT import FeatureAnalytics
final class SearchContainer: Container, SharedContainer {
    static let shared = SearchContainer()

    // Wired by the app target at startup
    var analytics: any AnalyticsProtocol {
        provide(.singleton) { unimplemented("analytics") } preview: { MockAnalytics() }
    }

    var searchService: any SearchServiceProtocol {
        provide(.singleton) { SearchService(analytics: self.analytics) }
    }
}
```

Notice:
- The factory is `unimplemented("analytics")` — if the app forgets to wire it, the app crashes on first resolution with a clear message naming the missing dependency.
- A `preview:` factory provides a mock so previews still work.
- `FeatureSearch` does not import `FeatureAnalytics`. It only knows about `AnalyticsProtocol` (which lives in a small protocol module both can import).

## Composition root — the app target wires everything

The app target is the ONLY place that imports both modules. It overrides each cross-module proxy with the real implementation:

```swift
// In MyApp (the app target)
import FeatureAuth
import FeatureSearch
import FeatureAnalytics

@main
struct MyApp: App {
    init() {
        wireContainers()
    }

    var body: some Scene { ... }
}

private func wireContainers() {
    let app = AppContainer.shared  // or wherever the canonical analytics lives
    SearchContainer.shared.override(\.analytics) { app.analytics }
    AuthContainer.shared.override(\.analytics) { app.analytics }
}
```

This pattern keeps each feature module:
- Independently buildable (no cross-feature imports)
- Independently testable (override the proxy with a mock)
- Independently previewable (the `preview:` factory handles it)

## Protocol modules

For the pattern to work, protocols must live in a module both the producer and consumer can import. Common shape:

```
Workspace/
├── AnalyticsProtocols/          # public protocol(s), no implementations
│   └── AnalyticsProtocol.swift
├── FeatureAnalytics/             # imports AnalyticsProtocols, implements
├── FeatureSearch/                # imports AnalyticsProtocols, NOT FeatureAnalytics
└── MyApp/                        # imports everything, composition root
```

`AnalyticsProtocols` has no Forge dependency — it's pure protocol declarations.

## Common mistakes

- **Feature module imports another feature module.** This is the cardinal sin. If you find yourself adding `import FeatureX` in `FeatureY`, you need a protocol module instead.
- **Composition root forgets to wire a proxy.** Caught by `unimplemented()` — but only at runtime. If you add a new cross-module proxy, immediately add the matching `override` in the app target. The `/forge:wire-modules` slash command helps.
- **Using `provide { ... }` without a default for a cross-module dep.** Without `unimplemented`, the factory will be called with no real implementation, often producing silent wrong behavior (a no-op analytics, an empty network client). Always wrap cross-module proxies in `unimplemented`.
- **Per-module container imports app-level types.** Containers should only know about their own module's protocols. Wiring lives in the app target, not in the module's container.

## Testing per-module containers

In a feature module's tests, override the proxies with mocks via `withOverrides` (see `forge-testing` skill). You can test the feature module fully isolated from the rest of the app.

```swift
try await SearchContainer.shared.withOverrides {
    $0.override(\.analytics) { MockAnalytics() }
} run: {
    let result = await SearchContainer.shared.searchService.search("query")
    #expect(result.count > 0)
}
```

## Related skills

- `using-forge` — registration and injection basics
- `forge-testing` — overriding in tests
- `forge-migration` — refactoring an existing modular app to Forge
