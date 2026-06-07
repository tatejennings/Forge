# Changelog

All notable changes to Forge are documented here. This project adheres to
[Semantic Versioning](https://semver.org). While the framework is in the `0.x`
series, breaking changes are released as minor version bumps.

## [0.5.0] - 2026-06-07

### Breaking

- **`SharedContainer.shared` is now `{ get }` only** (was `{ get set }`), and
  `AppContainer.shared` is a `static let`. The shared instance is stable for the
  lifetime of the process and can no longer be reassigned. For test isolation, use
  `resetAll()` / `withOverrides(_:run:)` on the shared container instead of swapping
  it. (If you specifically want swap-based tests, you can still declare your own
  container's `shared` as a `static var` — the protocol requirement is only `{ get }`.)
- **Wrong-type overrides now fail loudly.** A type-mismatched override triggers an
  `assertionFailure` (crashing in debug/test builds) instead of silently falling
  through to the real factory. Release builds still fall through. A test that relied
  on the old silent fall-through will now crash in debug — fix the override's return
  type.

### Changed

- **`Forge.defaultContainer` is now fully thread-safe.** Reads and writes are guarded
  by an internal lock, so it is safe to access from any thread. The previous "set it on
  the main thread before any background work" restriction is lifted (configuring it once
  at startup is still recommended).
- `unimplemented(_:)` captures `#fileID` instead of `#file`, keeping absolute source
  paths out of diagnostics and release binaries.
- Documentation reframes "compile-time safe" as "compile-time-safe at the call site,
  with loud, fail-fast runtime checks underneath."

### Added

- CI workflow running the full test suite across Swift 5.10 / 6.0 / 6.1 / 6.2 on Linux
  and macOS. This is the safeguard for the KeyPath name-extraction format that the
  override system depends on.
- **Strict-concurrency CI job** compiling the library with
  `-strict-concurrency=complete -swift-version 6`, plus `StrictConcurrency` enabled on
  the target itself — Forge builds with no concurrency warnings under the Swift 6
  language mode. (`Container` stays `@unchecked Sendable` because it is `open`; the
  conformance is sound — all mutable state lives behind the lock.)
- Scope-contract tests asserting factory invocation counts: `.transient` builds on
  every resolution, `.singleton` / `.cached` build exactly once (including under
  concurrent first resolution via a 1000-way race), and `.cached` rebuilds after
  `resetCached()`.
- README "Known constraint" note documenting the KeyPath string-interpolation
  dependency, and a "Thread safety" section.

### Notes

- `.singleton` and `.cached` resolution is **exactly-once**: the factory runs inside a
  recursive lock, so a side-effectful initializer never runs more than once even when
  multiple threads race to resolve it for the first time.

## [0.4.0]

Tagged release covering documentation and Claude Code plugin updates. No CHANGELOG was
published for this version.

[0.5.0]: https://github.com/tatejennings/Forge/releases/tag/0.5.0
[0.4.0]: https://github.com/tatejennings/Forge/releases/tag/0.4.0
