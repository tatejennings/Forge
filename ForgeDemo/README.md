# ForgeDemo — the Modular reference app

ForgeDemo is the canonical example of Forge's **Modular** path: a multi-package
Swift app where **each module is its own SPM package**, every module owns its
dependencies in its **own container**, cross-module dependencies are
`unimplemented()` **proxies**, and a thin **composition root** in the app target
wires the real implementations in at launch.

> Looking for the **Simple** (single-target, extend-`AppContainer`) path? It needs
> no demo — see the
> [Getting Started](https://tatejennings.github.io/Forge/documentation/forge/gettingstarted)
> guide and the Quick Start in the repo [README](../README.md). This app is **not**
> a Simple example; do not copy its structure into a single-target app.

## How to tell this is the Modular path

- **One package per module** — each has its own `Package.swift` and only declares
  the dependencies it actually uses, so boundaries are enforced by the build.
- **Per-module containers** with `SharedContainer` conformance. Feature modules add a
  local `typealias Inject<T> = ContainerInject<XContainer, T>`; provider modules
  (Core*) just register services.
- **`unimplemented()` proxies** for dependencies a feature module declares but cannot
  construct itself.
- **A thin composition root** — a standalone `wireContainers()` in
  `CompositionRoot.swift` that `override`s each proxy with the real implementation
  owned by a Core module's container. **The app target owns no dependencies and never
  extends `AppContainer`.**

A Simple app has none of these — no per-module packages, no feature containers, no
`unimplemented()`, no `wireContainers()`.

## Layout

```
ForgeDemo/
├── ForgeDemo/                      # app target (thin)
│   ├── CompositionRoot.swift       # wireContainers() — wires proxies; AppContainer placeholder (commented)
│   ├── ForgeDemoApp.swift          # @main; init() { wireContainers() }
│   └── RootView.swift
└── Packages/                       # one package per module
    ├── CoreModels/                 # protocols + models + mocks. No Forge.
    ├── CoreNetworking/             # NetworkingContainer { httpClient, remoteTaskService }
    ├── CoreInfrastructure/         # InfrastructureContainer { persistence, taskService, appState }; depends on CoreNetworking
    ├── FeatureTasks/               # TaskContainer (proxies: taskService, appState)
    └── FeatureSettings/            # SettingsContainer (proxies: taskService, appState)
```

## How wiring flows

1. `CoreNetworking` / `CoreInfrastructure` own the **real** services in their own
   containers (`InfrastructureContainer.taskService` reads `remoteTaskService` from
   `NetworkingContainer` — an allowed downward Core → Core dependency).
2. `FeatureTasks` / `FeatureSettings` declare `taskService` / `appState` as
   `unimplemented()` proxies.
3. The app target's `wireContainers()` resolves the reals from
   `InfrastructureContainer.shared` and `override`s the feature proxies — once, at
   launch. The app target itself registers nothing.

## See also

- [`forge-modular`](../plugins/forge/skills/forge-modular/SKILL.md) skill — the full Modular pattern
- [`using-forge`](../plugins/forge/skills/using-forge/SKILL.md) skill — "Which path am I in?" decision rule
- [ModularArchitecture](https://tatejennings.github.io/Forge/documentation/forge/modulararchitecture) (DocC)
