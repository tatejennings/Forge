---
description: Add Forge to the current project and scaffold the first AppContainer extension or custom Container.
argument-hint: "[simple|modular]  # optional setup style; auto-detected if omitted"
---

You are running `/forge:init` to add the Forge dependency injection framework to the user's project. The argument (if provided) is `$ARGUMENTS` — either `simple` (extend `AppContainer`), `modular` (custom `Container` per module), or empty (auto-detect).

Use the `using-forge` and `forge-modular` skills as the authoritative source for conventions.

## Steps

1. **Inspect the project structure.**
   - Look for `Package.swift`, `.xcodeproj`, or `.xcworkspace` at the working directory and one level down.
   - Count the number of `.target(...)` / library targets in any `Package.swift` files.
   - Single target → suggest `simple` setup unless the user passed `modular`.
   - Multiple targets / workspace → suggest `modular` unless the user passed `simple`.

2. **If the setup style is still ambiguous, ask the user** (one question, multi-choice):
   - Simple — extend the built-in `AppContainer`. Best for single-target apps.
   - Modular — one `Container` per module, composition root in the app target. Best for SPM workspaces or large apps.

3. **Add the Forge SPM dependency.**
   - If a `Package.swift` is present, add to `dependencies:` and to the target's `dependencies:`:
     ```swift
     .package(url: "https://github.com/tatejennings/Forge.git", from: "0.1.0")
     ```
     Target dependency: `.product(name: "Forge", package: "Forge")`.
   - If an Xcode project is present (no `Package.swift`), explain that the user needs to add the package via Xcode (File → Add Package Dependencies…) and provide the URL. Do not attempt to edit `.xcodeproj` files directly.

4. **Scaffold the container file.**
   - **Simple style:** create `<MainTargetDir>/DI/AppContainer+DI.swift` with:
     ```swift
     import Forge

     extension AppContainer {
         // Add your dependencies here as computed properties.
         // Example:
         // var networkClient: any NetworkClientProtocol {
         //     provide(.singleton) { URLSessionNetworkClient() }
         // }
     }
     ```
   - **Modular style:** create `<TargetDir>/DI/<TargetName>Container.swift` with:
     ```swift
     import Forge

     typealias Inject<T> = ContainerInject<<TargetName>Container, T>

     final class <TargetName>Container: Container, SharedContainer {
         static let shared = <TargetName>Container()

         // Add your dependencies here.
     }
     ```
   - Match the target's existing folder conventions if there's an obvious DI / Dependencies folder. Otherwise create a `DI/` folder.

5. **Report what you did.**
   - Files created.
   - Whether SPM was updated automatically or the user needs to add the package in Xcode.
   - Next steps: `/forge:add-dependency <name>` to register the first dependency.

## Idempotence

- If `Forge` is already in `Package.swift`, skip the add and say so.
- If the scaffolded file already exists with non-comment content, do NOT overwrite. Print the existing path and ask the user whether to merge or skip.

## Do not

- Run `swift build` or `swift test` — leave that to the user.
- Edit `.xcodeproj` files directly.
- Add example dependencies unrelated to what the user has actually expressed interest in.
