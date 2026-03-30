import Testing
@testable import Forge

@Suite("KeyPath name extraction")
struct KeyPathNameTests {

    @Test("Extracts simple property name from KeyPath")
    func simplePropertyExtraction() {
        let name = propertyName(from: \TestContainer.transientService)
        #expect(name == "transientService")
    }

    @Test("Extracts singleton property name from KeyPath")
    func singletonPropertyExtraction() {
        let name = propertyName(from: \TestContainer.singletonService)
        #expect(name == "singletonService")
    }

    @Test("Extracts cached property name from KeyPath")
    func cachedPropertyExtraction() {
        let name = propertyName(from: \TestContainer.cachedService)
        #expect(name == "cachedService")
    }

    @Test("Extracts property name from AppContainer extension")
    func appContainerExtensionProperty() {
        let name = propertyName(from: \AppContainer.testService)
        #expect(name == "testService")
    }

    @Test("Extracts previewable property name")
    func previewablePropertyExtraction() {
        let name = propertyName(from: \TestContainer.previewableService)
        #expect(name == "previewableService")
    }

    @Test("All TestContainer properties extract correctly")
    func allPropertiesExtractCorrectly() {
        #expect(propertyName(from: \TestContainer.transientService) == "transientService")
        #expect(propertyName(from: \TestContainer.singletonService) == "singletonService")
        #expect(propertyName(from: \TestContainer.cachedService) == "cachedService")
        #expect(propertyName(from: \TestContainer.previewableService) == "previewableService")
        #expect(propertyName(from: \TestContainer.transientPreviewable) == "transientPreviewable")
    }

    @Test("Extracted name matches #function default used by provide()")
    func extractedNameMatchesFunctionDefault() {
        // The critical invariant: the name extracted from a KeyPath must match
        // what #function produces inside the computed property getter.
        // #function inside a computed property `var transientService` produces "transientService".
        // If this test fails, the entire KeyPath override system is broken.
        let container = TestContainer()

        // Override using KeyPath — this extracts the name via propertyName(from:)
        container.override(\.transientService) { SimpleService(id: "keypath-test") as any ServiceProtocol }

        // Resolve via the computed property — this looks up using #function
        let resolved = container.transientService
        #expect(resolved.id == "keypath-test",
                "KeyPath-extracted name must match #function key used by provide()")
    }
}
