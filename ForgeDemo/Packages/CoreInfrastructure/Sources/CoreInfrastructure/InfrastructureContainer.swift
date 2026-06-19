import Forge
import CoreModels
import CoreNetworking
import CoreLogger

// Per-module Forge container (Modular path). CoreInfrastructure owns persistence
// and the app's domain services. It depends on CoreNetworking (an allowed downward
// Core -> Core dependency) and reads `remoteTaskService` from NetworkingContainer.
// The app's composition root wires `taskService` / `appState` into the feature
// modules. No local `Inject` typealias — this is a provider module.
public final class InfrastructureContainer: Container, SharedContainer, @unchecked Sendable {
    nonisolated(unsafe) public static var shared = InfrastructureContainer()

    // Internal building blocks.
    var swiftDataStack: SwiftDataStack {
        provide(.singleton) {
            (try? SwiftDataStack()) ?? { fatalError("SwiftData failed to initialize") }()
        }
    }

    var taskRepository: any TaskRepositoryProtocol {
        provide(.singleton) { TaskRepository(stack: self.swiftDataStack) }
    }

    /// Wired into the feature modules by the app's composition root.
    public var taskService: any TaskServiceProtocol {
        provide(.singleton) {
            TaskService(
                repository: self.taskRepository,
                remoteService: NetworkingContainer.shared.remoteTaskService,
                logger: LoggerContainer.shared.logger
            )
        } preview: {
            MockTaskService()
        }
    }

    /// Wired into the feature modules by the app's composition root.
    public var appState: any AppStateProtocol {
        provide(.singleton) {
            AppStateService(logger: LoggerContainer.shared.logger)
        } preview: {
            MockAppState(displayName: "Preview User")
        }
    }
}
