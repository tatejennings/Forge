# Forge — Claude Code Plugin

Skills, slash commands, and subagents that help you adopt and use the [Forge](https://github.com/tatejennings/Forge) Swift dependency injection framework inside Claude Code.

## Install

```text
/plugin marketplace add tatejennings/Forge
/plugin install forge@tatejennings-forge
```

## What you get

### Skills (auto-activate when relevant)

| Skill | Activates when |
|---|---|
| `using-forge` | You're editing a Swift file that imports `Forge` or uses `@Inject` / `Container` / `provide(...)` |
| `forge-testing` | You're editing a test file that touches Forge |
| `forge-modular` | You're working in a multi-module SPM workspace using Forge |
| `forge-migration` | You're migrating an app to Forge from Factory, manual init injection, or service-locator patterns |

### Slash commands

| Command | What it does |
|---|---|
| `/forge:init` | Adds the Forge SPM dependency and scaffolds your first `AppContainer` extension |
| `/forge:new-container` | Creates a new module container with `SharedContainer` and local `Inject` typealias |
| `/forge:add-dependency` | Walks through adding a dependency: protocol, scope, optional preview factory |
| `/forge:wire-modules` | Generates composition-root wiring for cross-module dependencies |

### Subagents

| Agent | Use case |
|---|---|
| `forge-reviewer` | Audits a file, directory, or PR for Forge anti-patterns (concrete return types, wrong scopes, missing protocols, unwired cross-module deps) |
| `forge-migrator` | Migrates an existing app to Forge — handles Factory (hmlongco/Factory), manual init injection, and service-locator / `.shared` singleton patterns |

## Versioning

This plugin lives in the Forge repository and is versioned alongside the framework. When Forge's public API or recommended patterns change, the plugin is updated in the same commit. Always install the plugin version that matches the Forge version you depend on.

## Issues / feedback

File issues at [github.com/tatejennings/Forge/issues](https://github.com/tatejennings/Forge/issues) with the `claude-plugin` label.
