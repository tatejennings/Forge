import Testing
import CoreModels
@testable import FeatureTasks

@Suite("AddTaskViewModel", .serialized)
struct AddTaskViewModelTests {

    @Test("Submit with valid title returns task")
    @MainActor
    func submitValidTitle() async {
        let previous = TaskContainer.shared
        defer { TaskContainer.shared = previous }
        let container = TaskContainer()
        TaskContainer.shared = container

        let mockService = MockTaskService(tasks: [])
        container.override(\.taskService) { mockService as any TaskServiceProtocol }

        let vm = AddTaskViewModel()
        vm.title = "Write unit tests"
        vm.notes = "Cover all ViewModels"
        let result = await vm.submit()
        #expect(result != nil)
        #expect(result?.title == "Write unit tests")
    }

    @Test("Submit with empty title returns nil")
    @MainActor
    func submitEmptyTitle() async {
        let previous = TaskContainer.shared
        defer { TaskContainer.shared = previous }
        let container = TaskContainer()
        TaskContainer.shared = container

        let mockService = MockTaskService(tasks: [])
        container.override(\.taskService) { mockService as any TaskServiceProtocol }

        let vm = AddTaskViewModel()
        vm.title = "   "
        let result = await vm.submit()
        #expect(result == nil)
    }

    @Test("canSubmit is false when title is empty")
    func canSubmitEmpty() {
        // canSubmit doesn't access injected dependencies, so no container setup needed
        let vm = AddTaskViewModel()
        #expect(vm.canSubmit == false)
        vm.title = "Some task"
        #expect(vm.canSubmit == true)
    }
}
