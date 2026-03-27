# Swift DI Framework — Technical Specification

> **Working name:** `Forge`
> If the name changes, update the SPM package name, module name, and all import statements accordingly.

---

## 1. Overview

Forge is a lightweight, compile-time safe dependency injection framework for Swift, built as a Swift Package. It is designed for modular SPM-based iOS/tvOS/macOS applications where each feature module manages its own dependencies through a scoped container.

The framework has one north star: **make dependency injection easier than not using it.** Every design decision is evaluated against that standard. If a feature adds friction for the common case, it does not belong in Forge.

---

## 2. Design Philosophy & Developer Experience Goals

These are the five non-negotiable priorities for Forge, in order. If a proposed implementation decision conflicts with a higher-priority item, the higher-priority item wins.

### Priority 1 — Easy to use and implement
A developer should be able to add Forge to a module, define a container, and inject a dependency in under five minutes without reading documentation. The API surface should feel obvious and native to Swift — not like learning a new paradigm.

### Priority 2 — Minimal boilerplate
Every line of code Forge requires a developer to write must earn its place. The registration of a dependency should be one computed property. The injection of a dependency should be one property declaration. The setup of a test override should be one closure. Nothing more.

### Priority 3 — SOLID architecture by default
Forge should make it easy to follow SOLID principles and awkward to violate them. The framework does not enforce correctness at compile time in every case, but its design should naturally guide developers toward good architecture. See Section 3 for full details.

### Priority 4 — Easy to test
Testing with Forge should require less code than testing without it. Overrides should be obvious, scoped, and automatically cleaned up. There should be no global state leakage between tests.

### Priority 5 — Easy to use with Xcode Previews
The `preview:` parameter on `provide` means that adding preview support for a dependency costs one extra closure at the definition site. No separate preview container, no conditional compilation at call sites.

---

## 3. SOLID Architecture in Forge

Forge is designed to make SOLID principles the path of least resistance. This section explains how each principle applies to both the framework's internal design and to how developers use it.

### Single Responsibility Principle
**The rule:** Each type should have one reason to change.

**In the framework:** `Container` manages lifecycle and resolution. `Scope` describes caching behavior. `ContainerInject` handles injection. `OverrideBuilder` handles test configuration. Each type does one thing.

**For developers using Forge:** Each container should own the dependencies for exactly one module. An `AuthContainer` should not register analytics services. If a container grows beyond its module's concerns, that is a signal that the module has too many responsibilities.

**Forge's role:** The per-module container pattern (one container per module, one `DI.swift` per module) makes single responsibility the natural default.

### Open/Closed Principle
**The rule:** Open for extension, closed for modification.

**In the framework:** `Container` is an `open class`. New containers are extensions — they add computed properties without touching the base class. Scope behavior is additive (new scopes can be added without changing existing ones).

**For developers using Forge:** Feature behavior is changed by overriding at the container boundary, not by modifying implementation types. A test that needs different behavior provides a different factory — it never edits `AuthService` to add test-specific branches.

```swift
// ✅ Open/Closed — override at the container, don't modify AuthService
AuthContainer.shared.withOverrides {
    $0.override("authService") { MockAuthService() }
} run: { ... }

// ❌ Violates Open/Closed — adding test flags inside production types
class AuthService {
    var isTesting = false  // never do this
}
```

### Liskov Substitution Principle
**The rule:** Subtypes must be substitutable for their base types without altering program correctness.

**In the framework:** `Container` subclasses are always valid containers. The base class API works identically on any subclass. `SharedContainer` conformance guarantees a `shared` instance is always available.

**For developers using Forge:** Always declare container properties using protocol return types (`any ServiceProtocol`), never concrete types. This is what makes mocks substitutable for live implementations.

```swift
// ✅ Protocol return type — mock is substitutable
public var authService: any AuthServiceProtocol {
    provide(.singleton) { AuthService() }
}

// ❌ Concrete return type — cannot substitute a mock without a subclass
public var authService: AuthService {
    provide(.singleton) { AuthService() }
}
```

**Forge's guidance:** Claude Code should add a note in the DocC comment for `provide` recommending protocol return types. The README must include this as a best practice.

### Interface Segregation Principle
**The rule:** Clients should not be forced to depend on interfaces they do not use.

