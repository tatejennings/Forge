# ForgeDemo — the Modular reference app

ForgeDemo is the canonical example of Forge's **Modular** path: a multi-module
Swift Package Manager app with **one container per feature module**, cross-module
`unimplemented()` proxies, and a **composition root** in the app target that wires
the real implementations in at launch.

> Looking for the **Simple** (single-target, extend-`AppContainer`) path? It needs
> no demo — see the
> [Getting Started](https://tatejennings.github.io/Forge/documentation/forge/gettingstarted)
> guide and the Quick Start in the repo [README](../README.md). This app is **not**
> a Simple example; do not copy its structure into a single-target app.

## How to tell this is the Modular path

The app target extends `AppContainer`, which on its own *looks* like the Simple
path. What makes ForgeDemo Modular is everything around that:

- **Per-module containers** with a module-local `typealias Inject<T> =
  ContainerInject<XContainer, T>` and `SharedContainer` conformance.
- **`unimplemented()` proxies** for dependencies a feature module declares but
  cannot construct.
- **A composition root** (`wireContainers()`) that `override`s each proxy with a
  live implementation.

A Simple app has none of these — no feature containers, no `unimplemented()`, no
`wireContainers()`.

## File map

| File | Role |
|---|---|
| `ForgeDemo/AppContainer+DI.swift` | **App-target composition root.** Registers the live implementations on `AppContainer` and `wireContainers()` injects them into the feature containers. |
| `Packages/ForgeDemoPackages/Sources/FeatureTasks/TaskContainer.swift` | **Per-module container** for the Tasks feature. Cross-module deps are `unimplemented()` proxies. |
| `Packages/ForgeDemoPackages/Sources/FeatureSettings/SettingsContainer.swift` | **Per-module container** for the Settings feature. |
| `Packages/ForgeDemoPackages/Sources/Core*` | Protocol/model/networking/infrastructure modules — no Forge dependency; safe for any module to import. |

## See also

- [`forge-modular`](../plugins/forge/skills/forge-modular/SKILL.md) skill — the full Modular pattern
- [`using-forge`](../plugins/forge/skills/using-forge/SKILL.md) skill — "Which path am I in?" decision rule
- [ModularArchitecture](https://tatejennings.github.io/Forge/documentation/forge/modulararchitecture) (DocC)
