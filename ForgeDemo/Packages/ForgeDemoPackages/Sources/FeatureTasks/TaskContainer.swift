@_exported import Forge
import CoreModels

typealias Inject<T> = ContainerInject<TaskContainer, T>

public final class TaskContainer: Container, SharedContainer, @unchecked Sendable {
    nonisolated(unsafe) public static var shared = TaskContainer()

    // MARK: - Cross-module proxies (wired by app target at startup via override)

    /// Override this with a real implementation from the app target's AppContainer.
    public var taskService: any TaskServiceProtocol {
        provide(.singleton) {
            unimplemented("taskService")
        } preview: {
            MockTaskService()
        }
    }

    /// Override this with a real implementation from the app target's AppContainer.
    public var appState: any AppStateProtocol {
        provide(.singleton) {
            unimplemented("appState")
        } preview: {
            MockAppState()
        }
    }

    // MARK: - Feature-owned dependencies

    public var taskListViewModel: TaskListViewModel {
        provide(.cached) { TaskListViewModel() }
    }

    public var addTaskViewModel: AddTaskViewModel {
        provide { AddTaskViewModel() }
    }

}
