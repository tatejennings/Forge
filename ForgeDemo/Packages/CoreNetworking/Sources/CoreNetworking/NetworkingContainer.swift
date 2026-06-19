import Forge
import CoreModels

// Per-module Forge container (Modular path). CoreNetworking owns its concrete
// networking services here. There is no local `Inject` typealias because this
// module *provides* dependencies but doesn't inject any from itself — factories
// reference `self.x` directly. Only the surface other modules consume is `public`.
public final class NetworkingContainer: Container, SharedContainer, @unchecked Sendable {
    nonisolated(unsafe) public static var shared = NetworkingContainer()

    // Internal building block — only this container needs it.
    var httpClient: any HTTPClientProtocol {
        provide(.singleton) {
            URLSessionHTTPClient()
        } preview: {
            MockHTTPClient()
        }
    }

    /// Consumed by CoreInfrastructure and wired into feature modules by the app's
    /// composition root.
    public var remoteTaskService: any RemoteTaskServiceProtocol {
        provide(.singleton) {
            RemoteTaskService(httpClient: self.httpClient)
        } preview: {
            MockRemoteTaskService()
        }
    }
}
