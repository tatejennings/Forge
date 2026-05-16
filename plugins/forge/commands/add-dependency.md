---
description: Register a new dependency in a Forge container — adds the protocol-typed computed property with the right scope and an optional preview factory.
argument-hint: "<dependencyName>  # e.g. authService, networkClient"
---

You are running `/forge:add-dependency` to register a new dependency in a Forge container. The dependency name is `$ARGUMENTS` (camelCase, the same name that will appear in `\.dependencyName` injection paths).

Use the `using-forge` skill as the authoritative source for conventions.

## Steps

1. **Find candidate containers.**
   - Search the repo for files containing `: Container, SharedContainer` or `: Container {`.
   - If none found, suggest running `/forge:init` first and stop.
   - If exactly one, use it.
   - If multiple, ask the user which container should own this dependency (single multi-choice question listing the containers by file path).

2. **Determine the protocol type.**
   - Default protocol name: PascalCase the dependency name and append `Protocol` (e.g. `authService` → `AuthServiceProtocol`).
   - If a protocol with that exact name already exists in the target/module, reuse it.
   - Otherwise ask the user (one question):
     - Use the default `<Name>Protocol`
     - Provide a custom protocol name
     - Skip protocol (concrete type) — and WARN that this prevents test/preview substitution. Recommend against unless the dependency is intentionally non-substitutable.

3. **Determine the implementation type.**
   - Default implementation name: PascalCase the dependency name (e.g. `authService` → `AuthService`).
   - If unclear, ask the user for the implementation type name.

4. **Determine the scope.**
   - Ask the user (one multi-choice question) with these options:
     - `.transient` (default) — new instance per resolution. Best for stateless services and per-screen ViewModels.
     - `.singleton` — one instance for the container's lifetime. Best for network clients, databases, analytics.
     - `.cached` — one instance until `resetCached()`. Best for ViewModels that survive navigation but can be refreshed.
   - Default: `.transient` unless the dependency name strongly implies a long-lived service (`Client`, `Database`, `Manager`, `Analytics`) — then default to `.singleton`.

5. **Determine if a preview factory is needed.**
   - Ask the user (one yes/no/auto question):
     - Yes — add a `preview:` factory using `Mock<ImplName>` as a placeholder.
     - No — skip.
     - Auto-decide based on the dependency: if the implementation name suggests network / disk / external side effects (`URL`, `Network`, `HTTP`, `Database`, `Analytics`, `Auth`), default to Yes; otherwise No.

6. **Insert the registration.**
   - Add the property to the chosen container, in alphabetical order with the other registrations if a consistent order exists; otherwise at the end of the container body.
   - Template:
     ```swift
     var <name>: any <Protocol> {
         provide(<scope>) { <Impl>(<deps>) }<preview-clause>
     }
     ```
     - `<preview-clause>` is ` preview: { Mock<Impl>() }` when a preview was requested, else empty.
     - For `<deps>`: inspect existing container properties for plausible matches by name (e.g. `network`, `networkClient`, `analytics`) and pass them as `self.<name>`. If unsure, leave the init call empty and emit a one-line comment: `// TODO: pass real dependencies (e.g., self.networkClient)`.

7. **Report what you did.**
   - Path of the modified file.
   - Lines added.
   - The injection site: `@Inject(\.<name>)` in classes, or `<Container>.shared.<name>` for direct resolution.
   - If a protocol or mock type was assumed but not created, list those as user follow-ups.

## Idempotence

- If a property with the same name already exists in the chosen container, do NOT overwrite. Print the existing property and ask whether to skip or replace.

## Do not

- Create the protocol or implementation type — leave that to the user. Only register the dependency.
- Add cross-module proxies in this command (those use `unimplemented`; that's a separate, smaller flow you can mention in the report if the user's container looks like it's in a feature module that imports a protocol module without the implementation).