**In the framework:** `SharedContainer` is a minimal protocol — just `static var shared`. `Container` does not inherit from it. Developers only opt into `SharedContainer` when they need the zero-argument `@Inject` syntax.

**For developers using Forge:** Define narrow protocols for each dependency. A `NetworkClientProtocol` should not carry authentication methods just because the networking layer also does auth. Separate concerns into separate protocols and separate container registrations.

```swift
// ✅ Narrow protocols — each consumer only depends on what it needs
protocol NetworkClientProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

protocol AuthTokenProviderProtocol {
    var currentToken: String? { get }
}

// ❌ Fat protocol — forces all consumers to know about unrelated concerns
protocol NetworkClientProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    var currentToken: String? { get }   // why does a network client know about auth tokens?
    func logout()                        // definitely not a networking concern
}
```

### Dependency Inversion Principle
**The rule:** High-level modules should not depend on low-level modules. Both should depend on abstractions.

**In the framework:** This is Forge's *entire purpose*. The container is the composition root — it is the only place where abstractions are wired to concretions. Everything above it (ViewModels, services, business logic) depends only on protocols. Everything below it (concrete implementations) knows nothing about the container.

**For developers using Forge:** Feature modules must import only protocol/interface modules, never concrete implementation modules. The container (or app target) is the only place that imports both.

```
CoreProtocols (protocols only — no Forge import)
     ↑ depends on
AuthModule (AuthContainer depends on CoreProtocols abstractions)
     ↑ wired by
AppTarget (imports AuthModule + concrete implementations, wires at startup)
```

ViewModels and services never `import` a concrete service module directly. They inject via protocol. The container handles the wiring.

---

## 4. Goals

- Container-based DI with explicit, readable resolution
- Per-module scoped containers with clean `@Inject` call sites via module-local typealiases
- Three lifecycle scopes: transient, singleton, cached
- First-class testing support via scoped overrides (automatic cleanup, no `defer` required)
- Xcode preview support via `previewValue` factories on individual dependencies
- `unimplemented` helper for loud test failures when dependencies are accidentally called
- Swift 6 / strict concurrency compliant
- Zero third-party dependencies
- No code generation, no build phases, no reflection

## 5. Non-Goals (explicit out of scope for v1)

The following are intentionally excluded. Do not implement these:

- Weak-reference scopes
- TTL / time-based scopes
- Named/tagged registrations
- Decorator / middleware hooks
- Context-aware resolution (e.g. debug vs release factories)
- Circular dependency detection
- Auto-wiring / reflection-based resolution
- Objective-C compatibility

---

## 6. Platform & Language Requirements

| Requirement | Value |
|---|---|
| Swift | 5.10 minimum |
| iOS | 16.0+ |
| tvOS | 16.0+ |
| macOS | 13.0+ |
| watchOS | 9.0+ |
| Xcode | 15.0+ |

---

## 7. SPM Package Structure

```
Forge/                               ← GitHub repo root
├── Package.swift                    ← Forge framework package
├── README.md
├── LICENSE
├── Sources/
│   └── Forge/
│       ├── Container.swift          # Base container class
│       ├── Scope.swift              # Scope enum
│       ├── ContainerInject.swift    # @ContainerInject property wrapper
│       ├── Unimplemented.swift      # unimplemented() test helper
│       └── Internal/
│           ├── ScopeCache.swift     # Internal caching logic
│           ├── Lock.swift           # Thread safety primitives
│           └── PreviewContext.swift # Preview environment detection
├── Tests/
│   └── ForgeTests/
│       ├── ContainerTests.swift
│       ├── ScopeTests.swift
│       ├── OverrideTests.swift
│       ├── PreviewTests.swift
│       └── Fixtures/
│           ├── TestContainer.swift
│           └── TestServices.swift
└── ForgeDemo/                         ← ForgeDemo app lives here
    ├── ForgeDemo.xcodeproj
    └── Packages/
        └── MomentumPackages/        ← demo's SPM package (references Forge via path: "../../")
```

### Package.swift Requirements

- Products: one library product named `Forge`
- Target: one target named `Forge` at `Sources/Forge`
- Test target: `ForgeTests` depending on `Forge`
- No external dependencies
- Swift tools version: 5.10

---

## 8. Core Types

### 6.1 `Scope`

