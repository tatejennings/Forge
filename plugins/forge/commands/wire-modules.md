---
description: Generate composition-root wiring in the app target for cross-module unimplemented() proxies declared in per-module Forge containers.
---

You are running `/forge:wire-modules` to ensure the app target's composition root overrides every `unimplemented(...)` proxy declared in per-module Forge containers. This is the wiring that turns a `unimplemented` default into a real implementation at app launch.

Use the `forge-modular` skill as the authoritative source for the pattern.

## Steps

1. **Discover containers and their `unimplemented` proxies.**
   - Find all `Container` subclasses across the workspace.
   - For each, find computed properties whose `provide(...)` body calls `unimplemented("<name>")`. These are the cross-module proxies that need wiring.
   - Record each finding as `(ContainerName, propertyName, expectedSource)` where `expectedSource` is the property name on `AppContainer` (or another container) that supplies the real implementation.

2. **Find the app target's composition root.**
   - Look for a file with `@main` and `App` conformance (SwiftUI) OR `@UIApplicationMain`/`AppDelegate` (UIKit).
   - The composition root is either inside `init()` of the `App` struct, or in `applicationDidFinishLaunching`, or in a dedicated `wireContainers()` function nearby.
   - If no obvious composition root exists, create a new file `<AppTarget>/DI/Composition.swift` with a `wireContainers()` function, and invoke it from the app's init / launch path.

3. **Discover the source container.**
   - The source is usually `AppContainer.shared`. If the workspace has a different "root" container (a container that imports all feature modules and registers the real implementations), prefer that one.

4. **Generate the wiring lines.**
   - For each `(ContainerName, propertyName, expectedSource)`, generate:
     ```swift
     <ContainerName>.shared.override(\.<propertyName>) { source.<propertyName> }
     ```
   - `source` is the app-level container variable, e.g. `let app = AppContainer.shared`.
   - If the source container does NOT have a property matching `<propertyName>`:
     - Look for fuzzy matches (e.g. `analyticsService` vs `analytics`).
     - If found, generate with the matched name and emit a `// NOTE:` comment recording the name mismatch so the user can confirm.
     - If not found, emit a `// TODO(forge): register \(propertyName) on AppContainer` comment so the user can supply it.

5. **Insert the wiring idempotently.**
   - If a wiring line for the same `(Container, property)` already exists in the composition root, skip it.
   - Group wirings by container, alphabetical by property within each group, alphabetical by container name across groups.

6. **Report what you did.**
   - Wirings discovered.
   - Wirings added.
   - Wirings skipped (already present).
   - Any `TODO` comments inserted (missing source properties).
   - Any `NOTE` comments inserted (fuzzy name matches that need user confirmation).

## Idempotence

- This command is designed to be re-runnable. Running it twice should produce no changes the second time.

## Do not

- Modify the per-module containers themselves — only the composition root.
- Invent source properties on `AppContainer`. If a source is missing, leave a `TODO` for the user.
- Reorder unrelated code in the composition root. Insert wirings as a contiguous block.
