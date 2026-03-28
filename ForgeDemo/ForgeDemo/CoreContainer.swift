import Forge
import CoreModels
import CoreNetworking
import CoreInfrastructure

nonisolated final class CoreContainer: Container, SharedContainer, @unchecked Sendable {
    nonisolated(unsafe) static var shared = CoreContainer()

    // MARK: - Networking
    
    var httpClient: any HTTPClientProtocol {
        provide(.singleton,
                preview: { MockHTTPClient() }
        ) {
            URLSessionHTTPClient()
        }
    }

    var remoteTaskService: any RemoteTaskServiceProtocol {
        provide(.singleton,
                preview: { MockRemoteTaskService() }
        ) {
            RemoteTaskService(httpClient: self.httpClient)
        }
    }

    // MARK: - Persistence

    var swiftDataStack: SwiftDataStack {
        provide(.singleton) {
            (try? SwiftDataStack()) ?? { fatalError("SwiftData failed to initialize") }()
        }
    }

    var taskRepository: any TaskRepositoryProtocol {
        provide(.singleton) { TaskRepository(stack: self.swiftDataStack) }
    }

    // MARK: - Services

    var taskService: any TaskServiceProtocol {
        provide(.singleton,
                preview: { MockTaskService() }
        ) {
            TaskService(
                repository: self.taskRepository,
                remoteService: self.remoteTaskService
            )
        }
    }

    var appState: any AppStateProtocol {
        provide(.singleton,
                preview: { MockAppState(displayName: "Preview User") }
        ) {
            AppStateService()
        }
    }
}