```swift
// Sources/Forge/Scope.swift

public enum Scope {
    /// A new instance is created every time the dependency is resolved. (Default)
    case transient

    /// One instance per container. Created on first resolution, lives as long as the container.
    case singleton

    /// One instance per container. Created on first resolution. Can be explicitly reset
    /// via `container.resetCached()`. Survives until reset or container deallocation.
    case cached
}
```

No other cases. Do not add cases without updating this spec.

---

### 6.2 `Container`

```swift
// Sources/Forge/Container.swift

open class Container {

    // MARK: - Initialization

    public init() {}

    // MARK: - Core Resolution

    /// Called from computed property definitions on subclasses.
    /// Uses `#function` as the default key — matches the property name automatically.
    ///
    /// When `preview` is provided and the app is running inside an Xcode preview,
    /// the preview factory is used instead of the main factory. No scope caching
    /// is applied to preview values — they are always transient in that context.
    ///
    /// Example:
    ///   var myService: any MyServiceProtocol {
    ///       provide(.singleton, preview: { MockService() }) { LiveService() }
    ///   }
    public func provide<T>(
        _ scope: Scope = .transient,
        preview: (() -> T)? = nil,
        key: String = #function,
        _ factory: () -> T
    ) -> T

    // MARK: - Testing / Overrides

    /// Registers overrides for the duration of a closure, then automatically restores
    /// the previous state. Overrides registered via the builder take precedence over
    /// original factories within the closure body.
    ///
    /// This is the preferred override pattern — no `defer` or manual cleanup needed.
    ///
    /// Example:
    ///   AuthContainer.shared.withOverrides {
    ///       $0.override("authService") { MockAuthService() }
    ///   } run: {
    ///       let vm = LoginViewModel()
    ///       // test assertions...
    ///   }
    public func withOverrides(
        _ configure: (inout OverrideBuilder) -> Void,
        run body: () throws -> Void
    ) rethrows

    /// Async variant of withOverrides for use in async test contexts.
    public func withOverrides(
        _ configure: (inout OverrideBuilder) -> Void,
        run body: () async throws -> Void
    ) async rethrows

    /// Registers a replacement factory for a given key directly (for setUp/tearDown patterns).
    /// The key must exactly match the computed property name on the container.
    public func override<T>(_ key: String, with factory: @escaping () -> T)

    /// Removes a single override by key.
    public func removeOverride(for key: String)

    /// Removes all registered overrides and clears all cached/singleton values.
    public func resetAll()

    /// Clears only cached-scope values (scope == .cached). Leaves singletons intact.
    public func resetCached()
}
```

#### `OverrideBuilder`

A simple value type passed into `withOverrides`. Its only job is accumulating override registrations before they are applied to the container.

```swift
public struct OverrideBuilder {
    /// Registers an override factory for the given key.
    /// The key must exactly match the computed property name on the container.
    public mutating func override<T>(_ key: String, with factory: @escaping () -> T)
}
```

The builder intentionally mirrors the container's direct `override` API so the mental model is consistent. The closure form just handles the save/restore lifecycle automatically.

#### `withOverrides` Internal Implementation

```
1. Snapshot current overrides dictionary
2. Apply all overrides registered via OverrideBuilder
3. Execute body closure
4. Restore snapshot (even if body throws)
```

This is a stack-free, copy-based approach. The snapshot is a `[String: Any]` copy taken before mutations. Restoration is guaranteed because `rethrows` propagates errors after the restore step.

**Note on string keys:** `withOverrides` uses the same string-keyed mechanism as direct overrides. The key must match the computed property name exactly. The `#if DEBUG` unmatched-key warning (Section 9.4) covers both override paths and will catch typos during development.

#### Internal Implementation Notes for `provide`

The `provide` function is the single resolution point. Its behavior:

1. Check `overrides[key]` — if present, call override factory and return (no caching of overrides)
2. If running inside an Xcode preview (detected via `PreviewContext.isPreview`) AND a `preview` factory was provided, call `preview()` and return (no caching)
3. If `scope == .transient`, call `factory()` and return immediately
4. If `scope == .singleton` or `scope == .cached`, check the appropriate cache dictionary
   - Cache hit: return cached value cast to `T`
   - Cache miss: call `factory()`, store result, return

