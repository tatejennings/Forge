# Testing with Forge

Mock dependencies in tests using scoped overrides, container swap, and explicit test contracts.

## Overview

Forge provides three mechanisms for overriding dependencies in tests, listed in order
of preference. All examples use Swift Testing (`@Test`, `@Suite`, `#expect`).

## Scoped Overrides with withOverrides (Preferred)

``Container/withOverrides(_:run:)-3qdpl`` registers overrides for the duration of a
closure, then automatically restores the previous state. No manual cleanup required:

```swift
@Test("Login succeeds with valid credentials")
func testLoginSuccess() async throws {
    let mock = MockAuthService(shouldSucceed: true)

    try await AuthContainer.shared.withOverrides {
        $0.override(\.authService) { mock }
    } run: {
        let viewModel = LoginViewModel()
        await viewModel.login(username: "user", password: "pass")
        #expect(mock.loginCalled)
    }
}
```

Cleanup is guaranteed via `defer` — even if the body throws, overrides are restored.
Both sync and async variants are available:

- ``Container/withOverrides(_:run:)-3qdpl`` — synchronous
- ``Container/withOverrides(_:run:)-4eui2`` — async (use when your test body contains `await`)

## Container Swap

For test suites where every test needs a completely fresh container, swap
``SharedContainer/shared`` in the suite's `init`:

```swift
@Suite("LoginViewModel behavior", .serialized)
struct LoginViewModelTests {

    init() {
        AuthContainer.shared = AuthContainer()
    }

    @Test("Login calls the auth service")
    func testLoginCallsService() async throws {
        let mock = MockAuthService()

        try await AuthContainer.shared.withOverrides {
            $0.override(\.authService) { mock }
        } run: {
            let vm = LoginViewModel()
            await vm.login(username: "test", password: "pass")
            #expect(mock.loginCalled)
        }
    }
}
```

Each test gets a fresh container with no leftover state from previous tests.

## Direct Overrides (Escape Hatch)

When `withOverrides` closures are impractical, use ``Container/override(_:with:)``
directly:

```swift
init() {
    AuthContainer.shared = AuthContainer()
    AuthContainer.shared.override(\.authService) { MockAuthService() }
}
```

This is the escape hatch — prefer `withOverrides` wherever possible because direct
overrides require manual cleanup via ``Container/removeOverride(for:)`` or
``Container/resetAll()``.

## The TestContainer Pattern with unimplemented

``unimplemented(_:file:line:)`` makes dependency contracts explicit — any dependency
that isn't overridden crashes immediately instead of silently running the wrong code.
This is valuable in tests (shown here) and in cross-module proxies (see
<doc:ModularArchitecture>).

Use it to define a test container where every dependency fails loudly if called
without being explicitly overridden:

```swift
final class TestAuthContainer: AuthContainer {
    override var authService: any AuthServiceProtocol {
        provide { unimplemented("authService") }
    }

    override var networkClient: any NetworkClientProtocol {
        provide { unimplemented("networkClient") }
    }
}
```

Then in your tests, swap to the test container and override only what you need:

```swift
@Test("Login success flow")
func testLoginSuccess() async throws {
    AuthContainer.shared = TestAuthContainer()

    try await AuthContainer.shared.withOverrides {
        $0.override(\.authService) {
            MockAuthService(shouldSucceed: true)
        }
        // networkClient is unimplemented — if login accidentally
        // calls it, the test fails loudly instead of silently
        // executing live code
    } run: {
        let vm = LoginViewModel()
        await vm.login(username: "user", password: "pass")
    }
}
```

This makes test contracts explicit — you declare exactly which dependencies a test
exercises. Anything else is a bug.

## Best Practices

- **Prefer `withOverrides`** — automatic cleanup prevents test state leakage
- **Swap containers in suite `init()`** — gives each test a fresh starting point
- **Use `unimplemented` for test containers** — makes dependency boundaries explicit
- **Use `.serialized` on suites** that swap `shared` — prevents data races
- **Use protocol return types** on container properties — this is what makes mocks
  substitutable for live implementations
