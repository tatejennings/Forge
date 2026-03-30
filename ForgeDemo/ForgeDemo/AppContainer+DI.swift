import Forge
import CoreModels
import CoreNetworking
import CoreInfrastructure
import FeatureTasks
import FeatureSettings

// MARK: - App Dependencies

extension AppContainer {

    // MARK: Networking

    var httpClient: any HTTPClientProtocol {
        provide(.singleton) {
            URLSessionHTTPClient()
        } preview: {
            MockHTTPClient()
        }
    }

    var remoteTaskService: any RemoteTaskServiceProtocol {
        provide(.singleton) {
            RemoteTaskService(httpClient: self.httpClient)
        } preview: {
            MockRemoteTaskService()
        }
    }

    // MARK: Persistence

    var swiftDataStack: SwiftDataStack {
        provide(.singleton) {
            (try? SwiftDataStack()) ?? { fatalError("SwiftData failed to initialize") }()
        }
    }

    var taskRepository: any TaskRepositoryProtocol {
        provide(.singleton) { TaskRepository(stack: self.swiftDataStack) }
    }

    // MARK: Services

    var taskService: any TaskServiceProtocol {
        provide(.singleton) {
            TaskService(
                repository: self.taskRepository,
                remoteService: self.remoteTaskService
            )
        } preview: {
            MockTaskService()
        }
    }

    var appState: any AppStateProtocol {
        provide(.singleton) {
            AppStateService()
        } preview: {
            MockAppState(displayName: "Preview User")
        }
    }

    // MARK: Composition Root

    static func wireContainers() {
        let app = AppContainer.shared

        // Resolve once eagerly, then hand the instances to the @Sendable closures
        let taskService = app.taskService
        let appState = app.appState

        // Wire TaskContainer with live dependencies from AppContainer
        TaskContainer.shared.override("taskService") { taskService }
        TaskContainer.shared.override("appState") { appState }

        // Wire SettingsContainer with live dependencies from AppContainer
        SettingsContainer.shared.override("taskService") { taskService }
        SettingsContainer.shared.override("appState") { appState }
    }
}
