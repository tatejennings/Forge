import Testing
@testable import Forge

@Suite("Scope behavior")
struct ScopeTests {

    @Test("Transient scope returns a new instance each resolution")
    func transientReturnsNewInstance() {
        let container = TestContainer()

        let first = container.transientService
        let second = container.transientService

        #expect(first.id != second.id)
    }

    @Test("Singleton scope returns the same instance across resolutions")
    func singletonReturnsSameInstance() {
        let container = TestContainer()

        let first = container.singletonService
        let second = container.singletonService

        #expect(first.id == second.id)
    }

    @Test("Cached scope returns the same instance until resetCached")
    func cachedReturnsSameInstanceUntilReset() {
        let container = TestContainer()

        let first = container.cachedService
        let second = container.cachedService
        #expect(first.id == second.id)

        container.resetCached()

        let third = container.cachedService
        #expect(first.id != third.id)
    }

    @Test("resetCached does NOT clear singleton values")
    func resetCachedPreservesSingletons() {
        let container = TestContainer()

        let beforeReset = container.singletonService
        container.resetCached()
        let afterReset = container.singletonService

        #expect(beforeReset.id == afterReset.id)
    }

    @Test("resetAll clears both cached and singleton values")
    func resetAllClearsBoth() {
        let container = TestContainer()

        let singleton = container.singletonService
        let cached = container.cachedService

        container.resetAll()

        let newSingleton = container.singletonService
        let newCached = container.cachedService

        #expect(singleton.id != newSingleton.id)
        #expect(cached.id != newCached.id)
    }
}