Cache storage is `[String: Any]`. Casts use `as? T`. If a cast fails (type mismatch, likely a bug), call `factory()` and return fresh — do not crash in production.

Singletons and cached values use the same underlying cache mechanism but are stored in separate dictionaries (`singletonCache` and `cachedCache`) so `resetCached()` can clear one without touching the other.

#### Preview Detection (`PreviewContext`)

```swift
// Sources/Forge/Internal/PreviewContext.swift

enum PreviewContext {
    /// Returns true when the process is running inside an Xcode preview.
    /// Detection method: check ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"]
    static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
```

This is the standard detection mechanism used across the Swift community. It is not a public API — it is an internal implementation detail of `provide`. Do not expose `PreviewContext` publicly.

#### Thread Safety

All reads and writes to `singletonCache`, `cachedCache`, and `overrides` must be protected.

Use `NSLock` (not an actor). Rationale: actor isolation would make `provide` `async`, which is unacceptable at call sites in `init` and property declarations.

Mark `Container` as `@unchecked Sendable`.

The lock must use a **double-checked locking pattern** for cache reads to avoid lock contention on hot paths:

```
read without lock → if miss → acquire lock → read again → if still miss → write
```

---

### 6.3 `ContainerInject`

```swift
// Sources/Forge/ContainerInject.swift

@propertyWrapper
public struct ContainerInject<C: Container, Value> {

    private let keyPath: KeyPath<C, Value>
    private let container: C
    private var _resolved: Value?

    /// Resolves lazily — dependency is acquired on first access of `wrappedValue`,
    /// not at initialization of the property wrapper.
    public var wrappedValue: Value { mutating get }

    /// Init that accepts an explicit container instance.
    public init(_ container: C, _ keyPath: KeyPath<C, Value>)

    /// Init that accepts a container's shared instance automatically.
    /// Requires C to conform to SharedContainer.
    public init(_ keyPath: KeyPath<C, Value>) where C: SharedContainer
}
```

#### `SharedContainer` Protocol

```swift
public protocol SharedContainer: AnyObject {
    static var shared: Self { get set }
}
```

`Container` does NOT conform to `SharedContainer` by default. User-defined containers opt in:

```swift
// In the user's module
final class AppContainer: Container, SharedContainer {
    static var shared = AppContainer()
}
```

This is required for the zero-argument `@Inject(\.someProperty)` syntax to work via the module-local typealias.

#### Lazy Resolution

Resolution is deferred to first access. This is important because property wrappers initialize before their enclosing type's `init` body runs, so resolving eagerly can create ordering issues with containers that are configured after object creation (common in tests).

---

### 6.4 `unimplemented`

```swift
// Sources/Forge/Unimplemented.swift

/// Returns a closure that triggers an XCTest failure (in test targets) or a
/// fatal error (in production) if it is ever called.
///
/// Use this when defining a test container's dependencies to ensure that any
/// dependency your test does not explicitly override will loudly fail if called,
/// rather than silently executing live code.
///
/// Example:
///   var analytics: any AnalyticsProtocol {
///       provide { unimplemented("analytics") }
///   }
public func unimplemented<T>(_ name: String, file: StaticString = #file, line: UInt = #line) -> T
```

#### Implementation Notes

- In test targets (`#if DEBUG` + XCTest available): call `XCTFail` with a descriptive message, then `fatalError` to satisfy the return type
- In all other contexts: `fatalError` with a descriptive message
- The message format should be: `"'\(name)' was called but is not implemented. Override this dependency in your test container."`
- `file` and `line` default arguments capture the call site for XCTest failure attribution

#### Usage Pattern

```swift
// A "safe" test container where unoverridden dependencies fail loudly
final class AuthContainerTests: XCTestCase {

    override func setUp() {
        // Fresh container with unimplemented traps
        AuthContainer.shared = AuthContainer()
        AuthContainer.shared.withOverrides {
            // Only override what this specific test needs.
            // Any other dependency accidentally called will fatalError.
            $0.override("authService") { MockAuthService() }
        } run: {
            // test body
        }
    }
}
```

This pattern is inspired by swift-dependencies' `unimplemented` concept. It makes the test contract explicit: you declare exactly which dependencies a test exercises, and anything else is a bug.

---

## 9. Per-Module Usage Pattern

### 7.1 Module-Local Typealias

