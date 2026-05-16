---
description: Create a new module-scoped Forge container with SharedContainer and a local Inject typealias.
argument-hint: "<ContainerName>  # e.g. AuthContainer, SearchContainer"
---

You are running `/forge:new-container` to create a new Forge container. The container name is `$ARGUMENTS`.

Use the `forge-modular` skill for the authoritative pattern.

## Steps

1. **Validate the name.**
   - Must be a valid Swift type name (PascalCase, ends with `Container` by convention).
   - If invalid or missing, ask the user for a valid name.

2. **Pick the target/module.**
   - If there are multiple targets in `Package.swift`, ask which target the container belongs to (single multi-choice question).
   - If single target, use that target.

3. **Pick the file location.**
   - Look for an existing `DI/` or `Dependencies/` folder under the target's source root. Use it if present.
   - Otherwise create `<TargetDir>/DI/<ContainerName>.swift`.

4. **Generate the file.**
   ```swift
   import Forge

   typealias Inject<T> = ContainerInject<<ContainerName>, T>

   final class <ContainerName>: Container, SharedContainer {
       static var shared = <ContainerName>()

       // Register dependencies here as computed properties.
       // Example:
       // var someService: any SomeServiceProtocol {
       //     provide(.singleton) { SomeService() }
       // }
   }
   ```

5. **Report what you did.**
   - Path of the created file.
   - Reminder: the local `typealias Inject<T> = ContainerInject<<ContainerName>, T>` shadows the framework `Inject`, so `@Inject(\.x)` in this module resolves from `<ContainerName>.shared`.
   - Suggested next step: `/forge:add-dependency <name>` to register the first dependency in this container.

## Idempotence

- If a file with that name already exists, do NOT overwrite. Print the existing path and stop.

## Do not

- Create the container in the app target unless the user explicitly chose it. Feature modules own their own containers.
- Add cross-module dependencies in this command. That's what `/forge:add-dependency` (with `unimplemented`) is for.
- Add an example dependency to the generated file — leave the body empty with a comment example.
