import Testing
@testable import Forge

@Suite("Preview behavior", .serialized)
struct PreviewTests {

    init() {
        // Reset preview override before each test
        PreviewContext._isPreviewOverride = nil
    }

    @Test("Preview factory is used when running in preview context")
    func previewFactoryUsedInPreview() {
        PreviewContext._isPreviewOverride = true
        let container = TestContainer()

        let resolved = container.previewableService
        #expect(resolved.id == "preview")
    }

    @Test("Preview factory is NOT used when not in preview context")
    func previewFactoryNotUsedOutsidePreview() {
        PreviewContext._isPreviewOverride = false
        let container = TestContainer()

        let resolved = container.previewableService
        #expect(resolved.id == "live")
    }

    @Test("Preview values are not cached regardless of declared scope")
    func previewValuesNotCached() {
        PreviewContext._isPreviewOverride = true
        let container = TestContainer()

        // previewableService is declared as .singleton, but preview values
        // should not be cached — each resolution should call the preview factory
        let first = container.previewableService
        let second = container.previewableService

        #expect(first.id == "preview", "First resolution should use preview factory")
        #expect(second.id == "preview", "Second resolution should use preview factory")

        // Verify they are different instances (not cached despite .singleton scope)
        let firstIdentity = ObjectIdentifier(first as AnyObject)
        let secondIdentity = ObjectIdentifier(second as AnyObject)
        #expect(firstIdentity != secondIdentity, "Preview values should not be cached — each call should produce a new instance")
    }

    @Test("Preview factory on transient scope also works")
    func previewFactoryTransient() {
        PreviewContext._isPreviewOverride = true
        let container = TestContainer()

        let resolved = container.transientPreviewable
        #expect(resolved.id == "preview-transient")
    }

    @Test("Overrides take precedence over preview factories")
    func overridesTakePrecedenceOverPreview() {
        PreviewContext._isPreviewOverride = true
        let container = TestContainer()

        container.override(\.previewableService) { SimpleService(id: "override-wins") as any ServiceProtocol }

        let resolved = container.previewableService
        #expect(resolved.id == "override-wins")
    }
}
