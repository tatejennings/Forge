# Changelog

All notable changes to Forge are documented here. This project adheres to
[Semantic Versioning](https://semver.org). While the framework is in the `0.x`
series, breaking changes are released as minor version bumps.

## [0.4.0] - 2026-06-07

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

- **Dependency resolution uses double-checked locking.** Factories now run *outside*
  the lock, and the internal lock is non-recursive (`NSLock` instead of
  `NSRecursiveLock`). Trade-off: under a data race a singleton may be *built* more
  than once, with all but the first instance discarded (first-write-wins). Singleton
  identity remains stable — every caller observes the same stored instance — but a
  side-effectful initializer may run more than once.
- `unimplemented(_:)` captures `#fileID` instead of `#file`, keeping absolute source
  paths out of diagnostics and release binaries.
- Documentation reframes "compile-time safe" as "compile-time-safe at the call site,
  with loud, fail-fast runtime checks underneath."

### Added

- CI workflow running the full test suite across Swift 5.10 / 6.0 / 6.1 / 6.2. This
  is the safeguard for the KeyPath name-extraction format that the override system
  depends on.
- README "Known constraint" note documenting the KeyPath string-interpolation
  dependency and how the CI matrix mitigates it.

[0.4.0]: https://github.com/tatejennings/Forge/releases/tag/0.4.0
