@testable import Forge

final class TestContainer: Container, SharedContainer, @unchecked Sendable {
    nonisolated(unsafe) static var shared = TestContainer()

    var transientService: any ServiceProtocol {
        provide(.transient) { SimpleService() }
    }

    var singletonService: any ServiceProtocol {
        provide(.singleton) { SimpleService() }
    }

    var cachedService: any ServiceProtocol {
        provide(.cached) { SimpleService() }
    }

    var previewableService: any ServiceProtocol {
        provide(.singleton, preview: { SimpleService(id: "preview") }) { SimpleService(id: "live") }
    }

    var transientPreviewable: any ServiceProtocol {
        provide(.transient, preview: { SimpleService(id: "preview-transient") }) { SimpleService(id: "live-transient") }
    }
}
