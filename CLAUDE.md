# CLAUDE.md

Project-level instructions for Claude Code working in the Forge repository.

## What this repo is

Forge is a lightweight, compile-time-safe dependency injection framework for Swift. The source lives under `Sources/Forge/`. Tests live under `Tests/`. A demo app is in `ForgeDemo/`. Public documentation is generated from DocC sources under `Sources/Forge/Documentation.docc/`.

Alongside the framework, this repo ships a Claude Code plugin under `plugins/forge/` (see `plugins/forge/README.md`) and a top-level `AGENTS.md` for non-Claude agent tools. These exist to help users adopt and use Forge correctly. They MUST stay in sync with the framework.

## Plugin/agent sync (mandatory)

When editing any file under `Sources/Forge/` that changes public API, public behavior, conventions, or documented patterns, you MUST also update:

1. The relevant skill(s) under `plugins/forge/skills/` — usually `using-forge`, plus `forge-testing` / `forge-modular` / `forge-migration` if affected.
2. The matching slash command(s) under `plugins/forge/commands/` if their generated output references the changed API.
3. The relevant subagent prompt(s) under `plugins/forge/agents/` if their decision rules reference the changed API.
4. `AGENTS.md` at the repo root if the change affects anything in its condensed digest.

If the change is purely internal (private symbols, refactors, tests, comments, DocC prose that doesn't change API), no plugin update is required — but state this explicitly in your response so it's clear the check was performed.

### What counts as a "public API or convention" change

- Adding, removing, renaming, or changing the signature of any `public` symbol in `Sources/Forge/`.
- Changing the behavior of an existing public symbol (scope semantics, override semantics, preview detection, etc.).
- Changing a documented pattern in the README, DocC articles, or skill content (e.g. how to structure cross-module wiring, how to write a test container, what `unimplemented` is for).
- Introducing or removing a recommended practice ("always use protocol return types", "one container per module", etc.).

### How to update the plugin

- `plugins/forge/skills/using-forge/SKILL.md` — update if the change touches anything a user invokes day-to-day (registration, injection, scopes, previews, basic `unimplemented`).
- `plugins/forge/skills/forge-testing/SKILL.md` — update if the change affects `withOverrides`, `override`, `removeOverride`, `resetAll`, `resetCached`, or `unimplemented` in a test context.
- `plugins/forge/skills/forge-modular/SKILL.md` — update if the change affects multi-module patterns, `SharedContainer`, the local `Inject` typealias pattern, or composition-root wiring.
- `plugins/forge/skills/forge-migration/SKILL.md` — update if the change affects how users would migrate from another DI pattern into Forge.
- `plugins/forge/commands/*.md` — update if the generated code/templates a command produces references the changed API.
- `plugins/forge/agents/forge-reviewer.md` — update the anti-pattern list if a new convention is introduced or an old one deprecated.
- `plugins/forge/agents/forge-migrator.md` — update if the migration target patterns change or a new source pattern needs handling.

## Project conventions

- Swift version: 5.10+ (also tested against 6.0/6.1/6.2).
- The framework has zero external dependencies. Do not introduce one without explicit user approval.
- Tests use Swift Testing (`@Test`), not XCTest, except where legacy test files exist.
- Public API additions require accompanying DocC documentation under `Sources/Forge/Documentation.docc/`.

## Style

- Match existing file conventions: copyright header (if present in neighboring files), import order, brace style.
- Prefer Swift's standard formatting (4-space indent, K&R braces, trailing commas in multi-line arrays).
- Public symbols get DocC `///` comments; internal symbols do not need them.
