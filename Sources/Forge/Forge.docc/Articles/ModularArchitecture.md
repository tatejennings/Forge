# Modular Architecture

Organize dependency injection across multiple Swift Package Manager modules.

## Overview

In a modular codebase, each SPM module owns its own ``Container`` subclass. This
keeps dependency boundaries clean, makes modules independently testable, and
prevents accidental cross-module coupling.

## One Container per Module

Each module defines exactly one container that manages all dependencies for that
module. The container file includes the module-local typealias:

```swift
// FeatureAuth/Sources/AuthContainer.swift

import Forge
import CoreProtocols

typealias Inject<T> = ContainerInject<AuthContainer, T>

public final class AuthContainer: Container, SharedContainer {
    public static var shared = AuthContainer()

    public var authService: any AuthServiceProtocol {
        provide(.singleton, preview: { MockAuthService() }) {
            AuthService(network: self.networkClient)
        }
    }

    public var networkClient: any NetworkClientProtocol {
        provide(.singleton) { URLSessionNetworkClient() }
    }
}
```

All `@Inject` usages within the module use the bare syntax — no container name visible:

```swift
// FeatureAuth/Sources/LoginViewModel.swift

final class LoginViewModel: ObservableObject {
    @Inject(\.authService) private var auth
}
```

## Cross-Module Proxying

Feature modules must not import other feature modules directly. If a module needs a
dependency owned by another module, it **proxies** the dependency through its own
container:

```swift
// FeatureSearch/Sources/SearchContainer.swift

import Forge
import CoreAnalytics

public final class SearchContainer: Container, SharedContainer {
    public static var shared = SearchContainer()

    // Proxy — delegates to another module's container
    public var analytics: any AnalyticsProtocol {
        provide { CoreAnalyticsContainer.shared.analytics }
    }

    public var searchService: any SearchServiceProtocol {
        provide(.singleton) {
            SearchService(analytics: self.analytics)
        }
    }
}
```

### Benefits of Proxying

- **Test isolation** — override `analytics` on `SearchContainer` directly, without
  touching `CoreAnalyticsContainer`
- **Clean dependency graph** — each module's DI surface is fully within its own container
- **Swappability** — if `CoreAnalytics` is replaced, only the proxy property needs updating

## The Composition Root

The app target is the **composition root** — the only place where all modules are
imported and containers are wired together:

```swift
// App/Sources/AppDelegate.swift

import FeatureAuth
import FeatureSearch
import CoreAnalytics

class AppDelegate: UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Wire containers
        AuthContainer.shared = AuthContainer()
        SearchContainer.shared = SearchContainer()
        CoreAnalyticsContainer.shared = CoreAnalyticsContainer()
        return true
    }
}
```

## Import Dependency Graph

The correct architecture follows this pattern:

```
CoreProtocols (protocols only — no Forge import)
       ^
       |
  Feature modules (each has its own Container)
       ^
       |
  App target (imports all modules, wires containers)
```

**Key rules:**

1. Protocol modules define abstractions only — no Forge dependency needed
2. Feature modules import protocol modules and Forge
3. ViewModels and services never `import` a concrete service module directly
4. The app target is the only place that imports both protocol and concrete modules

## Best Practices

- Keep containers **module-scoped** — if a container grows beyond its module's
  concerns, the module has too many responsibilities
- Make dependency properties **public** — they are the module's DI surface
- Use **protocol return types** on all dependency properties
- Proxy cross-module dependencies rather than importing other feature modules
