@testable import Forge

extension AppContainer {

    var testService: any ServiceProtocol {
        provide(.transient) { SimpleService(id: "app-container-live") }
    }

    var testSingletonService: any ServiceProtocol {
        provide(.singleton) { SimpleService(id: "app-container-singleton") }
    }
}
