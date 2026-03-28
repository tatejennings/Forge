import Forge
import CoreModels

public final class TaskContainer: Container, SharedContainer, @unchecked Sendable {
    nonisolated(unsafe) public static var shared = TaskContainer()

    // MARK: - Cross-module proxies (wired by app target at startup via override)

    /// Override this with a real implementation from the app target's CoreContainer.
    public var taskService: any TaskServiceProtocol {
        provide(.singleton, preview: { MockTaskService() }) {
            #if DEBUG
            print("[Forge] ⚠️ taskService resolved without override — using mock fallback")
            #endif
            return MockTaskService()
        }
    }

    /// Override this with a real implementation from the app target's CoreContainer.
    public var appState: any AppStateProtocol {
        provide(.singleton, preview: { MockAppState() }) {
            #if DEBUG
            print("[Forge] ⚠️ appState resolved without override — using mock fallback")
            #endif
            return MockAppState()
        }
    }

    // MARK: - Feature-owned dependencies

    public var taskListViewModel: TaskListViewModel {
        provide(.cached,
                preview: { TaskListViewModel() }
        ) {
            TaskListViewModel()
        }
    }

    public var addTaskViewModel: AddTaskViewModel {
        provide { AddTaskViewModel() }
    }

    public func taskDetailViewModel(for task: TaskItem) -> TaskDetailViewModel {
        TaskDetailViewModel(task: task)
    }
}
