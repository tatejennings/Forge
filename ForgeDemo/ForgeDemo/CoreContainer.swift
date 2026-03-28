import Forge
import CoreModels
import CoreNetworking
import CoreInfrastructure

nonisolated final class CoreContainer: Container, SharedContainer, @unchecked Sendable {
    nonisolated(unsafe) static var shared = CoreContainer()

    // MARK: - Networking
    
    var httpClient: any HTTPClientProtocol {
        provide(.singleton,
                preview: { MockHTTPClient() as any HTTPClientProtocol }
        ) {
            URLSessionHTTPClient() as any HTTPClientProtocol
        }
    }

    var remoteTaskService: any RemoteTaskServiceProtocol {
        provide(.singleton,
                preview: { MockRemoteTaskService() as any RemoteTaskServiceProtocol }
        ) {
            RemoteTaskService(httpClient: self.httpClient) as any RemoteTaskServiceProtocol
        }
    }

    // MARK: - Persistence

    var swiftDataStack: SwiftDataStack {
        provide(.singleton) {
            (try? SwiftDataStack()) ?? { fatalError("SwiftData failed to initialize") }()
        }
    }

    var taskRepository: any TaskRepositoryProtocol {
        provide(.singleton) { TaskRepository(stack: self.swiftDataStack) as any TaskRepositoryProtocol }
    }

    // MARK: - Services

    var taskService: any TaskServiceProtocol {
        provide(.singleton,
                preview: { MockTaskService() as any TaskServiceProtocol }
        ) {
            TaskService(
                repository: self.taskRepository,
                remoteService: self.remoteTaskService
            ) as any TaskServiceProtocol
        }
    }

    var appState: any AppStateProtocol {
        provide(.singleton,
                preview: { MockAppState(displayName: "Preview User") as any AppStateProtocol }
        ) {
            AppStateService() as any AppStateProtocol
        }
    }
}