Each SPM module that uses DI defines a single file:

```swift
// FeatureAuthModule/Sources/DI.swift

import Forge

typealias Inject<T> = ContainerInject<AuthContainer, T>
```

This is the **only file** where `AuthContainer` is referenced by name within the module's call sites. All `@Inject` usages elsewhere in the module use the bare `@Inject(\.propertyName)` syntax.

### 7.2 Container Definition

```swift
// FeatureAuthModule/Sources/AuthContainer.swift

import Forge

public final class AuthContainer: Container, SharedContainer {

    public static var shared = AuthContainer()

    // MARK: - Dependencies

    public var authService: any AuthServiceProtocol {
        provide(.singleton, preview: { MockAuthService() }) { AuthService(network: self.networkClient) }
    }

    public var networkClient: any NetworkClientProtocol {
        provide(.singleton) { URLSessionNetworkClient() }
    }

    public var tokenStorage: any TokenStorageProtocol {
        provide { KeychainTokenStorage() }
    }
}
```

Rules for container definitions:
- Properties that expose protocol types must use `any ProtocolName` return type
- Properties can reference `self` to access sibling dependencies
- `preview:` factories should return safe, non-network mocks suitable for Xcode Previews
- The `preview:` parameter is optional — omit it for dependencies that behave correctly in previews without mocking (e.g. pure in-memory services)
- All public — these are the module's DI surface
- The container class itself should be `public` for app-level composition

### 7.3 Injection at Call Sites

```swift
// FeatureAuthModule/Sources/LoginViewModel.swift

final class LoginViewModel: ObservableObject {

    @Inject(\.authService) private var auth
    @Inject(\.tokenStorage) private var tokens

    // ...
}
```

No container name visible. No explicit `shared` reference. Clean.

### 7.4 Inline Resolution (without property wrapper)

For use cases where a property wrapper is not appropriate (e.g. inside a function, or a non-class type):

```swift
let auth = AuthContainer.shared.authService
```

Both patterns are valid and encouraged depending on context.

---

## 10. Cross-Module Dependencies

Feature modules must not import other feature modules. If a feature module needs a dependency owned by another module, it proxies it through its own container:

```swift
// FeatureSearch depends on analytics, which lives in CoreAnalyticsModule

// FeatureSearch/Sources/SearchContainer.swift
import CoreAnalyticsModule

public final class SearchContainer: Container, SharedContainer {
    public static var shared = SearchContainer()

    // Proxy — SearchContainer owns the reference, delegates to CoreAnalyticsModule
    public var analytics: any AnalyticsProtocol {
        provide { CoreAnalyticsContainer.shared.analytics }
    }

    public var searchService: any SearchServiceProtocol {
        provide(.singleton) { SearchService(analytics: self.analytics) }
    }
}
```

Benefits of proxying:
- SearchModule is testable in isolation — override `analytics` on `SearchContainer`, not `CoreAnalyticsContainer`
- Clean dependency graph — SearchModule's DI seam is fully within SearchContainer
- App target controls what `CoreAnalyticsContainer.shared.analytics` actually resolves to

---

## 11. Testing & Overrides

### 9.1 Scoped Overrides with `withOverrides` (preferred)

`withOverrides` is the preferred override mechanism. Overrides are automatically cleaned up when the closure exits — no `defer`, no manual `resetAll()`, no risk of test state leaking between cases.

```swift
func testLoginSuccess() async throws {
    let mock = MockAuthService(shouldSucceed: true)

    try await AuthContainer.shared.withOverrides {
        $0.override("authService") { mock }
    } run: {
        let viewModel = LoginViewModel()
        await viewModel.login(username: "user", password: "pass")
        XCTAssertTrue(mock.loginCalled)
    }
}
```

Both sync and async `run` variants are provided (see Section 6.2). Use the async variant for any test that calls async code.

### 9.2 Container Swap (preferred for full suite isolation)

For test classes where every test needs a clean slate, swap `shared` in `setUp`/`tearDown`. This is the recommended pattern for parallel test execution.

```swift
final class LoginViewModelTests: XCTestCase {

    override func setUp() {
        AuthContainer.shared = AuthContainer()
    }

    override func tearDown() {
        AuthContainer.shared = AuthContainer()
    }

    func testLoginCallsService() async throws {
        let mock = MockAuthService()

        try await AuthContainer.shared.withOverrides {
            $0.override("authService") { mock }
        } run: {
            let vm = LoginViewModel()
            await vm.login(username: "test", password: "pass")
            XCTAssertTrue(mock.loginCalled)
        }
    }
}
```

