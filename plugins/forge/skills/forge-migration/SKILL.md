---
name: forge-migration
description: Use when migrating an existing Swift app to Forge from another dependency injection pattern — manual constructor injection, Factory (hmlongco/Factory), or service-locator / .shared singletons. Covers the migration playbook and when to invoke the forge-migrator subagent for larger jobs.
---

# Migrating to Forge

The migration playbook is the same regardless of source pattern, with small variations. For larger codebases (more than ~10 dependencies, or multiple modules), invoke the **`forge-migrator`** subagent — it plans and applies the migration incrementally in an isolated context. For single-file or small migrations, do it directly in this conversation.

## The playbook (universal)

1. **Add Forge as a dependency.** SPM: add `https://github.com/tatejennings/Forge.git` to `Package.swift`.
2. **Introduce protocols** for any concrete type that needs to be substitutable in tests or previews. If a type is already protocol-fronted, skip.
3. **Choose a container layout:**
   - Single target → extend `AppContainer`.
   - Multi-module → one container per module + composition root in the app target (see `forge-modular`).
4. **Register dependencies** as computed properties on the container, using the right scope (see `using-forge`).
5. **Replace injection sites** with `@Inject(\.x)`.
6. **Backfill tests** to use `withOverrides` (see `forge-testing`).
7. **Run tests.** Then delete the old DI plumbing.

## Source pattern: manual constructor injection

Existing code:
```swift
final class LoginViewModel {
    private let auth: AuthService
    init(auth: AuthService = AuthService(network: URLSessionNetworkClient())) {
        self.auth = auth
    }
}
```

Migration steps:
- Extract `AuthServiceProtocol` if it doesn't exist.
- Register `authService` and `networkClient` in `AppContainer`.
- Replace the init parameter with `@Inject(\.authService)`.

After:
```swift
final class LoginViewModel {
    @Inject(\.authService) private var auth
}
```

Bonus: the default-value chain disappears, simplifying call sites.

## Source pattern: Factory (`hmlongco/Factory`)

Factory has the closest shape to Forge. Most patterns map directly.

| Factory | Forge equivalent |
|---|---|
| `Container.shared` static container | `AppContainer` (built-in) or your own `Container` subclass |
| `@Injected(\.authService)` | `@Inject(\.authService)` |
| `Factory(self) { AuthService() }` | `provide(.transient) { AuthService() }` |
| `.singleton` scope | `provide(.singleton) { ... }` |
| `.cached` scope | `provide(.cached) { ... }` |
| `.unique` / per-resolution | `.transient` (default) |
| `.shared` Factory scope | Closest match is `.singleton`; verify lifetime semantics manually |
| `.register { Mock() }` (testing) | `withOverrides { $0.override(\.x) { Mock() } }` |

Step-by-step:
1. Rename Factory's `Container` subclass to a Forge `Container` subclass.
2. Replace each `Factory(self) { ... }` with `provide(scope) { ... }`. The return type goes on the property, not the factory.
3. Replace `@Injected` call sites with `@Inject`.
4. Replace `.register { Mock() }` in tests with `withOverrides`.

Watch out for:
- Factory's `@LazyInjected` / `@WeakLazyInjected` — Forge does not have weak references. Verify the original lifetime intent; usually `.singleton` is correct.
- Factory's named/keyed factories — Forge does not support named registrations. Refactor into separate properties.
- Factory's `Resolver`-style autoregistration — Forge does not autoregister. Each dependency is an explicit property.

## Source pattern: service locator / `.shared` singletons

Existing code:
```swift
final class AnalyticsService {
    static let shared = AnalyticsService()
    private init() {}
}

// Usage everywhere:
AnalyticsService.shared.track(event)
```

Migration steps:
- Introduce `AnalyticsProtocol` if not present.
- Register in `AppContainer`:
  ```swift
  var analytics: any AnalyticsProtocol {
      provide(.singleton) { AnalyticsService() }
  }
  ```
- Replace `AnalyticsService.shared` call sites with `@Inject(\.analytics)` (in classes) or `AppContainer.shared.analytics` (in Views / contexts where `@Inject` doesn't fit).
- Optionally remove the `static shared` property once all call sites are migrated — but only after tests pass.

Migration order matters: introduce the Forge registration first, point a few call sites at it, run tests, then expand. Leaving `.shared` and `@Inject` coexisting during the transition is fine.

## When to call `forge-migrator` instead

Invoke the `forge-migrator` subagent when:
- The codebase has more than ~10 dependencies across multiple files.
- Multiple modules need coordinated migration.
- The source pattern is unclear or mixed (some Factory, some manual, some singletons).
- The user wants the migration done as a series of reviewable changes rather than one big diff.

Do the migration inline (without `forge-migrator`) when:
- A single file or small handful of types is in scope.
- The user wants to learn the pattern by walking through it together.

## Pitfalls

- **Don't migrate tests first.** Migrate the production code, run the original tests, then rewrite tests on top of `withOverrides`. Migrating tests first removes your safety net.
- **Don't change scopes by accident.** Factory's `.shared` is not Forge's `.singleton` in all cases — verify lifetime semantics in the original.
- **Don't forget cross-module proxies.** If a feature module depends on something the app composes, use `unimplemented` (see `forge-modular`), not a direct import.

## Related skills

- `using-forge` — registration and injection basics
- `forge-modular` — multi-module composition root
- `forge-testing` — `withOverrides` patterns
