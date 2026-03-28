import Testing
import Foundation
import Dispatch
@testable import Forge

@Suite("Container behavior", .serialized)
struct ContainerTests {

    @Test("Thread safety: concurrent singleton resolution produces one instance")
    func concurrentSingletonResolution() {
        let container = TestContainer()
        let iterations = 1000
        let collector = IDCollector()

        DispatchQueue.concurrentPerform(iterations: iterations) { _ in
            let service = container.singletonService
            collector.append(service.id)
        }

        let uniqueIds = collector.uniqueIDs
        #expect(uniqueIds.count == 1, "Singleton should produce exactly one instance, got \(uniqueIds.count)")
    }

    @Test("Container swap pattern works for test isolation")
    func containerSwapPattern() {
        // Simulate setUp
        TestContainer.shared = TestContainer()

        let first = TestContainer.shared.singletonService.id

        // Simulate tearDown + new setUp
        TestContainer.shared = TestContainer()

        let second = TestContainer.shared.singletonService.id

        #expect(first != second, "Fresh container should produce a new singleton instance")
    }

    @Test("@ContainerInject resolves lazily, not at init time")
    func containerInjectLazyResolution() {
        let container = TestContainer()

        // Create the property wrapper but don't access wrappedValue yet
        var inject = ContainerInject(container, \.singletonService)

        // Override after creating the wrapper
        container.override("singletonService") { SimpleService(id: "lazy-override") as any ServiceProtocol }

        // Now access — should get the override because resolution is lazy
        let resolved = inject.wrappedValue
        #expect(resolved.id == "lazy-override")
    }

    @Test("@ContainerInject works with SharedContainer convenience init")
    func containerInjectSharedConvenience() {
        TestContainer.shared = TestContainer()
        TestContainer.shared.override("transientService") { SimpleService(id: "shared-test") as any ServiceProtocol }

        var inject = ContainerInject<TestContainer, any ServiceProtocol>(\.transientService)
        let resolved = inject.wrappedValue
        #expect(resolved.id == "shared-test")
    }

    @Test("Cross-module proxy: override on owning container propagates through proxy")
    func crossModuleProxy() {
        let coreContainer = TestContainer()
        let featureContainer = TestContainer()

        // Feature container proxies to core container via override
        featureContainer.override("singletonService") { coreContainer.singletonService }

        let first = featureContainer.singletonService
        let second = featureContainer.singletonService

        // Both resolutions should return the same instance (core's singleton)
        #expect(first.id == second.id, "Proxy should return core container's singleton")

        // Core container's singleton should match
        let coreResolved = coreContainer.singletonService
        #expect(first.id == coreResolved.id, "Proxy should return the same instance as core container")
    }
}