Container swap + `withOverrides` compose naturally. Swap gives you a clean container per test class; `withOverrides` gives you targeted overrides per test method.

### 9.3 Direct Overrides (for setUp/tearDown patterns)

When `withOverrides` closures are impractical (e.g. setting up overrides in `setUp` that persist across multiple test methods), use the direct override API with manual cleanup:

```swift
override func setUp() {
    AuthContainer.shared = AuthContainer()
    AuthContainer.shared.override("authService") { MockAuthService() }
}

override func tearDown() {
    AuthContainer.shared.resetAll()
}
```

This is the escape hatch, not the default. Prefer `withOverrides` wherever possible.

### 9.4 Debug Warning for Unmatched Override Keys

In `DEBUG` builds only, the container should emit a runtime warning (using `print` or `os_log`) if an override key is registered but never hits during the test run. This helps catch typos in key strings.

Implementation: track a `Set<String>` of override keys that have been queried. At `resetAll()` time (and at the end of `withOverrides`), diff against registered overrides and warn on any that were never accessed.

This behavior is `#if DEBUG` only and silent in release builds. It applies to both `withOverrides` and direct `override(_:with:)` registrations.

### 9.5 `unimplemented` for Explicit Test Contracts

Use `unimplemented` in container definitions to make test boundaries explicit. Any dependency not overridden in a test will loudly fail if called, rather than silently executing live code:

```swift
// A test-specific container subclass where everything is unimplemented by default
final class TestAuthContainer: AuthContainer {
    override var authService: any AuthServiceProtocol {
        provide { unimplemented("authService") }
    }
    override var networkClient: any NetworkClientProtocol {
        provide { unimplemented("networkClient") }
    }
}

// In your test — only provide what you actually need
func testLoginSuccess() async throws {
    AuthContainer.shared = TestAuthContainer()

    try await AuthContainer.shared.withOverrides {
        $0.override("authService") { MockAuthService(shouldSucceed: true) }
        // networkClient is unimplemented — if login accidentally calls it, test fails
    } run: {
        let vm = LoginViewModel()
        await vm.login(username: "user", password: "pass")
    }
}
```

---

## 12. Full End-to-End Example

This example is the canonical reference. Tests should validate this exact pattern works.

### Protocols (CoreModule)

```swift
// CoreModule — no Forge import needed
public protocol AuthServiceProtocol {
    func login(username: String, password: String) async throws -> User
}

public protocol NetworkClientProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}
```

### Container (AuthModule)

```swift
import Forge
import CoreModule

public final class AuthContainer: Container, SharedContainer {
    public static var shared = AuthContainer()

    public var networkClient: any NetworkClientProtocol {
        provide(.singleton, preview: { MockNetworkClient() }) { URLSessionNetworkClient() }
    }

    public var authService: any AuthServiceProtocol {
        provide(.singleton, preview: { MockAuthService() }) { AuthService(network: self.networkClient) }
    }
}
```

### DI.swift (AuthModule)

```swift
import Forge
typealias Inject<T> = ContainerInject<AuthContainer, T>
```

### ViewModel (AuthModule)

```swift
final class LoginViewModel: ObservableObject {
    @Inject(\.authService) private var authService

    func login(username: String, password: String) async {
        // uses authService resolved from AuthContainer.shared
    }
}
```

### Test

```swift
import XCTest
@testable import AuthModule

final class LoginViewModelTests: XCTestCase {

    override func setUp() {
        AuthContainer.shared = AuthContainer()
    }

    override func tearDown() {
        AuthContainer.shared = AuthContainer()
    }

    func testLoginCallsService() async throws {
        let mock = MockAuthService()

        try await AuthContainer.shared.withOverrides {
            $0.override("authService") { mock }
        } run: {
            let vm = LoginViewModel()
            await vm.login(username: "test", password: "pass")
            XCTAssertTrue(mock.loginCalled)
        }
    }
}
```

---

## 13. Error Handling & Safety Contracts

