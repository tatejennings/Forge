import Testing
import CoreModels
@testable import FeatureTasks

@Suite("TaskListViewModel", .serialized)
struct TaskListViewModelTests {

    @Test("loadTasks populates task list")
    @MainActor
    func loadTasksPopulates() async {
        let previous = TaskContainer.shared
        defer { TaskContainer.shared = previous }

        let container = TaskContainer()
        TaskContainer.shared = container

        let mockService = MockTaskService(tasks: TaskItem.previews)
        let mockState = MockAppState()
        container.override(\.taskService) { mockService as any TaskServiceProtocol }
        container.override(\.appState) { mockState as any AppStateProtocol }

        let vm = TaskListViewModel()
        await vm.loadTasks()
        #expect(vm.tasks.count == TaskItem.previews.count)
        #expect(vm.isLoading == false)
        #expect(vm.errorMessage == nil)
    }

    @Test("refreshTasks updates task list")
    @MainActor
    func refreshTasksUpdates() async {
        let previous = TaskContainer.shared
        defer { TaskContainer.shared = previous }

        let container = TaskContainer()
        TaskContainer.shared = container

        let initial = [TaskItem(title: "Old Task")]
        let mockService = MockTaskService(tasks: initial)
        let mockState = MockAppState()
        container.override(\.taskService) { mockService as any TaskServiceProtocol }
        container.override(\.appState) { mockState as any AppStateProtocol }

        let vm = TaskListViewModel()
        await vm.loadTasks()
        #expect(vm.tasks.count == 1)

        mockService.stubbedTasks = [TaskItem(title: "New Task"), TaskItem(title: "Another Task")]
        await vm.refreshTasks()

        #expect(vm.tasks.count == 2)
        #expect(mockService.refreshCallCount == 1)
        #expect(mockState.isSyncing == false)
    }

    @Test("toggleTask updates badge count")
    @MainActor
    func toggleTaskUpdatesBadge() async {
        let previous = TaskContainer.shared
        defer { TaskContainer.shared = previous }

        let container = TaskContainer()
        TaskContainer.shared = container

        let tasks = [TaskItem(title: "Test Task")]
        let mockService = MockTaskService(tasks: tasks)
        let mockState = MockAppState(count: 1)
        container.override(\.taskService) { mockService as any TaskServiceProtocol }
        container.override(\.appState) { mockState as any AppStateProtocol }

        let vm = TaskListViewModel()
        await vm.loadTasks()
        await vm.toggleTask(id: tasks[0].id)
        #expect(mockState.incompletedTaskCount == 0)
    }

    @Test("refreshTasks surfaces network error")
    @MainActor
    func refreshTasksSurfacesError() async {
        let previous = TaskContainer.shared
        defer { TaskContainer.shared = previous }

        let container = TaskContainer()
        TaskContainer.shared = container

        let mockService = MockTaskService(shouldThrow: true)
        let mockState = MockAppState()
        container.override(\.taskService) { mockService as any TaskServiceProtocol }
        container.override(\.appState) { mockState as any AppStateProtocol }

        let vm = TaskListViewModel()
        await vm.refreshTasks()
        #expect(vm.errorMessage != nil)
    }
}