| Scenario | Behavior |
|---|---|
| Override key typo (no property match) | `#if DEBUG` warning at `resetAll()` / `withOverrides` exit time |
| `withOverrides` body throws | Overrides are restored before error propagates |
| Cache cast failure (`Any` → `T`) | Fall through to factory, create fresh instance |
| Circular dependency | Stack overflow (no detection in v1 — document this) |
| `shared` accessed before assignment | Standard Swift fatalError on nil optional (if optional) or default-init |
| Concurrent reads during write | Protected by `NSLock` |
| `unimplemented` called in test | XCTFail + fatalError with descriptive message |
| `unimplemented` called in production | fatalError with descriptive message |
| Preview factory called outside preview | Never called — `PreviewContext.isPreview` guards usage |

---

## 14. What Claude Code Should NOT Do

- Do not add any features beyond what is specified here
- Do not add `@discardableResult` noise to `provide`
- Do not make `Container` conform to `SharedContainer` by default
- Do not use `actor` for the container — it makes resolution `async`
- Do not use `@MainActor` on the container
- Do not use reflection or `Mirror`
- Do not add `Hashable`/`Equatable` conformances to containers
- Do not add Combine publishers or `@Published` properties to the framework
- Do not add logging beyond the debug-mode override warning described in Section 9.4
- Do not expose `PreviewContext` as a public API
- Do not make `unimplemented` return an optional — it must satisfy any return type via `fatalError`

---

## 15. Test Coverage Requirements

The following scenarios must have test coverage before the framework is considered complete:

- Transient scope returns new instance each resolution
- Singleton scope returns same instance across multiple resolutions
- Cached scope returns same instance until `resetCached()` is called
- `resetCached()` does NOT clear singleton-scoped values
- `resetAll()` clears both cached and singleton values
- Override takes precedence over original factory
- Override is NOT cached (each resolution calls the override factory)
- `removeOverride(for:)` restores original factory behavior
- `resetAll()` removes all overrides
- `withOverrides` applies overrides within closure and restores after exit
- `withOverrides` restores overrides even when body throws
- `withOverrides` async variant works correctly in async contexts
- `@ContainerInject` resolves lazily (not at property wrapper init time)
- Thread safety: concurrent resolution of singleton does not produce two instances
- Container swap pattern works correctly in test setUp/tearDown
- Cross-module proxy pattern: override on owning container propagates correctly
- `previewValue` factory is used when `PreviewContext.isPreview` is true
- `previewValue` factory is NOT used when `PreviewContext.isPreview` is false
- Preview values are not cached regardless of declared scope
- `unimplemented` triggers `fatalError` (or XCTFail in test context) when called

---

## 16. Documentation Requirements

Every public type and public method must have a DocC comment covering:
- What it does (one line)
- Parameters
- Any behavior notes (e.g. thread safety, laziness, preview context)

The README should include:
- Installation (SPM URL)
- 5-minute quickstart showing registration and resolution
- The per-module typealias pattern
- The `preview:` parameter for Xcode Preview support
- Testing pattern: container swap + `withOverrides`
- The `unimplemented` helper and when to use it
- A **SOLID in practice** section with short code examples for each principle (drawn from Section 3 of this spec)
- A **best practices** section covering: always use protocol return types, keep containers module-scoped, keep protocols narrow, never import concrete modules from feature modules
- Explicit "what this is not" section

---

## 17. Open Questions / Decisions for Implementor

These are intentionally left open and can be resolved during implementation:

1. **`shared` mutability** — `static var shared` is mutable by design for test container swapping. Consider whether a `static func makeShared() -> Self` factory method is cleaner than direct mutation. Either is acceptable.

2. **`ContainerInject` storage** — The `_resolved: Value?` backing store requires `ContainerInject` to be `mutating`-aware. Verify this works correctly in `class` contexts (it should, since classes have reference semantics). Document any limitations in struct contexts.

3. **Package name vs module name** — SPM allows the package name (`Forge`) to differ from the module import name. Decide whether `import Forge` or `import ForgeKit` is cleaner and be consistent throughout.

4. **`withOverrides` thread safety** — The snapshot/restore approach is safe for serial test execution. For parallel tests, the container swap pattern (Section 9.2) is the correct tool — document this clearly. Do not attempt to make `withOverrides` thread-safe across concurrent callers; that complexity is out of scope.